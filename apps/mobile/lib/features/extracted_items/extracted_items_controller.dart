import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local_db/app_database.dart' as db;
import '../../data/parser/parser_client.dart';
import '../../domain/extracted_item.dart';
import '../../domain/item_type.dart';
import '../../domain/parse_result.dart';
import '../../domain/record_status.dart';
import '../../domain/task_status.dart';
import '../context/context_builder.dart';
import '../reminders/task_reminder_scheduler.dart';
import 'task_due_inference.dart';
import 'task_update_matcher.dart';

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
    TaskUpdateMatcher? taskUpdateMatcher,
    TaskReminderScheduler? taskReminderScheduler,
    String Function()? rawInputIdFactory,
    String Function()? parseResultIdFactory,
    String Function()? officialRecordIdFactory,
    DateTime Function()? nowProvider,
  }) : contextBuilder = contextBuilder ?? const ContextBuilder(),
       taskUpdateMatcher = taskUpdateMatcher ?? const TaskUpdateMatcher(),
       taskReminderCoordinator = TaskReminderCoordinator(
         scheduler: taskReminderScheduler ?? const NoopTaskReminderScheduler(),
       ),
       rawInputIdFactory = rawInputIdFactory ?? const Uuid().v4,
       parseResultIdFactory = parseResultIdFactory ?? const Uuid().v4,
       officialRecordIdFactory = officialRecordIdFactory ?? const Uuid().v4,
       nowProvider = nowProvider ?? DateTime.now;

  final db.AppDatabase database;
  final ParserClient parserClient;
  final ContextBuilder contextBuilder;
  final TaskUpdateMatcher taskUpdateMatcher;
  final TaskReminderCoordinator taskReminderCoordinator;
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
      final remindersToSync = <TaskReminderRequest>[];

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
            final reminderRequest =
                await _createOfficialRecordFromExtractedItem(
                  item: item,
                  officialRecordId: officialRecordIdFactory(),
                  now: now,
                );
            if (reminderRequest != null) {
              remindersToSync.add(reminderRequest);
            }
          }
        }
      });

      for (final reminderRequest in remindersToSync) {
        await taskReminderCoordinator.sync(
          taskId: reminderRequest.taskId,
          title: reminderRequest.title,
          dueTime: reminderRequest.dueTime,
          isActive: true,
          now: now,
        );
      }

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
        ? InferredTaskDue(
            dueTimeText: editedDueTimeText,
            dueTime: editedDueTime,
          )
        : inferTaskDue(
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

    if (ItemTypeApiValue.fromApiValue(item.type) == ItemType.taskCreate) {
      await taskReminderCoordinator.sync(
        taskId: officialRecordId,
        title: fallbackText,
        dueTime: taskDue.dueTime,
        isActive: true,
        now: now,
      );
    }
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
            : taskUpdateMatcher.firstTaskUpdateCandidate(
                intent.candidates,
                selectedTaskId,
              ),
      TaskUpdateResolution.ready => taskUpdateMatcher.firstCandidateOrNull(
        intent.candidates,
      ),
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

    if (taskUpdateMatcher.isDelayMissingNewTime(intent)) {
      return TaskUpdateExecutionResult(
        state: TaskUpdateExecutionState.needsSelection,
        candidates: intent.candidates,
      );
    }

    final now = nowProvider();
    await database.transaction(() async {
      switch (intent.action) {
        case TaskUpdateAction.complete:
          await database.markTaskCompleted(id: resolvedTask.id, updatedAt: now);
        case TaskUpdateAction.cancel:
          await database.markTaskCancelled(id: resolvedTask.id, updatedAt: now);
        case TaskUpdateAction.delay:
          await database.updateTaskById(
            id: resolvedTask.id,
            dueTimeText: Value(intent.dueTimeText),
            dueTime: Value(intent.dueTime),
            updatedAt: now,
          );
        case TaskUpdateAction.edit:
          final updatedTitle =
              item.content ?? item.title ?? resolvedTask.title;
          await database.updateTaskById(
            id: resolvedTask.id,
            title: Value(updatedTitle),
            updatedAt: now,
          );
      }

      await database.updateExtractedItemStatus(
        id: item.localId,
        status: RecordStatus.confirmed,
        updatedAt: now,
      );
    });

    final updatedTask = await database.getTaskById(resolvedTask.id);
    if (updatedTask == null) {
      await taskReminderCoordinator.sync(
        taskId: resolvedTask.id,
        title: resolvedTask.title,
        dueTime: null,
        isActive: false,
        now: now,
      );
    } else {
      await taskReminderCoordinator.sync(
        taskId: updatedTask.id,
        title: updatedTask.title,
        dueTime: updatedTask.dueTime,
        isActive:
            TaskStatus.fromValue(updatedTask.taskStatus) == TaskStatus.active,
        now: now,
      );
    }

    return const TaskUpdateExecutionResult(
      state: TaskUpdateExecutionState.applied,
    );
  }

  Future<void> undoAutoSavedExtractedItem({
    required String extractedItemId,
  }) async {
    final item = await _getExtractedItem(extractedItemId);
    final type = ItemTypeApiValue.fromApiValue(item.type);
    final taskToCancel = type == ItemType.taskCreate
        ? await database.getTaskBySourceExtractedItemId(extractedItemId)
        : null;

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

    if (taskToCancel != null) {
      await taskReminderCoordinator.sync(
        taskId: taskToCancel.id,
        title: taskToCancel.title,
        dueTime: null,
        isActive: false,
        now: nowProvider(),
      );
    }
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
        ? InferredTaskDue(
            dueTimeText: editedDueTimeText,
            dueTime: editedDueTime,
          )
        : inferTaskDue(
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

    if (type == ItemType.taskCreate) {
      final task = await database.getTaskBySourceExtractedItemId(
        extractedItemId,
      );
      if (task != null) {
        await taskReminderCoordinator.sync(
          taskId: task.id,
          title: fallbackText,
          dueTime: taskDue.dueTime,
          isActive: true,
          now: now,
        );
      }
    }
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
              item.needUserConfirm ||
                  !_shouldAutoSaveValues(
                    type: item.type,
                    title: item.title,
                    content: item.content,
                    sourceText: item.sourceText,
                    now: now,
                  )
              ? RecordStatus.pending
              : RecordStatus.confirmed,
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
    if (item.needUserConfirm) {
      return false;
    }

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
        inferTaskDue(
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

    final matchResult = taskUpdateMatcher.match(
      intent: taskUpdateIntent,
      sourceText: sourceText,
      activeTaskCandidates: activeTaskCandidates,
    );

    return taskUpdateIntent.copyWith(
      candidates: matchResult.candidates,
      resolution: matchResult.resolution,
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

  String _taskUpdateActionToApiValue(TaskUpdateAction action) {
    return switch (action) {
      TaskUpdateAction.complete => 'complete',
      TaskUpdateAction.cancel => 'cancel',
      TaskUpdateAction.delay => 'delay',
      TaskUpdateAction.edit => 'edit',
    };
  }

  Future<TaskReminderRequest?> _createOfficialRecordFromExtractedItem({
    required ExtractedItem item,
    required String officialRecordId,
    required DateTime now,
  }) async {
    final fallbackText = item.title ?? item.content ?? item.sourceText;
    final taskDue = inferTaskDue(
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
                taskStatus: Value(TaskStatus.active.value),
                createdAt: now,
                updatedAt: now,
              ),
            );
        return taskDue.dueTime == null
            ? null
            : TaskReminderRequest(
                taskId: officialRecordId,
                title: fallbackText,
                dueTime: taskDue.dueTime!,
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
        return null;
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
        return null;
      case ItemType.taskUpdate:
      case ItemType.generalAnswer:
      case ItemType.profileCandidate:
        return null;
    }
  }
}
