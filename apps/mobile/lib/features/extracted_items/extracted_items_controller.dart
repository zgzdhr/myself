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

class PendingExtractedBatch {
  const PendingExtractedBatch({
    required this.rawInputId,
    required this.createdAt,
    required this.items,
  });

  final String rawInputId;
  final DateTime createdAt;
  final List<ExtractedItem> items;
}

enum TaskUpdateExecutionState { applied, needsSelection, noMatch }

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

  Future<List<PendingExtractedBatch>> getRecentPendingBatches({
    int batchLimit = 3,
  }) async {
    final pendingRows =
        await (database.select(database.extractedItems)
              ..where((item) => item.status.equals(RecordStatus.pending.value))
              ..orderBy([
                (item) => OrderingTerm(
                  expression: item.createdAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();

    final rawInputIds = <String>[];
    for (final row in pendingRows) {
      if (!rawInputIds.contains(row.rawInputId)) {
        rawInputIds.add(row.rawInputId);
      }
      if (rawInputIds.length == batchLimit) {
        break;
      }
    }

    final batches = <PendingExtractedBatch>[];
    for (final rawInputId in rawInputIds) {
      final rawInput = await (database.select(
        database.rawInputs,
      )..where((row) => row.id.equals(rawInputId))).getSingle();
      final rows = [
        for (final row in pendingRows)
          if (row.rawInputId == rawInputId) row,
      ]..sort((left, right) => left.createdAt.compareTo(right.createdAt));

      batches.add(
        PendingExtractedBatch(
          rawInputId: rawInputId,
          createdAt: rawInput.createdAt,
          items: [for (final row in rows) await _toDomainExtractedItem(row)],
        ),
      );
    }

    return batches;
  }

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
    bool hasEditedDueTime = false,
    String? editedDueTimeText,
    DateTime? editedDueTime,
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
    final taskDue = hasEditedDueTime
        ? (dueTimeText: editedDueTimeText, dueTime: editedDueTime)
        : _inferTaskDue(
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
      throw StateError(
        'Task update metadata is required to apply task updates.',
      );
    }

    final resolvedTask = switch (intent.resolution) {
      TaskUpdateResolution.noMatch => null,
      TaskUpdateResolution.needsSelection =>
        selectedTaskId == null
            ? null
            : _firstTaskUpdateCandidate(intent.candidates, selectedTaskId),
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

    if (_isDelayMissingNewTime(intent)) {
      return TaskUpdateExecutionResult(
        state: TaskUpdateExecutionState.needsSelection,
        candidates: intent.candidates,
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
    bool hasEditedDueTime = false,
    String? editedDueTimeText,
    DateTime? editedDueTime,
  }) async {
    final item = await _getExtractedItem(extractedItemId);
    final now = nowProvider();
    final type = ItemTypeApiValue.fromApiValue(item.type);
    final title = editedTitle ?? item.title;
    final content = editedContent ?? item.content;
    final fallbackText = title ?? content ?? item.sourceText;
    final taskDue = hasEditedDueTime
        ? (dueTimeText: editedDueTimeText, dueTime: editedDueTime)
        : _inferTaskDue(
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
          : await _resolveTaskUpdateIntent(
              item.taskUpdateIntent!,
              sourceText: item.sourceText,
            );
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
          status:
              _shouldAutoSaveValues(
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

  Future<ExtractedItem> _toDomainExtractedItem(db.ExtractedItem row) async {
    final type = ItemTypeApiValue.fromApiValue(row.type);
    final taskUpdateIntent = type == ItemType.taskUpdate
        ? await _readPersistedTaskUpdateIntent(row)
        : null;

    return ExtractedItem(
      localId: row.id,
      rawInputId: row.rawInputId,
      type: type,
      title: row.title,
      content: row.content,
      sourceText: row.sourceText,
      tags: _decodeTags(row.tagsJson),
      confidence: row.confidence,
      needUserConfirm: row.needUserConfirm,
      status: RecordStatusValue.fromValue(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      expiresAt: row.expiresAt,
      taskUpdateIntent: taskUpdateIntent,
    );
  }

  Future<TaskUpdateIntent?> _readPersistedTaskUpdateIntent(
    db.ExtractedItem row,
  ) async {
    final parseResult =
        await (database.select(database.aiParseResults)
              ..where((parse) => parse.id.equals(row.aiParseResultId)))
            .getSingleOrNull();
    if (parseResult == null || parseResult.rawJson.isEmpty) {
      return null;
    }

    final itemIndex = int.tryParse(row.id.split(':').last);
    if (itemIndex == null) {
      return null;
    }

    try {
      final json = jsonDecode(parseResult.rawJson) as Map<String, Object?>;
      final items = json['items'] as List<Object?>? ?? const [];
      if (itemIndex >= items.length) {
        return null;
      }
      final itemJson = items[itemIndex] as Map<String, Object?>;
      final intent = _readTaskUpdateIntentFromJson(itemJson);
      return intent == null
          ? null
          : _resolveTaskUpdateIntent(
              intent,
              sourceText: itemJson['source_text'] as String? ?? row.sourceText,
            );
    } catch (_) {
      return null;
    }
  }

  List<String> _decodeTags(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson) as List<Object?>;
      return decoded.whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }

  TaskUpdateIntent? _readTaskUpdateIntentFromJson(Map<String, Object?> json) {
    final actionValue = json['update_action'] as String?;
    if (actionValue == null) {
      return null;
    }

    final dueTimeIso = json['due_time_iso'] as String?;
    return TaskUpdateIntent(
      action: TaskUpdateAction.fromApiValue(actionValue),
      targetTaskTitle: json['target_task_title'] as String?,
      targetText: json['target_text'] as String?,
      dueTimeText: json['due_time_text'] as String?,
      dueTime: dueTimeIso == null ? null : DateTime.parse(dueTimeIso),
    );
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
              text: '${title ?? ''} ${content ?? ''} $sourceText',
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
    TaskUpdateIntent taskUpdateIntent, {
    required String sourceText,
  }) async {
    final package = await contextBuilder.buildTaskUpdateResolution(
      database: database,
      now: nowProvider(),
    );
    final activeTaskCandidates = [
      for (final candidate in package.candidates)
        TaskUpdateCandidate(
          id: candidate.id,
          title: candidate.title,
          dueTimeText: candidate.dueTimeText,
        ),
    ];

    final normalizedQueries = _taskUpdateMatchQueries(
      taskUpdateIntent: taskUpdateIntent,
      sourceText: sourceText,
    );

    if (normalizedQueries.isEmpty) {
      return taskUpdateIntent.copyWith(
        candidates: const [],
        resolution: TaskUpdateResolution.noMatch,
      );
    }

    final matches = _matchTaskUpdateCandidates(
      activeTaskCandidates: activeTaskCandidates,
      normalizedQueries: normalizedQueries,
    );
    final resolution = _resolveTaskUpdateResolution(
      intent: taskUpdateIntent,
      matches: matches,
    );

    return taskUpdateIntent.copyWith(
      candidates: matches,
      resolution: resolution,
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
        TaskUpdateAction.edit => item.content ?? '将更新这个任务',
      },
    };
  }

  String _normalizeTaskText(String value) {
    var normalized = value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[，。！？、,.!?；;：:]'), '')
        .toLowerCase();

    const noisePhrases = [
      '这件事情',
      '那件事情',
      '这个事情',
      '那个事情',
      '这件事',
      '那件事',
      '这个事',
      '那个事',
      '这个任务',
      '那个任务',
      '的事情',
      '这事',
      '那事',
      '事情',
      '任务',
      '一下',
    ];
    for (final phrase in noisePhrases) {
      normalized = normalized.replaceAll(phrase, '');
    }

    const actionNoise = [
      '已经做完了',
      '做完了',
      '完成了',
      '搞定了',
      '处理好了',
      '不用去了',
      '不想去了',
      '不去了',
      '不用做了',
      '不想做了',
      '先不做了',
      '不用开了',
      '不想开了',
      '不开了',
      '取消掉',
      '取消了',
      '取消',
      '改天再说',
      '算了',
    ];
    for (final phrase in actionNoise) {
      normalized = normalized.replaceAll(phrase, '');
    }

    return normalized;
  }

  List<String> _taskUpdateMatchQueries({
    required TaskUpdateIntent taskUpdateIntent,
    required String sourceText,
  }) {
    final rawQueries = [
      taskUpdateIntent.targetTaskTitle,
      taskUpdateIntent.targetText,
      sourceText,
    ];

    final queries = <String>[];
    for (final rawQuery in rawQueries) {
      final normalizedQuery = _normalizeTaskText(rawQuery ?? '');
      if (normalizedQuery.isEmpty || _isGenericTaskTarget(normalizedQuery)) {
        continue;
      }
      if (!queries.contains(normalizedQuery)) {
        queries.add(normalizedQuery);
      }
    }
    return queries;
  }

  List<TaskUpdateCandidate> _matchTaskUpdateCandidates({
    required List<TaskUpdateCandidate> activeTaskCandidates,
    required List<String> normalizedQueries,
  }) {
    final exactMatches = _uniqueTaskUpdateCandidates([
      for (final candidate in activeTaskCandidates)
        if (normalizedQueries.contains(_normalizeTaskText(candidate.title)))
          candidate,
    ]);
    if (exactMatches.isNotEmpty) {
      return exactMatches;
    }

    final containsMatches = _uniqueTaskUpdateCandidates([
      for (final candidate in activeTaskCandidates)
        if (_taskTitleContainsAnyQuery(candidate.title, normalizedQueries))
          candidate,
    ]);
    if (containsMatches.isNotEmpty) {
      return containsMatches;
    }

    return _uniqueTaskUpdateCandidates([
      for (final candidate in activeTaskCandidates)
        if (_hasStrongTaskTokenOverlap(
          title: candidate.title,
          normalizedQueries: normalizedQueries,
        ))
          candidate,
    ]);
  }

  bool _taskTitleContainsAnyQuery(
    String title,
    List<String> normalizedQueries,
  ) {
    final normalizedTitle = _normalizeTaskText(title);
    return normalizedQueries.any(
      (query) =>
          normalizedTitle.contains(query) || query.contains(normalizedTitle),
    );
  }

  bool _hasStrongTaskTokenOverlap({
    required String title,
    required List<String> normalizedQueries,
  }) {
    final titleTokens = _taskMatchTokens(title);
    if (titleTokens.isEmpty) {
      return false;
    }

    for (final query in normalizedQueries) {
      final queryTokens = _taskMatchTokens(query);
      if (queryTokens.isEmpty) {
        continue;
      }
      if (queryTokens.any(titleTokens.contains)) {
        return true;
      }
    }
    return false;
  }

  List<String> _taskMatchTokens(String value) {
    final normalized = _normalizeTaskText(value);
    if (normalized.isEmpty || _isGenericTaskTarget(normalized)) {
      return const [];
    }

    const semanticTokens = [
      '高考',
      '健身',
      '开会',
      '会议',
      '王总',
      '张总',
      '李总',
      '客户',
      '资料',
      '方案',
      '周报',
      'ppt',
      '合同',
    ];

    final tokens = <String>[];
    for (final token in semanticTokens) {
      if (normalized.contains(token.toLowerCase())) {
        tokens.add(token.toLowerCase());
      }
    }

    final chineseChunks = RegExp(r'[\u4e00-\u9fa5]{2,}')
        .allMatches(normalized)
        .map((match) => match.group(0)!)
        .where((chunk) => chunk.length >= 2);
    for (final chunk in chineseChunks) {
      if (!tokens.contains(chunk)) {
        tokens.add(chunk);
      }
    }

    final latinChunks = RegExp(r'[a-z0-9]{2,}')
        .allMatches(normalized)
        .map((match) => match.group(0)!)
        .where((chunk) => chunk.length >= 2);
    for (final chunk in latinChunks) {
      if (!tokens.contains(chunk)) {
        tokens.add(chunk);
      }
    }

    return tokens;
  }

  List<TaskUpdateCandidate> _uniqueTaskUpdateCandidates(
    List<TaskUpdateCandidate> candidates,
  ) {
    final seen = <String>{};
    final unique = <TaskUpdateCandidate>[];
    for (final candidate in candidates) {
      if (seen.add(candidate.id)) {
        unique.add(candidate);
      }
    }
    return unique;
  }

  TaskUpdateResolution _resolveTaskUpdateResolution({
    required TaskUpdateIntent intent,
    required List<TaskUpdateCandidate> matches,
  }) {
    if (matches.isEmpty) {
      return TaskUpdateResolution.noMatch;
    }

    if (_isDelayMissingNewTime(intent)) {
      return TaskUpdateResolution.needsSelection;
    }

    return matches.length == 1
        ? TaskUpdateResolution.ready
        : TaskUpdateResolution.needsSelection;
  }

  bool _isDelayMissingNewTime(TaskUpdateIntent intent) {
    return intent.action == TaskUpdateAction.delay &&
        intent.dueTimeText == null &&
        intent.dueTime == null;
  }

  bool _isGenericTaskTarget(String normalizedQuery) {
    const genericTargets = {
      '那个事',
      '这个事',
      '那件事',
      '这件事',
      '这个任务',
      '那个任务',
      '刚才那个',
      '之前那个',
      '刚才',
      '之前',
      '它',
    };
    return genericTargets.contains(normalizedQuery);
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
    DateTime atTime(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
    }

    final explicitClockTime = _firstExplicitClockTime(text);
    DateTime dueTimeFor(int dayOffset, int defaultHour) {
      if (explicitClockTime == null) {
        return atTime(dayOffset, defaultHour);
      }
      return atTime(
        dayOffset,
        _resolveClockHour(hour: explicitClockTime.hour, text: text),
        explicitClockTime.minute,
      );
    }

    String timeTextFor(String fallbackText) {
      return explicitClockTime?.text ?? fallbackText;
    }

    if (text.contains('明天上午')) {
      return (dueTimeText: timeTextFor('明天上午'), dueTime: dueTimeFor(1, 9));
    }

    if (text.contains('明天下午')) {
      return (dueTimeText: timeTextFor('明天下午'), dueTime: dueTimeFor(1, 14));
    }

    if (text.contains('明天晚上') || text.contains('明晚') || text.contains('明天傍晚')) {
      return (
        dueTimeText: timeTextFor(text.contains('明天傍晚') ? '明天傍晚' : '明天晚上'),
        dueTime: dueTimeFor(1, 18),
      );
    }

    if (text.contains('明天')) {
      return (dueTimeText: timeTextFor('明天'), dueTime: dueTimeFor(1, 9));
    }

    if (_hasExplicitDateOutsideTodayOrTomorrow(text)) {
      return (dueTimeText: _firstRecognizedTimeText(text), dueTime: null);
    }

    if (text.contains('今天上午') || text.contains('上午')) {
      return (
        dueTimeText: timeTextFor(text.contains('今天上午') ? '今天上午' : '上午'),
        dueTime: dueTimeFor(0, 9),
      );
    }

    if (text.contains('今天中午') || text.contains('中午')) {
      return (
        dueTimeText: timeTextFor(text.contains('今天中午') ? '今天中午' : '中午'),
        dueTime: dueTimeFor(0, 11),
      );
    }

    if (text.contains('今天下午') || text.contains('今下午') || text.contains('下午')) {
      return (
        dueTimeText: timeTextFor(
          text.contains('今天下午') || text.contains('今下午') ? '今天下午' : '下午',
        ),
        dueTime: dueTimeFor(0, 14),
      );
    }

    if (text.contains('今天晚上') ||
        text.contains('今晚上') ||
        text.contains('今晚') ||
        text.contains('晚上') ||
        text.contains('傍晚')) {
      return (
        dueTimeText: timeTextFor(
          text.contains('今天晚上') || text.contains('今晚上') || text.contains('今晚')
              ? '今晚'
              : text.contains('傍晚')
              ? '傍晚'
              : '晚上',
        ),
        dueTime: dueTimeFor(0, 18),
      );
    }

    if (text.contains('今天')) {
      return (dueTimeText: timeTextFor('今天'), dueTime: dueTimeFor(0, now.hour));
    }

    if (explicitClockTime != null) {
      return (
        dueTimeText: explicitClockTime.text,
        dueTime: dueTimeFor(0, now.hour),
      );
    }

    return (dueTimeText: null, dueTime: null);
  }

  bool _hasExplicitDateOutsideTodayOrTomorrow(String text) {
    return RegExp(r'(周|星期|礼拜)[一二三四五六日天]').hasMatch(text) ||
        RegExp(r'\d{1,2}[月/-]\d{1,2}[日号]?').hasMatch(text) ||
        RegExp(r'(后天|大后天|下周|下星期|下礼拜)').hasMatch(text);
  }

  String? _firstRecognizedTimeText(String text) {
    const timeTexts = [
      '上午',
      '中午',
      '下午',
      '傍晚',
      '晚上',
      '今晚',
      '今晚上',
      '今天上午',
      '今天中午',
      '今天下午',
      '今天晚上',
      '明天上午',
      '明天下午',
      '明天晚上',
      '明天傍晚',
    ];
    for (final timeText in timeTexts) {
      if (text.contains(timeText)) return timeText;
    }
    return null;
  }

  ({String text, int hour, int minute})? _firstExplicitClockTime(String text) {
    final numericColonMatch = RegExp(
      r'(\d{1,2})[:：](\d{1,2})',
    ).firstMatch(text);
    if (numericColonMatch != null) {
      return (
        text: numericColonMatch.group(0)!,
        hour: int.parse(numericColonMatch.group(1)!),
        minute: int.parse(numericColonMatch.group(2)!),
      );
    }

    final numericPointMatch = RegExp(
      r'(\d{1,2})点(半|(\d{1,2})分?)?',
    ).firstMatch(text);
    if (numericPointMatch != null) {
      final halfText = numericPointMatch.group(2);
      final minuteText = numericPointMatch.group(3);
      return (
        text: numericPointMatch.group(0)!,
        hour: int.parse(numericPointMatch.group(1)!),
        minute: halfText == '半' ? 30 : int.tryParse(minuteText ?? '') ?? 0,
      );
    }

    final chinesePointMatch = RegExp(
      r'([一二两三四五六七八九十]{1,3})点(半)?',
    ).firstMatch(text);
    if (chinesePointMatch != null) {
      final hour = _parseChineseHour(chinesePointMatch.group(1)!);
      if (hour != null) {
        return (
          text: chinesePointMatch.group(0)!,
          hour: hour,
          minute: chinesePointMatch.group(2) == '半' ? 30 : 0,
        );
      }
    }

    return null;
  }

  int _resolveClockHour({required int hour, required String text}) {
    if (hour == 12) return hour;
    if (text.contains('下午') ||
        text.contains('晚上') ||
        text.contains('今晚') ||
        text.contains('今晚上') ||
        text.contains('傍晚') ||
        text.contains('明晚')) {
      return hour < 12 ? hour + 12 : hour;
    }
    return hour;
  }

  int? _parseChineseHour(String text) {
    const digits = {
      '一': 1,
      '二': 2,
      '两': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };
    if (text == '十') return 10;
    if (text.startsWith('十')) {
      return 10 + (digits[text.substring(1)] ?? 0);
    }
    if (text.endsWith('十')) {
      return (digits[text.substring(0, 1)] ?? 0) * 10;
    }
    if (text.contains('十')) {
      final parts = text.split('十');
      return (digits[parts[0]] ?? 0) * 10 + (digits[parts[1]] ?? 0);
    }
    return digits[text];
  }
}
