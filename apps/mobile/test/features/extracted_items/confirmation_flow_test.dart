import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart' as db;
import 'package:mobile/data/parser/mock_parser_client.dart';
import 'package:mobile/data/parser/parser_client.dart';
import 'package:mobile/domain/extracted_item.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/domain/parse_result.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/features/extracted_items/extracted_items_controller.dart';

void main() {
  late db.AppDatabase database;
  late ExtractedItemsController controller;
  late int rawInputCounter;
  late int officialRecordCounter;

  setUp(() async {
    database = db.AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    rawInputCounter = 0;
    officialRecordCounter = 0;
    controller = ExtractedItemsController(
      database: database,
      parserClient: MockParserClient(
        parsedAtProvider: () => DateTime.utc(2026, 5, 31),
      ),
      rawInputIdFactory: () => 'raw-${++rawInputCounter}',
      parseResultIdFactory: () => 'parse-1',
      officialRecordIdFactory: () => 'official-${++officialRecordCounter}',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'submitInput auto-saves near-term task and short-term state but leaves profile candidate pending',
    () async {
      final result = await controller.submitInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');

      final tasks = await database.getActiveTasks();
      final states = await database.getActiveShortTermStates(
        now: DateTime.utc(2026, 5, 31, 12),
      );
      final profiles = await database.getActiveProfileItems();
      final taskItem = await _getExtractedItem(database, 'raw-1:0');
      final stateItem = await _getExtractedItem(database, 'raw-1:1');
      final profileItem = await _getExtractedItem(database, 'raw-1:2');

      expect(result.items.map((item) => item.status), [
        RecordStatus.confirmed,
        RecordStatus.confirmed,
        RecordStatus.pending,
      ]);
      expect(tasks.single.title, '联系王总');
      expect(states.single.content, '用户今天感觉疲惫');
      expect(profiles, isEmpty);
      expect(taskItem.status, RecordStatus.confirmed.value);
      expect(stateItem.status, RecordStatus.confirmed.value);
      expect(profileItem.status, RecordStatus.pending.value);
    },
  );

  test(
    'submitInput binds raw input, parse result, and extracted items to the controller-owned rawInputId',
    () async {
      final result = await controller.submitInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');

      final rawInput = await database.select(database.rawInputs).getSingle();
      final parseResult = await database
          .select(database.aiParseResults)
          .getSingle();
      final extractedItems = await database
          .select(database.extractedItems)
          .get();

      expect(result.rawInputId, 'raw-1');
      expect(rawInput.id, 'raw-1');
      expect(parseResult.rawInputId, rawInput.id);
      expect(extractedItems.map((item) => item.rawInputId).toSet(), {
        rawInput.id,
      });
      expect(extractedItems.map((item) => item.id), [
        'raw-1:0',
        'raw-1:1',
        'raw-1:2',
      ]);
    },
  );

  test(
    'undo auto-saved extracted item removes official record and marks it deleted',
    () async {
      await controller.submitInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');

      await controller.undoAutoSavedExtractedItem(extractedItemId: 'raw-1:0');
      await controller.undoAutoSavedExtractedItem(extractedItemId: 'raw-1:1');

      final tasks = await database.getActiveTasks();
      final states = await database.getActiveShortTermStates(
        now: DateTime.utc(2026, 5, 31, 12),
      );
      final taskItem = await _getExtractedItem(database, 'raw-1:0');
      final stateItem = await _getExtractedItem(database, 'raw-1:1');

      expect(tasks, isEmpty);
      expect(states, isEmpty);
      expect(taskItem.status, RecordStatus.deleted.value);
      expect(stateItem.status, RecordStatus.deleted.value);
    },
  );

  test(
    'confirms task item into tasks and marks extracted item confirmed',
    () async {
      final pendingTaskController = _buildPendingTaskController(database);
      await pendingTaskController.submitInput('联系王总');
      await pendingTaskController.confirmExtractedItem(
        extractedItemId: 'raw-2:0',
      );

      final task = await database.select(database.tasks).getSingle();
      final extractedItem = await _getExtractedItem(database, 'raw-2:0');

      expect(task.title, '联系王总');
      expect(task.dueTimeText, null);
      expect(task.dueTime, null);
      expect(task.status, RecordStatus.confirmed.value);
      expect(extractedItem.status, RecordStatus.confirmed.value);
    },
  );

  test(
    'auto-saved short-term state is active with expiry after submit',
    () async {
      await controller.submitInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');

      final activeStates = await database.getActiveShortTermStates(
        now: DateTime.utc(2026, 5, 31, 12),
      );
      final extractedItem = await _getExtractedItem(database, 'raw-1:1');

      expect(activeStates.single.content, '用户今天感觉疲惫');
      expect(activeStates.single.validUntil.toUtc(), DateTime.utc(2026, 6, 1));
      expect(extractedItem.status, RecordStatus.confirmed.value);
    },
  );

  test(
    'profile candidate only becomes profile item after confirmation',
    () async {
      await controller.submitInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');
      expect(await database.getActiveProfileItems(), isEmpty);

      await controller.confirmExtractedItem(extractedItemId: 'raw-1:2');

      final profiles = await database.getActiveProfileItems();
      final extractedItem = await _getExtractedItem(database, 'raw-1:2');

      expect(profiles.single.content, '用户不喜欢太频繁的提醒');
      expect(extractedItem.status, RecordStatus.confirmed.value);
    },
  );

  test(
    'edit before confirming creates official record from edited value',
    () async {
      final pendingTaskController = _buildPendingTaskController(database);
      await pendingTaskController.submitInput('联系王总');
      await pendingTaskController.confirmExtractedItem(
        extractedItemId: 'raw-2:0',
        editedTitle: '给王总发微信',
        editedContent: '先发微信确认明天上午沟通时间',
      );

      final task = await database.select(database.tasks).getSingle();
      final extractedItem = await _getExtractedItem(database, 'raw-2:0');

      expect(task.title, '给王总发微信');
      expect(task.description, '先发微信确认明天上午沟通时间');
      expect(extractedItem.title, '给王总发微信');
      expect(extractedItem.content, '先发微信确认明天上午沟通时间');
      expect(extractedItem.status, RecordStatus.edited.value);
    },
  );

  test('rejects item without creating an official record', () async {
    await controller.submitInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');
    await controller.rejectExtractedItem(extractedItemId: 'raw-1:2');

    final extractedItem = await _getExtractedItem(database, 'raw-1:2');

    expect(extractedItem.status, RecordStatus.rejected.value);
    expect(await database.getActiveProfileItems(), isEmpty);
  });

  test('completes a matched task after confirmation', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-1',
      title: '联系王总',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '联系王总',
        sourceText: '联系王总已经完成了',
        tags: const ['task'],
        confidence: 0.93,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.complete,
          targetTaskTitle: '联系王总',
          targetText: '联系王总',
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('联系王总已经完成了');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final updatedTask = await _getTask(database, 'task-existing-1');
    final extractedItem = await _getExtractedItem(database, 'raw-3:0');

    expect(updateResult.state, TaskUpdateExecutionState.applied);
    expect(updatedTask.status, RecordStatus.archived.value);
    expect(extractedItem.status, RecordStatus.confirmed.value);
  });

  test('delays a matched task after confirmation', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-2',
      title: '准备方案',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '准备方案',
        sourceText: '把准备方案延期到明天上午',
        tags: const ['task'],
        confidence: 0.94,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.delay,
          targetTaskTitle: '准备方案',
          targetText: '准备方案',
          dueTimeText: '明天上午',
          dueTime: DateTime.utc(2026, 6, 1, 9),
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('把准备方案延期到明天上午');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final updatedTask = await _getTask(database, 'task-existing-2');

    expect(updateResult.state, TaskUpdateExecutionState.applied);
    expect(updatedTask.status, RecordStatus.confirmed.value);
    expect(updatedTask.dueTimeText, '明天上午');
    expect(updatedTask.dueTime!.toUtc(), DateTime.utc(2026, 6, 1, 9));
  });

  test('cancels a matched task after confirmation', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-3',
      title: '客户资料',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '客户资料',
        sourceText: '那个客户资料不用做了',
        tags: const ['task'],
        confidence: 0.92,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.cancel,
          targetTaskTitle: '客户资料',
          targetText: '客户资料',
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('那个客户资料不用做了');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final updatedTask = await _getTask(database, 'task-existing-3');

    expect(updateResult.state, TaskUpdateExecutionState.applied);
    expect(updatedTask.status, RecordStatus.deleted.value);
  });

  test('ambiguous task update requires selection before applying', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-4',
      title: '联系王总-上海',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    await _insertConfirmedTask(
      database,
      id: 'task-existing-5',
      title: '联系王总-北京',
      dueTime: DateTime.utc(2026, 5, 31, 10),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '联系王总',
        sourceText: '把联系王总改到后天',
        tags: const ['task'],
        confidence: 0.9,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.delay,
          targetText: '联系王总',
          dueTimeText: '后天',
          dueTime: DateTime.utc(2026, 6, 2, 9),
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('把联系王总改到后天');
    final pendingResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final appliedResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
      selectedTaskId: 'task-existing-5',
    );
    final untouchedTask = await _getTask(database, 'task-existing-4');
    final updatedTask = await _getTask(database, 'task-existing-5');

    expect(pendingResult.state, TaskUpdateExecutionState.needsSelection);
    expect(pendingResult.candidates.map((task) => task.id), [
      'task-existing-4',
      'task-existing-5',
    ]);
    expect(appliedResult.state, TaskUpdateExecutionState.applied);
    expect(untouchedTask.dueTime!.toUtc(), DateTime.utc(2026, 5, 31, 9));
    expect(updatedTask.dueTimeText, '后天');
    expect(updatedTask.dueTime!.toUtc(), DateTime.utc(2026, 6, 2, 9));
  });

  test('no match task update creates no official change', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-6',
      title: '联系张总',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '联系李总',
        sourceText: '联系李总已经完成了',
        tags: const ['task'],
        confidence: 0.89,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.complete,
          targetTaskTitle: '联系李总',
          targetText: '联系李总',
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('联系李总已经完成了');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final existingTask = await _getTask(database, 'task-existing-6');
    final extractedItem = await _getExtractedItem(database, 'raw-3:0');

    expect(updateResult.state, TaskUpdateExecutionState.noMatch);
    expect(existingTask.status, RecordStatus.confirmed.value);
    expect(existingTask.title, '联系张总');
    expect(extractedItem.status, RecordStatus.pending.value);
  });

  test('archived task does not participate in task update matching', () async {
    await _insertTaskWithStatus(
      database,
      id: 'task-archived-1',
      title: '联系王总',
      dueTime: DateTime.utc(2026, 5, 31, 9),
      status: RecordStatus.archived,
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '联系王总',
        sourceText: '联系王总已经完成了',
        tags: const ['task'],
        confidence: 0.9,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.complete,
          targetTaskTitle: '联系王总',
          targetText: '联系王总',
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('联系王总已经完成了');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final archivedTask = await _getTask(database, 'task-archived-1');

    expect(updateResult.state, TaskUpdateExecutionState.noMatch);
    expect(archivedTask.status, RecordStatus.archived.value);
  });

  test('deleted task does not participate in task update matching', () async {
    await _insertTaskWithStatus(
      database,
      id: 'task-deleted-1',
      title: '客户资料',
      dueTime: DateTime.utc(2026, 5, 31, 9),
      status: RecordStatus.deleted,
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '客户资料',
        sourceText: '客户资料不用做了',
        tags: const ['task'],
        confidence: 0.9,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.cancel,
          targetTaskTitle: '客户资料',
          targetText: '客户资料',
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('客户资料不用做了');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final deletedTask = await _getTask(database, 'task-deleted-1');

    expect(updateResult.state, TaskUpdateExecutionState.noMatch);
    expect(deletedTask.status, RecordStatus.deleted.value);
  });

  test('empty task update target resolves to no match', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-7',
      title: '联系王总',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: null,
        sourceText: '完成了',
        tags: const ['task'],
        confidence: 0.7,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: const TaskUpdateIntent(
          action: TaskUpdateAction.complete,
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('完成了');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final existingTask = await _getTask(database, 'task-existing-7');

    expect(updateResult.state, TaskUpdateExecutionState.noMatch);
    expect(existingTask.status, RecordStatus.confirmed.value);
  });

  test('delay without a new time does not clear existing due time', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-8',
      title: '准备方案',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '准备方案',
        sourceText: '准备方案延期一下',
        tags: const ['task'],
        confidence: 0.88,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.delay,
          targetTaskTitle: '准备方案',
          targetText: '准备方案',
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('准备方案延期一下');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final existingTask = await _getTask(database, 'task-existing-8');
    final extractedItem = await _getExtractedItem(database, 'raw-3:0');

    expect(updateResult.state, TaskUpdateExecutionState.needsSelection);
    expect(updateResult.candidates.map((task) => task.id), ['task-existing-8']);
    expect(existingTask.dueTimeText, '今天');
    expect(existingTask.dueTime!.toUtc(), DateTime.utc(2026, 5, 31, 9));
    expect(extractedItem.status, RecordStatus.pending.value);
  });

  test('generic task update target resolves to no match', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-9',
      title: '那个事',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '那个事',
        sourceText: '那个事完成了',
        tags: const ['task'],
        confidence: 0.72,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.complete,
          targetText: '那个事',
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('那个事完成了');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final existingTask = await _getTask(database, 'task-existing-9');

    expect(updateResult.state, TaskUpdateExecutionState.noMatch);
    expect(existingTask.status, RecordStatus.confirmed.value);
  });
}

Future<db.ExtractedItem> _getExtractedItem(db.AppDatabase database, String id) {
  return (database.select(
    database.extractedItems,
  )..where((item) => item.id.equals(id))).getSingle();
}

ExtractedItemsController _buildPendingTaskController(db.AppDatabase database) {
  return ExtractedItemsController(
    database: database,
    parserClient: _StaticParserClient(
      ParseResult(
        userReply: '我先整理成一条待确认任务。',
        inputSummary: '用户提到联系王总。',
        intentTypes: const [ItemType.taskCreate],
        items: [
          ParsedExtractedItem(
            localId: 'parsed:0',
            type: ItemType.taskCreate,
            title: '联系王总',
            content: null,
            sourceText: '联系王总',
            tags: const ['任务'],
            confidence: 0.92,
            needUserConfirm: true,
            parsedAt: DateTime.utc(2026, 5, 31),
          ),
        ],
      ),
    ),
    rawInputIdFactory: () => 'raw-2',
    parseResultIdFactory: () => 'parse-2',
    officialRecordIdFactory: () => 'official-pending-task',
    nowProvider: () => DateTime.utc(2026, 5, 31),
  );
}

ExtractedItemsController _buildTaskUpdateController(
  db.AppDatabase database, {
  required ParsedExtractedItem parsedItem,
}) {
  return ExtractedItemsController(
    database: database,
    parserClient: _StaticParserClient(
      ParseResult(
        userReply: '我先整理出这条任务更新。',
        inputSummary: '用户提到更新已有任务。',
        intentTypes: const [ItemType.taskUpdate],
        items: [parsedItem],
      ),
    ),
    rawInputIdFactory: () => 'raw-3',
    parseResultIdFactory: () => 'parse-3',
    officialRecordIdFactory: () => 'official-task-update',
    nowProvider: () => DateTime.utc(2026, 5, 31),
  );
}

Future<void> _insertConfirmedTask(
  db.AppDatabase database, {
  required String id,
  required String title,
  required DateTime dueTime,
}) async {
  await _insertTaskWithStatus(
    database,
    id: id,
    title: title,
    dueTime: dueTime,
    status: RecordStatus.confirmed,
  );
}

Future<void> _insertTaskWithStatus(
  db.AppDatabase database, {
  required String id,
  required String title,
  required DateTime dueTime,
  required RecordStatus status,
}) async {
  await database
      .into(database.rawInputs)
      .insert(
        db.RawInputsCompanion.insert(
          id: 'raw-$id',
          inputText: title,
          createdAt: DateTime.utc(2026, 5, 31),
        ),
      );
  await database
      .into(database.aiParseResults)
      .insert(
        db.AiParseResultsCompanion.insert(
          id: 'parse-$id',
          rawInputId: 'raw-$id',
          rawJson: '{}',
          validationState: 'valid',
          createdAt: DateTime.utc(2026, 5, 31),
        ),
      );
  await database
      .into(database.extractedItems)
      .insert(
        db.ExtractedItemsCompanion.insert(
          id: 'item-$id',
          rawInputId: 'raw-$id',
          aiParseResultId: 'parse-$id',
          type: ItemType.taskCreate.apiValue,
          title: Value(title),
          sourceText: title,
          confidence: 0.9,
          needUserConfirm: true,
          status: status.value,
          createdAt: DateTime.utc(2026, 5, 31),
          updatedAt: DateTime.utc(2026, 5, 31),
        ),
      );
  await database
      .into(database.tasks)
      .insert(
        db.TasksCompanion.insert(
          id: id,
          sourceRawInputId: 'raw-$id',
          sourceExtractedItemId: 'item-$id',
          title: title,
          dueTimeText: Value('今天'),
          dueTime: Value(dueTime),
          status: status.value,
          createdAt: DateTime.utc(2026, 5, 31),
          updatedAt: DateTime.utc(2026, 5, 31),
        ),
      );
}

Future<db.Task> _getTask(db.AppDatabase database, String id) {
  return (database.select(
    database.tasks,
  )..where((task) => task.id.equals(id))).getSingle();
}

class _StaticParserClient implements ParserClient {
  const _StaticParserClient(this.result);

  final ParseResult result;

  @override
  Future<ParseResult> parseInput(String text) async {
    return result;
  }
}
