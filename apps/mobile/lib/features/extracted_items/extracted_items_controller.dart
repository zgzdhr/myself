import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local_db/app_database.dart' as db;
import '../../data/parser/parser_client.dart';
import '../../domain/extracted_item.dart';
import '../../domain/item_type.dart';
import '../../domain/parse_result.dart';
import '../../domain/record_status.dart';
import '../context/context_builder.dart';

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

enum TaskUpdateExecutionState {
  applied,
  needsSelection,
  noMatch,
}

class TaskUpdateExecutionResult {
  const TaskUpdateExecutionResult({
    required this.state,
    this.candidates = const [],
  });

  final TaskUpdateExecutionState state;
  final List<TaskUpdateCandidate> candidates;
}

class ExtractedItemsController {
  ExtractedItemsController({
    required this.database,
    required this.parserClient,
    ContextBuilder? contextBuilder,
    String Function()? rawInputIdFactory,
    String Function()? parseResultIdFactory,
    String Function()? officialRecordIdFactory,
    DateTime Function()? nowProvider,
  }) : contextBuilder = contextBuilder ?? const ContextBuilder(),
       rawInputIdFactory = rawInputIdFactory ?? const Uuid().v4,
       parseResultIdFactory = parseResultIdFactory ?? const Uuid().v4,
       officialRecordIdFactory = officialRecordIdFactory ?? const Uuid().v4,
       nowProvider = nowProvider ?? DateTime.now;

  final db.AppDatabase database;
  final ParserClient parserClient;
  final ContextBuilder contextBuilder;
  final String Function() rawInputIdFactory;
  final String Function() parseResultIdFactory;
  final String Function() officialRecordIdFactory;
  final DateTime Function() nowProvider;

  static const autoSaveHint = '已自动整理，可修改或撤销';
  static const maxInputLength = 2000;

  Future<SubmitInputResult> submitInput(String text) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      throw const ParserFailure(
        code: 'empty_input',
        userMessage: '请先输入你想整理的内容。',
      );
    }

    if (trimmedText.length > maxInputLength) {
      throw const ParserFailure(
        code: 'input_too_long',
        userMessage: '输入内容过长，请精简到 2000 字以内再试。',
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
      final saveableParsedItems = [
        for (final item in parseResult.items)
          if (item.type != ItemType.generalAnswer) item,
      ];
      final persistedItems = await _toPersistedItems(
        items: saveableParsedItems,
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

  Future<TaskUpdateExecutionResult> applyTaskUpdate({
    required ExtractedItem item,
    String? selectedTaskId,
  }) async {
    final intent = item.taskUpdateIntent;
    if (item.type != ItemType.taskUpdate || intent == null) {
      throw StateError('Task update metadata is required to apply task updates.');
    }

    final resolvedTask = switch (intent.resolution) {
      TaskUpdateResolution.noMatch => null,
      TaskUpdateResolution.needsSelection =>
        selectedTaskId == null
            ? null
            : _firstTaskUpdateCandidate(
                intent.candidates,
                selectedTaskId,
              ),
      TaskUpdateResolution.ready => _firstCandidateOrNull(intent.candidates),
    };

    if (intent.resolution == TaskUpdateResolution.noMatch) {
      return const TaskUpdateExecutionResult(
        state: TaskUpdateExecutionState.noMatch,
      );
    }

    if (intent.resolution == TaskUpdateResolution.needsSelection &&
        resolvedTask == null) {
      return TaskUpdateExecutionResult(
        state: TaskUpdateExecutionState.needsSelection,
        candidates: intent.candidates,
      );
    }

    if (resolvedTask == null) {
      return const TaskUpdateExecutionResult(
        state: TaskUpdateExecutionState.noMatch,
      );
    }

    final now = nowProvider();
    await database.transaction(() async {
      switch (intent.action) {
        case TaskUpdateAction.complete:
          await database.markTaskArchived(id: resolvedTask.id, updatedAt: now);
        case TaskUpdateAction.cancel:
          await database.markTaskDeleted(id: resolvedTask.id, updatedAt: now);
        case TaskUpdateAction.delay:
          await database.updateTaskById(
            id: resolvedTask.id,
            dueTimeText: intent.dueTimeText,
            dueTime: intent.dueTime,
            updatedAt: now,
          );
        case TaskUpdateAction.edit:
          await database.updateTaskById(
            id: resolvedTask.id,
            title: item.content ?? item.title ?? resolvedTask.title,
            updatedAt: now,
          );
      }

      await database.updateExtractedItemStatus(
        id: item.localId,
        status: RecordStatus.confirmed,
        updatedAt: now,
      );
    });

    return const TaskUpdateExecutionResult(
      state: TaskUpdateExecutionState.applied,
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

  Map<String, Object?> _itemToJson(ParsedExtractedItem item) {
    return {
      'type': item.type.apiValue,
      'title': item.title,
      'content': item.content,
      'source_text': item.sourceText,
      'tags': item.tags,
      'confidence': item.confidence,
      'need_user_confirm': item.needUserConfirm,
      'expires_at': item.expiresAt?.toIso8601String(),
      'target_task_title': item.taskUpdateIntent?.targetTaskTitle,
      'target_text': item.taskUpdateIntent?.targetText,
      'update_action': item.taskUpdateIntent == null
          ? null
          : _taskUpdateActionToApiValue(item.taskUpdateIntent!.action),
      'due_time_text': item.taskUpdateIntent?.dueTimeText,
      'due_time_iso': item.taskUpdateIntent?.dueTime?.toIso8601String(),
    };
  }

  Future<List<ExtractedItem>> _toPersistedItems({
    required List<ParsedExtractedItem> items,
    required String rawInputId,
    required DateTime now,
  }) async {
    final persistedItems = <ExtractedItem>[];

    for (final item in items) {
      final resolvedTaskUpdateIntent = item.taskUpdateIntent == null
          ? null
          : await _resolveTaskUpdateIntent(item.taskUpdateIntent!);
      persistedItems.add(
        ExtractedItem(
          localId: _persistedLocalId(
            parsedLocalId: item.localId,
            rawInputId: rawInputId,
          ),
          rawInputId: rawInputId,
          type: item.type,
          title: _resolvePersistedTitle(
            item: item,
            taskUpdateIntent: resolvedTaskUpdateIntent,
          ),
          content: _resolvePersistedContent(
            item: item,
            taskUpdateIntent: resolvedTaskUpdateIntent,
          ),
          sourceText: item.sourceText,
          tags: item.tags,
          confidence: item.confidence,
          needUserConfirm: item.needUserConfirm,
          status: _shouldAutoSaveValues(
                type: item.type,
                title: item.title,
                content: item.content,
                sourceText: item.sourceText,
                now: now,
              )
              ? RecordStatus.confirmed
              : RecordStatus.pending,
          createdAt: now,
          updatedAt: now,
          expiresAt: item.expiresAt,
          taskUpdateIntent: resolvedTaskUpdateIntent,
        ),
      );
    }

    return persistedItems;
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
    return _shouldAutoSaveValues(
      type: item.type,
      title: item.title,
      content: item.content,
      sourceText: item.sourceText,
      now: now,
    );
  }

  bool _shouldAutoSaveValues({
    required ItemType type,
    required String? title,
    required String? content,
    required String sourceText,
    required DateTime now,
  }) {
    return switch (type) {
      ItemType.shortTermState => true,
      ItemType.taskCreate =>
        _inferTaskDue(
              text:
                  '${title ?? ''} ${content ?? ''} $sourceText',
              now: now,
            ).dueTime !=
            null,
      ItemType.lifeEvent =>
        sourceText.contains('记一下') || sourceText.contains('记住'),
      ItemType.taskUpdate ||
      ItemType.generalAnswer ||
      ItemType.profileCandidate => false,
    };
  }

  Future<TaskUpdateIntent> _resolveTaskUpdateIntent(
    TaskUpdateIntent taskUpdateIntent,
  ) async {
    final package = await contextBuilder.buildTaskUpdateResolution(
      database: database,
      now: nowProvider(),
    );
    final activeTaskCandidates = package.candidates;

    final targetQuery =
        taskUpdateIntent.targetTaskTitle ??
        taskUpdateIntent.targetText ??
        '';
    final normalizedQuery = _normalizeTaskText(targetQuery);

    if (normalizedQuery.isEmpty) {
      return taskUpdateIntent.copyWith(
        candidates: const [],
        resolution: TaskUpdateResolution.noMatch,
      );
    }

    final exactMatches = [
      for (final candidate in activeTaskCandidates)
        if (_normalizeTaskText(candidate.title) == normalizedQuery)
          TaskUpdateCandidate(
            id: candidate.id,
            title: candidate.title,
            dueTimeText: candidate.dueTimeText,
          ),
    ];
    final containsMatches = [
      for (final candidate in activeTaskCandidates)
        if (_normalizeTaskText(candidate.title).contains(normalizedQuery))
          TaskUpdateCandidate(
            id: candidate.id,
            title: candidate.title,
            dueTimeText: candidate.dueTimeText,
          ),
    ];
    final matches = exactMatches.isNotEmpty ? exactMatches : containsMatches;

    return taskUpdateIntent.copyWith(
      candidates: matches,
      resolution: switch (matches.length) {
        0 => TaskUpdateResolution.noMatch,
        1 => TaskUpdateResolution.ready,
        _ => TaskUpdateResolution.needsSelection,
      },
    );
  }

  String _persistedLocalId({
    required String parsedLocalId,
    required String rawInputId,
  }) {
    final parseIndex = parsedLocalId.split(':').last;
    return '$rawInputId:$parseIndex';
  }

  String? _resolvePersistedTitle({
    required ParsedExtractedItem item,
    required TaskUpdateIntent? taskUpdateIntent,
  }) {
    if (item.type != ItemType.taskUpdate) {
      return item.title;
    }

    return taskUpdateIntent?.targetLabel ?? item.title ?? item.sourceText;
  }

  String? _resolvePersistedContent({
    required ParsedExtractedItem item,
    required TaskUpdateIntent? taskUpdateIntent,
  }) {
    if (item.type != ItemType.taskUpdate || taskUpdateIntent == null) {
      return item.content;
    }

    return switch (taskUpdateIntent.resolution) {
      TaskUpdateResolution.noMatch => '没找到对应任务',
      TaskUpdateResolution.needsSelection => '请选择要更新的任务',
      TaskUpdateResolution.ready => switch (taskUpdateIntent.action) {
        TaskUpdateAction.complete => '将标记为已完成',
        TaskUpdateAction.cancel => '将取消这个任务',
        TaskUpdateAction.delay =>
          '将延期到 ${taskUpdateIntent.dueTimeText ?? '新的时间'}',
        TaskUpdateAction.edit => '将更新这个任务',
      },
    };
  }

  String _normalizeTaskText(String value) {
    return value.trim().replaceAll(' ', '').toLowerCase();
  }

  String _taskUpdateActionToApiValue(TaskUpdateAction action) {
    return switch (action) {
      TaskUpdateAction.complete => 'complete',
      TaskUpdateAction.cancel => 'cancel',
      TaskUpdateAction.delay => 'delay',
      TaskUpdateAction.edit => 'edit',
    };
  }

  TaskUpdateCandidate? _firstCandidateOrNull(
    List<TaskUpdateCandidate> candidates,
  ) {
    return candidates.isEmpty ? null : candidates.first;
  }

  TaskUpdateCandidate? _firstTaskUpdateCandidate(
    List<TaskUpdateCandidate> candidates,
    String id,
  ) {
    for (final candidate in candidates) {
      if (candidate.id == id) {
        return candidate;
      }
    }
    return null;
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
