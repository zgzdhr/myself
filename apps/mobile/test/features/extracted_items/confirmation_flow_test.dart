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
import 'package:mobile/domain/task_status.dart';
import 'package:mobile/features/extracted_items/extracted_items_controller.dart';
import 'package:mobile/features/reminders/task_reminder_scheduler.dart';

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

  test('auto-saved task schedules a local reminder candidate', () async {
    final reminderScheduler = _RecordingTaskReminderScheduler();
    final reminderController = ExtractedItemsController(
      database: database,
      parserClient: MockParserClient(
        parsedAtProvider: () => DateTime.utc(2026, 5, 31),
      ),
      taskReminderScheduler: reminderScheduler,
      rawInputIdFactory: () => 'raw-reminder',
      parseResultIdFactory: () => 'parse-reminder',
      officialRecordIdFactory: () => 'task-reminder',
      nowProvider: () => DateTime.utc(2026, 5, 31, 10),
    );

    await reminderController.submitInput('明天上午联系王总');

    expect(reminderScheduler.scheduled, hasLength(1));
    expect(reminderScheduler.scheduled.single.taskId, 'task-reminder');
    expect(reminderScheduler.scheduled.single.title, '联系王总');
    expect(reminderScheduler.scheduled.single.dueTime.year, 2026);
    expect(reminderScheduler.scheduled.single.dueTime.month, 6);
    expect(reminderScheduler.scheduled.single.dueTime.day, 1);
    expect(reminderScheduler.scheduled.single.dueTime.hour, 9);
    expect(reminderScheduler.scheduled.single.dueTime.minute, 0);
  });

  test('completed task update cancels the existing local reminder', () async {
    await _insertConfirmedTask(
      database,
      id: 'task-existing-reminder',
      title: '联系王总',
      dueTime: DateTime.utc(2026, 5, 31, 15),
    );

    final reminderScheduler = _RecordingTaskReminderScheduler();
    final taskUpdateController = _buildTaskUpdateController(
      database,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '联系王总',
        sourceText: '联系王总做完了',
        tags: const ['task'],
        confidence: 0.94,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: const TaskUpdateIntent(
          action: TaskUpdateAction.complete,
          targetTaskTitle: '联系王总',
          targetText: '联系王总',
        ),
      ),
      taskReminderScheduler: reminderScheduler,
    );

    final result = await taskUpdateController.submitInput('联系王总做完了');
    await taskUpdateController.applyTaskUpdate(item: result.items.single);

    expect(reminderScheduler.cancelled, ['task-existing-reminder']);
  });

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

  test('infers same-day implicit time words for task auto-save', () async {
    final eveningController = _buildTaskCreateController(
      database,
      rawInputId: 'raw-evening',
      title: '和同学吃烤鱼',
      sourceText: '今晚上要和同学吃烤鱼',
      now: DateTime.utc(2026, 5, 31, 10),
    );

    await eveningController.submitInput('今晚上要和同学吃烤鱼');

    final task = await database.select(database.tasks).getSingle();
    expect(task.title, '和同学吃烤鱼');
    expect(task.dueTimeText, '今晚');
    expect(task.dueTime!.year, 2026);
    expect(task.dueTime!.month, 5);
    expect(task.dueTime!.day, 31);
    expect(task.dueTime!.hour, 18);
  });

  test(
    'explicit clock time overrides same-day time segment defaults',
    () async {
      final eveningController = _buildTaskCreateController(
        database,
        rawInputId: 'raw-evening-clock',
        title: '出去玩',
        sourceText: '今晚上9点我要出去玩',
        now: DateTime.utc(2026, 5, 31, 10),
      );

      await eveningController.submitInput('今晚上9点我要出去玩');

      var task = await database.select(database.tasks).getSingle();
      expect(task.dueTimeText, '9点');
      expect(task.dueTime!.day, 31);
      expect(task.dueTime!.hour, 21);
      expect(task.dueTime!.minute, 0);

      await database.delete(database.tasks).go();
      await database.delete(database.extractedItems).go();
      await database.delete(database.aiParseResults).go();
      await database.delete(database.rawInputs).go();

      final afternoonController = _buildTaskCreateController(
        database,
        rawInputId: 'raw-afternoon-clock',
        title: '出去',
        sourceText: '下午1:20我要出去',
        now: DateTime.utc(2026, 5, 31, 10),
      );

      await afternoonController.submitInput('下午1:20我要出去');

      task = await database.select(database.tasks).getSingle();
      expect(task.dueTimeText, '1:20');
      expect(task.dueTime!.hour, 13);
      expect(task.dueTime!.minute, 20);
    },
  );

  test('uses reminder-friendly defaults for vague time segments', () async {
    final noonController = _buildTaskCreateController(
      database,
      rawInputId: 'raw-noon',
      title: '吃饭',
      sourceText: '中午吃饭',
      now: DateTime.utc(2026, 5, 31, 10),
    );

    await noonController.submitInput('中午吃饭');

    final task = await database.select(database.tasks).getSingle();
    expect(task.dueTimeText, '中午');
    expect(task.dueTime!.hour, 11);
  });

  test('does not convert explicit future date time words to today', () async {
    final fridayController = _buildTaskCreateController(
      database,
      rawInputId: 'raw-friday',
      title: '和同学吃烤鱼',
      sourceText: '周五下午和同学吃烤鱼',
      now: DateTime.utc(2026, 5, 31, 10),
    );

    await fridayController.submitInput('周五下午和同学吃烤鱼');

    final tasks = await database.getActiveTasks();
    final item = await _getExtractedItem(database, 'raw-friday:0');
    expect(tasks, isEmpty);
    expect(item.status, RecordStatus.pending.value);
  });

  test('keeps tomorrow evening out of same-day inference', () async {
    final tomorrowEveningController = _buildTaskCreateController(
      database,
      rawInputId: 'raw-tomorrow-evening',
      title: '和同学吃烤鱼',
      sourceText: '明天晚上和同学吃烤鱼',
      now: DateTime.utc(2026, 5, 31, 10),
    );

    await tomorrowEveningController.submitInput('明天晚上和同学吃烤鱼');

    final task = await database.select(database.tasks).getSingle();
    expect(task.dueTimeText, '明天晚上');
    expect(task.dueTime!.year, 2026);
    expect(task.dueTime!.month, 6);
    expect(task.dueTime!.day, 1);
    expect(task.dueTime!.hour, 18);
  });

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

  test('edit before confirming can set task due time manually', () async {
    final pendingTaskController = _buildPendingTaskController(database);
    await pendingTaskController.submitInput('回头整理资料');

    await pendingTaskController.confirmExtractedItem(
      extractedItemId: 'raw-2:0',
      editedTitle: '整理资料',
      hasEditedDueTime: true,
      editedDueTimeText: '手动选择',
      editedDueTime: DateTime(2026, 6, 8, 16, 30),
    );

    final task = await database.select(database.tasks).getSingle();
    expect(task.title, '整理资料');
    expect(task.dueTimeText, '手动选择');
    expect(task.dueTime, DateTime(2026, 6, 8, 16, 30));
  });

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
    expect(updatedTask.status, RecordStatus.confirmed.value);
    expect(updatedTask.taskStatus, TaskStatus.completed.value);
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
    expect(updatedTask.status, RecordStatus.confirmed.value);
    expect(updatedTask.taskStatus, TaskStatus.cancelled.value);
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

  test(
    'task update cleans generic suffix and matches concrete source target',
    () async {
      await _insertConfirmedTask(
        database,
        id: 'task-gaokao',
        title: '参加高考',
        dueTime: DateTime.utc(2026, 6, 1, 9),
      );
      final taskUpdateController = _buildTaskUpdateController(
        database,
        parsedItem: ParsedExtractedItem(
          localId: 'parsed:0',
          type: ItemType.taskUpdate,
          title: '那个事',
          sourceText: '参加高考那个事取消了',
          tags: const ['task'],
          confidence: 0.82,
          needUserConfirm: true,
          parsedAt: DateTime.utc(2026, 5, 31),
          taskUpdateIntent: TaskUpdateIntent(
            action: TaskUpdateAction.cancel,
            targetText: '那个事',
          ),
        ),
      );

      final result = await taskUpdateController.submitInput('参加高考那个事取消了');
      final updateResult = await taskUpdateController.applyTaskUpdate(
        item: result.items.single,
      );
      final cancelledTask = await _getTask(database, 'task-gaokao');

      expect(updateResult.state, TaskUpdateExecutionState.applied);
      expect(cancelledTask.status, RecordStatus.confirmed.value);
      expect(cancelledTask.taskStatus, TaskStatus.cancelled.value);
    },
  );

  test(
    'task update matches meeting target after 的事情 cancellation noise',
    () async {
      await _insertConfirmedTask(
        database,
        id: 'task-meeting',
        title: '今天下午开会',
        dueTime: DateTime.utc(2026, 5, 31, 14),
      );
      final taskUpdateController = _buildTaskUpdateController(
        database,
        parsedItem: ParsedExtractedItem(
          localId: 'parsed:0',
          type: ItemType.taskUpdate,
          title: '下午开会',
          sourceText: '下午开会的事情取消了',
          tags: const ['task'],
          confidence: 0.9,
          needUserConfirm: true,
          parsedAt: DateTime.utc(2026, 5, 31),
          taskUpdateIntent: TaskUpdateIntent(
            action: TaskUpdateAction.cancel,
            targetText: '下午开会的事情',
          ),
        ),
      );

      final result = await taskUpdateController.submitInput('下午开会的事情取消了');
      final updateResult = await taskUpdateController.applyTaskUpdate(
        item: result.items.single,
      );
      final cancelledTask = await _getTask(database, 'task-meeting');

      expect(updateResult.state, TaskUpdateExecutionState.applied);
      expect(cancelledTask.status, RecordStatus.confirmed.value);
      expect(cancelledTask.taskStatus, TaskStatus.cancelled.value);
    },
  );

  test(
    'task update plus energy state can match fitness cancellation target',
    () async {
      await _insertConfirmedTask(
        database,
        id: 'task-fitness',
        title: '今天下午去健身',
        dueTime: DateTime.utc(2026, 5, 31, 14),
      );
      final taskUpdateController = _buildTaskUpdateController(
        database,
        parsedItem: ParsedExtractedItem(
          localId: 'parsed:0',
          type: ItemType.taskUpdate,
          title: '健身',
          sourceText: '今天好累，健身不想去了',
          tags: const ['task'],
          confidence: 0.78,
          needUserConfirm: true,
          parsedAt: DateTime.utc(2026, 5, 31),
          taskUpdateIntent: TaskUpdateIntent(
            action: TaskUpdateAction.cancel,
            targetText: '健身',
          ),
        ),
      );

      final result = await taskUpdateController.submitInput('今天好累，健身不想去了');
      final updateResult = await taskUpdateController.applyTaskUpdate(
        item: result.items.single,
      );
      final cancelledTask = await _getTask(database, 'task-fitness');

      expect(updateResult.state, TaskUpdateExecutionState.applied);
      expect(cancelledTask.status, RecordStatus.confirmed.value);
      expect(cancelledTask.taskStatus, TaskStatus.cancelled.value);
    },
  );

  // ── B5/B6: edit / reject / parser error regression ──

  test('edits a matched task title after confirmation', () async {
    final reminderScheduler = _RecordingTaskReminderScheduler();
    await _insertConfirmedTask(
      database,
      id: 'task-existing-edit',
      title: '联系王总',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    final taskUpdateController = _buildTaskUpdateController(
      database,
      taskReminderScheduler: reminderScheduler,
      parsedItem: ParsedExtractedItem(
        localId: 'parsed:0',
        type: ItemType.taskUpdate,
        title: '联系王总',
        content: '改成联系张总',
        sourceText: '联系王总改成联系张总',
        tags: const ['task'],
        confidence: 0.9,
        needUserConfirm: true,
        parsedAt: DateTime.utc(2026, 5, 31),
        taskUpdateIntent: TaskUpdateIntent(
          action: TaskUpdateAction.edit,
          targetTaskTitle: '联系王总',
          targetText: '联系王总',
        ),
      ),
    );

    final result = await taskUpdateController.submitInput('联系王总改成联系张总');
    final updateResult = await taskUpdateController.applyTaskUpdate(
      item: result.items.single,
    );
    final updatedTask = await _getTask(database, 'task-existing-edit');

    expect(updateResult.state, TaskUpdateExecutionState.applied);
    expect(updatedTask.title, '改成联系张总');
    expect(updatedTask.status, RecordStatus.confirmed.value);
    expect(reminderScheduler.scheduled.single.title, '改成联系张总');
    expect(
      reminderScheduler.scheduled.single.dueTime.toUtc(),
      DateTime.utc(2026, 5, 31, 9),
    );
  });

  test(
    'rejecting a task_update item leaves the target task unchanged',
    () async {
      await _insertConfirmedTask(
        database,
        id: 'task-reject-target',
        title: '准备周报',
        dueTime: DateTime.utc(2026, 5, 31, 9),
      );
      final taskUpdateController = _buildTaskUpdateController(
        database,
        parsedItem: ParsedExtractedItem(
          localId: 'parsed:0',
          type: ItemType.taskUpdate,
          title: '准备周报',
          sourceText: '准备周报不用做了',
          tags: const ['task'],
          confidence: 0.9,
          needUserConfirm: true,
          parsedAt: DateTime.utc(2026, 5, 31),
          taskUpdateIntent: TaskUpdateIntent(
            action: TaskUpdateAction.cancel,
            targetTaskTitle: '准备周报',
            targetText: '准备周报',
          ),
        ),
      );

      final result = await taskUpdateController.submitInput('准备周报不用做了');
      await taskUpdateController.rejectExtractedItem(
        extractedItemId: result.items.single.localId,
      );
      final untouchedTask = await _getTask(database, 'task-reject-target');
      final rejectedItem = await _getExtractedItem(
        database,
        result.items.single.localId,
      );

      expect(untouchedTask.title, '准备周报');
      expect(untouchedTask.status, RecordStatus.confirmed.value);
      expect(rejectedItem.status, RecordStatus.rejected.value);
    },
  );

  test(
    'task_update submit failure does not modify any existing task',
    () async {
      await _insertConfirmedTask(
        database,
        id: 'task-error-target',
        title: '整理资料',
        dueTime: DateTime.utc(2026, 5, 31, 9),
      );
      final errorController = ExtractedItemsController(
        database: database,
        parserClient: _ErrorParserClient(),
        rawInputIdFactory: () => 'raw-error',
        parseResultIdFactory: () => 'parse-error',
        officialRecordIdFactory: () => 'official-error',
        nowProvider: () => DateTime.utc(2026, 5, 31),
      );

      await expectLater(
        errorController.submitInput('更新任务'),
        throwsA(isA<ParserFailure>()),
      );
      final untouchedTask = await _getTask(database, 'task-error-target');
      expect(untouchedTask.title, '整理资料');
      expect(untouchedTask.status, RecordStatus.confirmed.value);
    },
  );

  test(
    'cancel action keeps record visible with cancelled task status',
    () async {
      await _insertConfirmedTask(
        database,
        id: 'task-cancel-strategy',
        title: '不做了的任务',
        dueTime: DateTime.utc(2026, 5, 31, 9),
      );
      final taskUpdateController = _buildTaskUpdateController(
        database,
        parsedItem: ParsedExtractedItem(
          localId: 'parsed:0',
          type: ItemType.taskUpdate,
          title: '不做了的任务',
          sourceText: '不做了的任务取消',
          tags: const ['task'],
          confidence: 0.93,
          needUserConfirm: true,
          parsedAt: DateTime.utc(2026, 5, 31),
          taskUpdateIntent: TaskUpdateIntent(
            action: TaskUpdateAction.cancel,
            targetTaskTitle: '不做了的任务',
            targetText: '不做了的任务',
          ),
        ),
      );

      final result = await taskUpdateController.submitInput('不做了的任务取消');
      await taskUpdateController.applyTaskUpdate(item: result.items.single);
      final cancelledTask = await _getTask(database, 'task-cancel-strategy');

      expect(cancelledTask.status, RecordStatus.confirmed.value);
      expect(cancelledTask.taskStatus, TaskStatus.cancelled.value);
      expect(cancelledTask.title, '不做了的任务');
    },
  );

  // ── C3: auto-save boundary regression ──

  test('taskCreate that requires confirmation stays pending even with a time', () async {
    final controller = ExtractedItemsController(
      database: database,
      parserClient: _StaticParserClient(
        ParseResult(
          userReply: '我帮你整理出了一个任务。',
          inputSummary: '用户提到明天下午整理合同。',
          intentTypes: const [ItemType.taskCreate],
          items: [
            ParsedExtractedItem(
              localId: 'parsed:0',
              type: ItemType.taskCreate,
              title: '整理客户合同',
              sourceText: '明天下午整理客户合同',
              tags: const ['work'],
              confidence: 0.82,
              needUserConfirm: true,
              parsedAt: DateTime.utc(2026, 5, 31),
            ),
          ],
        ),
      ),
      rawInputIdFactory: () => 'raw-no-time',
      parseResultIdFactory: () => 'parse-no-time',
      officialRecordIdFactory: () => 'official-no-time',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    final result = await controller.submitInput('明天下午整理客户合同');

    expect(result.items.single.status, RecordStatus.pending);
    expect(await database.getActiveTasks(), isEmpty);
  });

  test('lifeEvent without memory keyword stays pending', () async {
    final controller = ExtractedItemsController(
      database: database,
      parserClient: _StaticParserClient(
        ParseResult(
          userReply: '我帮你记下这条经验。',
          inputSummary: '用户提到做菜经验。',
          intentTypes: const [ItemType.lifeEvent],
          items: [
            ParsedExtractedItem(
              localId: 'parsed:0',
              type: ItemType.lifeEvent,
              content: '做番茄炒蛋糖放多了',
              sourceText: '今天做番茄炒蛋糖放多了，下次少放',
              tags: const ['cooking'],
              confidence: 0.78,
              needUserConfirm: false,
              parsedAt: DateTime.utc(2026, 5, 31),
            ),
          ],
        ),
      ),
      rawInputIdFactory: () => 'raw-life-no-keyword',
      parseResultIdFactory: () => 'parse-life-no-keyword',
      officialRecordIdFactory: () => 'official-life-no-keyword',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    final result = await controller.submitInput('今天做番茄炒蛋糖放多了，下次少放');

    expect(result.items.single.status, RecordStatus.pending);
    expect(await database.getActiveLifeEvents(), isEmpty);
  });

  test('lifeEvent with 记一下 keyword auto-saves', () async {
    final controller = ExtractedItemsController(
      database: database,
      parserClient: _StaticParserClient(
        ParseResult(
          userReply: '我帮你记下这条经验。',
          inputSummary: '用户想记住一条教训。',
          intentTypes: const [ItemType.lifeEvent],
          items: [
            ParsedExtractedItem(
              localId: 'parsed:0',
              type: ItemType.lifeEvent,
              content: '会议室B栋空调有问题',
              sourceText: '记一下，会议室B栋空调有问题，下次订会避开',
              tags: const ['work', 'facility'],
              confidence: 0.85,
              needUserConfirm: false,
              parsedAt: DateTime.utc(2026, 5, 31),
            ),
          ],
        ),
      ),
      rawInputIdFactory: () => 'raw-life-keyword',
      parseResultIdFactory: () => 'parse-life-keyword',
      officialRecordIdFactory: () => 'official-life-keyword',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    final result = await controller.submitInput('记一下，会议室B栋空调有问题，下次订会避开');

    expect(result.items.single.status, RecordStatus.confirmed);
    final events = await database.getActiveLifeEvents();
    expect(events, hasLength(1));
    expect(events.single.content, contains('会议室'));
  });

  test('undone auto-saved task does not appear in active tasks', () async {
    await controller.submitInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');
    await controller.undoAutoSavedExtractedItem(extractedItemId: 'raw-1:0');

    final tasks = await database.getActiveTasks();
    expect(tasks, isEmpty);
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

ExtractedItemsController _buildTaskCreateController(
  db.AppDatabase database, {
  required String rawInputId,
  required String title,
  required String sourceText,
  required DateTime now,
}) {
  return ExtractedItemsController(
    database: database,
    parserClient: _StaticParserClient(
      ParseResult(
        userReply: '我先整理成一条任务。',
        inputSummary: sourceText,
        intentTypes: const [ItemType.taskCreate],
        items: [
          ParsedExtractedItem(
            localId: 'parsed:0',
            type: ItemType.taskCreate,
            title: title,
            sourceText: sourceText,
            tags: const ['任务'],
            confidence: 0.92,
            needUserConfirm: false,
            parsedAt: now,
          ),
        ],
      ),
    ),
    rawInputIdFactory: () => rawInputId,
    parseResultIdFactory: () => 'parse-$rawInputId',
    officialRecordIdFactory: () => 'official-$rawInputId',
    nowProvider: () => now,
  );
}

ExtractedItemsController _buildTaskUpdateController(
  db.AppDatabase database, {
  required ParsedExtractedItem parsedItem,
  TaskReminderScheduler? taskReminderScheduler,
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
    taskReminderScheduler: taskReminderScheduler,
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

class _ErrorParserClient implements ParserClient {
  @override
  Future<ParseResult> parseInput(String text) async {
    throw const ParserFailure(
      code: 'parser_service_error',
      userMessage: '解析服务暂时不可用。',
    );
  }
}

class _RecordingTaskReminderScheduler implements TaskReminderScheduler {
  final scheduled = <TaskReminderRequest>[];
  final cancelled = <String>[];

  @override
  Future<bool?> notificationsEnabled() async => true;

  @override
  Future<bool?> requestPermissions() async => true;

  @override
  Future<void> schedule(TaskReminderRequest request) async {
    scheduled.add(request);
  }

  @override
  Future<void> cancel(String taskId) async {
    cancelled.add(taskId);
  }
}
