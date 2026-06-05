import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local_db/app_database.dart' as db;
import '../../data/parser/parser_client.dart';
import '../../domain/extracted_item.dart';
import '../../domain/item_type.dart';
import '../../domain/parse_result.dart';
import '../../domain/record_status.dart';

class SubmitInputResult {
  const SubmitInputResult({
    required this.rawInputId,
    required this.aiParseResultId,
    required this.parseResult,
    required this.items,
  });

  final String rawInputId;
  final String aiParseResultId;
  final ParseResult parseResult;
  final List<ExtractedItem> items;
}

class ExtractedItemsController {
  ExtractedItemsController({
    required this.database,
    required this.parserClient,
    String Function()? rawInputIdFactory,
    String Function()? parseResultIdFactory,
    String Function()? officialRecordIdFactory,
    DateTime Function()? nowProvider,
  }) : rawInputIdFactory = rawInputIdFactory ?? const Uuid().v4,
       parseResultIdFactory = parseResultIdFactory ?? const Uuid().v4,
       officialRecordIdFactory = officialRecordIdFactory ?? const Uuid().v4,
       nowProvider = nowProvider ?? DateTime.now;

  final db.AppDatabase database;
  final ParserClient parserClient;
  final String Function() rawInputIdFactory;
  final String Function() parseResultIdFactory;
  final String Function() officialRecordIdFactory;
  final DateTime Function() nowProvider;

  static const autoSaveHint = '已自动整理，可修改或撤销';

  Future<SubmitInputResult> submitInput(String text) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      throw const ParserFailure(
        code: 'empty_input',
        userMessage: '请先输入你想整理的内容。',
      );
    }

    final now = nowProvider();
    final rawInputId = rawInputIdFactory();
    final aiParseResultId = parseResultIdFactory();

    await database
        .into(database.rawInputs)
        .insert(
          db.RawInputsCompanion.insert(
            id: rawInputId,
            inputText: trimmedText,
            createdAt: now,
          ),
        );

    try {
      final parseResult = await parserClient.parseInput(trimmedText);
      final persistedItems = _toPersistedItems(
        items: parseResult.items,
        rawInputId: rawInputId,
        now: now,
      );

      await database.transaction(() async {
        await database
            .into(database.aiParseResults)
            .insert(
              db.AiParseResultsCompanion.insert(
                id: aiParseResultId,
                rawInputId: rawInputId,
                rawJson: jsonEncode(_parseResultToJson(parseResult)),
                validationState: 'valid',
                createdAt: now,
              ),
            );

        for (final item in persistedItems) {
          await database
              .into(database.extractedItems)
              .insert(
                _toCompanion(
                  item: item,
                  aiParseResultId: aiParseResultId,
                  now: now,
                ),
              );

          if (_shouldAutoSave(item: item, now: now)) {
            await _createOfficialRecordFromExtractedItem(
              item: item,
              officialRecordId: officialRecordIdFactory(),
              now: now,
            );
          }
        }
      });

      return SubmitInputResult(
        rawInputId: rawInputId,
        aiParseResultId: aiParseResultId,
        parseResult: parseResult,
        items: persistedItems,
      );
    } on ParserFailure catch (error) {
      await _recordParseFailure(
        id: aiParseResultId,
        rawInputId: rawInputId,
        error: error,
        now: now,
      );
      rethrow;
    } catch (_) {
      await _recordParseFailure(
        id: aiParseResultId,
        rawInputId: rawInputId,
        error: const ParserFailure(
          code: 'submit_failed',
          userMessage: '整理失败，请稍后再试。',
        ),
        now: now,
      );
      throw const ParserFailure(
        code: 'submit_failed',
        userMessage: '整理失败，请稍后再试。',
      );
    }
  }

  Future<void> confirmExtractedItem({
    required String extractedItemId,
    String? editedTitle,
    String? editedContent,
  }) async {
    final item = await _getExtractedItem(extractedItemId);
    final now = nowProvider();
    final officialRecordId = officialRecordIdFactory();
    final status =
        _hasEdits(editedTitle: editedTitle, editedContent: editedContent)
        ? RecordStatus.edited
        : RecordStatus.confirmed;
    final title = editedTitle ?? item.title;
    final content = editedContent ?? item.content;
    final fallbackText = title ?? content ?? item.sourceText;
    final taskDue = _inferTaskDue(
      text: '${title ?? ''} ${content ?? ''} ${item.sourceText}',
      now: now,
    );

    await database.transaction(() async {
      await (database.update(
        database.extractedItems,
      )..where((row) => row.id.equals(extractedItemId))).write(
        db.ExtractedItemsCompanion(
          title: Value(title),
          content: Value(content),
          status: Value(status.value),
          updatedAt: Value(now),
        ),
      );

      switch (ItemTypeApiValue.fromApiValue(item.type)) {
        case ItemType.taskCreate:
          await database
              .into(database.tasks)
              .insert(
                db.TasksCompanion.insert(
                  id: officialRecordId,
                  sourceRawInputId: item.rawInputId,
                  sourceExtractedItemId: item.id,
                  title: fallbackText,
                  description: Value(content),
                  dueTimeText: Value(taskDue.dueTimeText),
                  dueTime: Value(taskDue.dueTime),
                  status: RecordStatus.confirmed.value,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        case ItemType.shortTermState:
          await database
              .into(database.shortTermStates)
              .insert(
                db.ShortTermStatesCompanion.insert(
                  id: officialRecordId,
                  sourceRawInputId: item.rawInputId,
                  sourceExtractedItemId: item.id,
                  content: content ?? title ?? item.sourceText,
                  tagsJson: Value(item.tagsJson),
                  validUntil:
                      item.expiresAt ?? now.add(const Duration(days: 1)),
                  status: RecordStatus.confirmed.value,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        case ItemType.lifeEvent:
          await database
              .into(database.lifeEvents)
              .insert(
                db.LifeEventsCompanion.insert(
                  id: officialRecordId,
                  sourceRawInputId: item.rawInputId,
                  sourceExtractedItemId: item.id,
                  content: content ?? title ?? item.sourceText,
                  tagsJson: Value(item.tagsJson),
                  status: RecordStatus.confirmed.value,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        case ItemType.profileCandidate:
          await database
              .into(database.profileItems)
              .insert(
                db.ProfileItemsCompanion.insert(
                  id: officialRecordId,
                  sourceRawInputId: item.rawInputId,
                  sourceExtractedItemId: item.id,
                  content: content ?? title ?? item.sourceText,
                  tagsJson: Value(item.tagsJson),
                  confidence: item.confidence,
                  status: RecordStatus.confirmed.value,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        case ItemType.taskUpdate:
        case ItemType.generalAnswer:
          break;
      }
    });
  }

  Future<void> rejectExtractedItem({required String extractedItemId}) {
    return database.updateExtractedItemStatus(
      id: extractedItemId,
      status: RecordStatus.rejected,
      updatedAt: nowProvider(),
    );
  }

  Future<void> undoAutoSavedExtractedItem({
    required String extractedItemId,
  }) async {
    final item = await _getExtractedItem(extractedItemId);
    final type = ItemTypeApiValue.fromApiValue(item.type);

    await database.transaction(() async {
      switch (type) {
        case ItemType.taskCreate:
          await database.markTaskDeletedBySourceExtractedItemId(
            extractedItemId: extractedItemId,
            updatedAt: nowProvider(),
          );
        case ItemType.shortTermState:
          await database.markShortTermStateDeletedBySourceExtractedItemId(
            extractedItemId: extractedItemId,
            updatedAt: nowProvider(),
          );
        case ItemType.lifeEvent:
          await database.markLifeEventDeletedBySourceExtractedItemId(
            extractedItemId: extractedItemId,
            updatedAt: nowProvider(),
          );
        case ItemType.taskUpdate:
        case ItemType.generalAnswer:
        case ItemType.profileCandidate:
          break;
      }

      await database.updateExtractedItemStatus(
        id: extractedItemId,
        status: RecordStatus.deleted,
        updatedAt: nowProvider(),
      );
    });
  }

  Future<void> editAutoSavedExtractedItem({
    required String extractedItemId,
    String? editedTitle,
    String? editedContent,
  }) async {
    final item = await _getExtractedItem(extractedItemId);
    final now = nowProvider();
    final type = ItemTypeApiValue.fromApiValue(item.type);
    final title = editedTitle ?? item.title;
    final content = editedContent ?? item.content;
    final fallbackText = title ?? content ?? item.sourceText;
    final taskDue = _inferTaskDue(
      text: '${title ?? ''} ${content ?? ''} ${item.sourceText}',
      now: now,
    );

    await database.transaction(() async {
      await (database.update(
        database.extractedItems,
      )..where((row) => row.id.equals(extractedItemId))).write(
        db.ExtractedItemsCompanion(
          title: Value(title),
          content: Value(content),
          status: Value(RecordStatus.edited.value),
          updatedAt: Value(now),
        ),
      );

      switch (type) {
        case ItemType.taskCreate:
          await database.updateTaskBySourceExtractedItemId(
            extractedItemId: extractedItemId,
            title: fallbackText,
            description: content,
            dueTimeText: taskDue.dueTimeText,
            dueTime: taskDue.dueTime,
            updatedAt: now,
          );
        case ItemType.shortTermState:
          await database.updateShortTermStateBySourceExtractedItemId(
            extractedItemId: extractedItemId,
            content: content ?? title ?? item.sourceText,
            validUntil: item.expiresAt ?? now.add(const Duration(days: 1)),
            updatedAt: now,
          );
        case ItemType.lifeEvent:
          await database.updateLifeEventBySourceExtractedItemId(
            extractedItemId: extractedItemId,
            content: content ?? title ?? item.sourceText,
            updatedAt: now,
          );
        case ItemType.taskUpdate:
        case ItemType.generalAnswer:
        case ItemType.profileCandidate:
          break;
      }
    });
  }

  Future<void> _recordParseFailure({
    required String id,
    required String rawInputId,
    required ParserFailure error,
    required DateTime now,
  }) {
    return database
        .into(database.aiParseResults)
        .insert(
          db.AiParseResultsCompanion.insert(
            id: id,
            rawInputId: rawInputId,
            rawJson: '{}',
            validationState: 'error',
            errorMessage: Value(error.code),
            createdAt: now,
          ),
        );
  }

  db.ExtractedItemsCompanion _toCompanion({
    required ExtractedItem item,
    required String aiParseResultId,
    required DateTime now,
  }) {
    return db.ExtractedItemsCompanion.insert(
      id: item.localId,
      rawInputId: item.rawInputId,
      aiParseResultId: aiParseResultId,
      type: item.type.apiValue,
      title: Value(item.title),
      content: Value(item.content),
      sourceText: item.sourceText,
      tagsJson: Value(jsonEncode(item.tags)),
      confidence: item.confidence,
      needUserConfirm: item.needUserConfirm,
      status: item.status.value,
      expiresAt: Value(item.expiresAt),
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, Object?> _parseResultToJson(ParseResult result) {
    return {
      'user_reply': result.userReply,
      'input_summary': result.inputSummary,
      'intent_types': [for (final type in result.intentTypes) type.apiValue],
      'items': [for (final item in result.items) _itemToJson(item)],
    };
  }

  Map<String, Object?> _itemToJson(ExtractedItem item) {
    return {
      'type': item.type.apiValue,
      'title': item.title,
      'content': item.content,
      'source_text': item.sourceText,
      'tags': item.tags,
      'confidence': item.confidence,
      'need_user_confirm': item.needUserConfirm,
      'expires_at': item.expiresAt?.toIso8601String(),
    };
  }

  List<ExtractedItem> _toPersistedItems({
    required List<ExtractedItem> items,
    required String rawInputId,
    required DateTime now,
  }) {
    return [
      for (final (index, item) in items.indexed)
        ExtractedItem(
          localId: '$rawInputId:$index',
          rawInputId: rawInputId,
          type: item.type,
          title: item.title,
          content: item.content,
          sourceText: item.sourceText,
          tags: item.tags,
          confidence: item.confidence,
          needUserConfirm: item.needUserConfirm,
          status: _shouldAutoSave(item: item, now: now)
              ? RecordStatus.confirmed
              : RecordStatus.pending,
          createdAt: now,
          updatedAt: now,
          expiresAt: item.expiresAt,
        ),
    ];
  }

  Future<db.ExtractedItem> _getExtractedItem(String id) {
    return (database.select(
      database.extractedItems,
    )..where((item) => item.id.equals(id))).getSingle();
  }

  bool _hasEdits({
    required String? editedTitle,
    required String? editedContent,
  }) {
    return editedTitle != null || editedContent != null;
  }

  bool _shouldAutoSave({required ExtractedItem item, required DateTime now}) {
    return switch (item.type) {
      ItemType.shortTermState => true,
      ItemType.taskCreate =>
        _inferTaskDue(
              text:
                  '${item.title ?? ''} ${item.content ?? ''} ${item.sourceText}',
              now: now,
            ).dueTime !=
            null,
      ItemType.lifeEvent =>
        item.sourceText.contains('记一下') || item.sourceText.contains('记住'),
      ItemType.taskUpdate ||
      ItemType.generalAnswer ||
      ItemType.profileCandidate => false,
    };
  }

  Future<void> _createOfficialRecordFromExtractedItem({
    required ExtractedItem item,
    required String officialRecordId,
    required DateTime now,
  }) async {
    final fallbackText = item.title ?? item.content ?? item.sourceText;
    final taskDue = _inferTaskDue(
      text: '${item.title ?? ''} ${item.content ?? ''} ${item.sourceText}',
      now: now,
    );

    switch (item.type) {
      case ItemType.taskCreate:
        await database
            .into(database.tasks)
            .insert(
              db.TasksCompanion.insert(
                id: officialRecordId,
                sourceRawInputId: item.rawInputId,
                sourceExtractedItemId: item.localId,
                title: fallbackText,
                description: Value(item.content),
                dueTimeText: Value(taskDue.dueTimeText),
                dueTime: Value(taskDue.dueTime),
                status: RecordStatus.confirmed.value,
                createdAt: now,
                updatedAt: now,
              ),
            );
      case ItemType.shortTermState:
        await database
            .into(database.shortTermStates)
            .insert(
              db.ShortTermStatesCompanion.insert(
                id: officialRecordId,
                sourceRawInputId: item.rawInputId,
                sourceExtractedItemId: item.localId,
                content: item.content ?? item.title ?? item.sourceText,
                tagsJson: Value(jsonEncode(item.tags)),
                validUntil: item.expiresAt ?? now.add(const Duration(days: 1)),
                status: RecordStatus.confirmed.value,
                createdAt: now,
                updatedAt: now,
              ),
            );
      case ItemType.lifeEvent:
        await database
            .into(database.lifeEvents)
            .insert(
              db.LifeEventsCompanion.insert(
                id: officialRecordId,
                sourceRawInputId: item.rawInputId,
                sourceExtractedItemId: item.localId,
                content: item.content ?? item.title ?? item.sourceText,
                tagsJson: Value(jsonEncode(item.tags)),
                status: RecordStatus.confirmed.value,
                createdAt: now,
                updatedAt: now,
              ),
            );
      case ItemType.taskUpdate:
      case ItemType.generalAnswer:
      case ItemType.profileCandidate:
        break;
    }
  }

  ({String? dueTimeText, DateTime? dueTime}) _inferTaskDue({
    required String text,
    required DateTime now,
  }) {
    if (text.contains('明天上午')) {
      return (
        dueTimeText: '明天上午',
        dueTime: DateTime(now.year, now.month, now.day + 1, 9),
      );
    }

    if (text.contains('明天下午')) {
      return (
        dueTimeText: '明天下午',
        dueTime: DateTime(now.year, now.month, now.day + 1, 14),
      );
    }

    if (text.contains('明天')) {
      return (
        dueTimeText: '明天',
        dueTime: DateTime(now.year, now.month, now.day + 1, 9),
      );
    }

    if (text.contains('今天')) {
      return (
        dueTimeText: '今天',
        dueTime: DateTime(now.year, now.month, now.day, now.hour),
      );
    }

    return (dueTimeText: null, dueTime: null);
  }
}
