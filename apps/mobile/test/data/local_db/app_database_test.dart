import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/domain/task_status.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('stores raw input, parse result, and pending extracted item', () async {
    final now = DateTime.utc(2026, 5, 31, 12);

    await _insertRawInput(database, now: now);
    await _insertParseResult(database, now: now);
    await _insertExtractedTask(database, now: now);

    final rawInput = await database.select(database.rawInputs).getSingle();
    final parseResult = await database
        .select(database.aiParseResults)
        .getSingle();
    final extractedItem = await database
        .select(database.extractedItems)
        .getSingle();

    expect(rawInput.inputText, '明天上午联系王总');
    expect(parseResult.validationState, 'valid');
    expect(extractedItem.type, ItemType.taskCreate.apiValue);
    expect(extractedItem.status, RecordStatus.pending.value);
  });

  test('confirms extracted items into task and profile records', () async {
    final now = DateTime.utc(2026, 5, 31, 12);

    await _insertRawInput(database, now: now);
    await _insertParseResult(database, now: now);
    await _insertExtractedTask(database, now: now);
    await _insertExtractedProfile(database, now: now);

    await database.confirmExtractedItemAsTask(
      taskId: 'task-1',
      extractedItemId: 'item-task',
      now: now,
    );
    await database.confirmExtractedItemAsProfileItem(
      profileItemId: 'profile-1',
      extractedItemId: 'item-profile',
      now: now,
    );

    final tasks = await database.getActiveTasks();
    final profiles = await database.getActiveProfileItems();
    final extractedItems = await database.select(database.extractedItems).get();

    expect(tasks.single.title, '联系王总');
    expect(tasks.single.taskStatus, TaskStatus.active.value);
    expect(profiles.single.content, '用户不喜欢太频繁的提醒');
    expect(extractedItems.map((item) => item.status).toSet(), {
      RecordStatus.confirmed.value,
    });
  });

  test(
    'marks extracted item as edited without creating an official record',
    () async {
      final now = DateTime.utc(2026, 5, 31, 12);

      await _insertRawInput(database, now: now);
      await _insertParseResult(database, now: now);
      await _insertExtractedTask(database, now: now);

      await database.updateExtractedItemStatus(
        id: 'item-task',
        status: RecordStatus.edited,
        updatedAt: now.add(const Duration(minutes: 1)),
      );

      final extractedItem = await database
          .select(database.extractedItems)
          .getSingle();
      final tasks = await database.select(database.tasks).get();

      expect(extractedItem.status, RecordStatus.edited.value);
      expect(tasks, isEmpty);
    },
  );

  test('deleted profile items are excluded from active queries', () async {
    final now = DateTime.utc(2026, 5, 31, 12);

    await _insertRawInput(database, now: now);
    await _insertParseResult(database, now: now);
    await _insertExtractedProfile(database, now: now);
    await database.confirmExtractedItemAsProfileItem(
      profileItemId: 'profile-1',
      extractedItemId: 'item-profile',
      now: now,
    );

    expect(await database.getActiveProfileItems(), hasLength(1));

    await database.markProfileItemDeleted(
      id: 'profile-1',
      updatedAt: now.add(const Duration(minutes: 1)),
    );

    expect(await database.getActiveProfileItems(), isEmpty);
  });

  test(
    'completed and cancelled tasks stay visible but leave active queries',
    () async {
      final now = DateTime.utc(2026, 5, 31, 12);

      await _insertRawInput(database, now: now);
      await _insertParseResult(database, now: now);
      await _insertExtractedTask(database, now: now);
      await database.confirmExtractedItemAsTask(
        taskId: 'task-1',
        extractedItemId: 'item-task',
        now: now,
      );

      await database.markTaskCompleted(
        id: 'task-1',
        updatedAt: now.add(const Duration(minutes: 1)),
      );

      expect(await database.getActiveTasks(), isEmpty);
      var visibleTasks = await database.getVisibleTasks();
      expect(visibleTasks.single.status, RecordStatus.confirmed.value);
      expect(visibleTasks.single.taskStatus, TaskStatus.completed.value);

      await database.markTaskCancelled(
        id: 'task-1',
        updatedAt: now.add(const Duration(minutes: 2)),
      );

      expect(await database.getActiveTasks(), isEmpty);
      visibleTasks = await database.getVisibleTasks();
      expect(visibleTasks.single.status, RecordStatus.confirmed.value);
      expect(visibleTasks.single.taskStatus, TaskStatus.cancelled.value);
    },
  );

  test('partial task update preserves unrelated task fields', () async {
    final now = DateTime(2026, 5, 31, 12);
    final originalStartTime = DateTime(2026, 6, 1, 9);
    final originalEndTime = DateTime(2026, 6, 1, 10);
    final originalDueTime = DateTime(2026, 6, 1, 9);
    final delayedDueTime = DateTime(2026, 6, 2, 14);

    await _insertRawInput(database, now: now);
    await _insertParseResult(database, now: now);
    await _insertExtractedTask(database, now: now);
    await database.confirmExtractedItemAsTask(
      taskId: 'task-1',
      extractedItemId: 'item-task',
      now: now,
    );
    await database.updateTaskById(
      id: 'task-1',
      description: const Value('需要保留的任务说明'),
      startTime: Value(originalStartTime),
      endTime: Value(originalEndTime),
      dueTimeText: const Value('明天上午'),
      dueTime: Value(originalDueTime),
      updatedAt: now,
    );

    await database.updateTaskById(
      id: 'task-1',
      dueTimeText: const Value('后天下午'),
      dueTime: Value(delayedDueTime),
      updatedAt: now.add(const Duration(minutes: 1)),
    );

    final task = await (database.select(
      database.tasks,
    )..where((row) => row.id.equals('task-1'))).getSingle();
    expect(task.description, '需要保留的任务说明');
    expect(task.startTime, originalStartTime);
    expect(task.endTime, originalEndTime);
    expect(task.dueTimeText, '后天下午');
    expect(task.dueTime, delayedDueTime);
  });

  test('stores, edits, and soft deletes daily summaries', () async {
    final now = DateTime.utc(2026, 6, 22, 20);
    final dayStart = DateTime.utc(2026, 6, 22);

    await database.saveDailySummary(
      updatedAt: now,
      summary: Summary(
        id: 'summary-1',
        summaryType: 'daily_summary',
        title: '6月22日复盘',
        content: '今天完成了一个关键任务。',
        encouragement: '能推进关键任务，说明你在恢复节奏。',
        improvementNotes: '上午启动偏慢，明天可以先做低阻力任务。',
        taskGuidance: '明天先处理明确截止时间的任务。',
        openItemsJson: '["等王总反馈"]',
        timeRangeStart: dayStart,
        timeRangeEnd: dayStart.add(const Duration(days: 1)),
        status: RecordStatus.confirmed.value,
        generatedBy: 'deepseek',
        modelName: null,
        promptVersion: 'review-daily-v1',
        confidence: 0.8,
        createdAt: now,
        updatedAt: now,
        userEditedAt: null,
        deletedAt: null,
      ),
      sources: [
        SummarySourcesCompanion.insert(
          id: 'source-1',
          summaryId: 'summary-1',
          sourceTable: 'tasks',
          sourceRecordId: 'task-1',
          sourceStatusAtGeneration: const Value('confirmed'),
          createdAt: now,
        ),
      ],
    );

    var summary = await database.getSummaryForDay(dayStart);
    expect(summary?.encouragement, contains('恢复节奏'));
    expect(await database.getSourcesForSummary('summary-1'), hasLength(1));

    await database.updateSummaryContent(
      id: 'summary-1',
      content: '今天完成了关键任务，并且复盘了启动偏慢的问题。',
      encouragement: '继续保持这个节奏。',
      improvementNotes: '明天先启动一个小任务。',
      taskGuidance: '先做短任务，再处理开放事项。',
      updatedAt: now.add(const Duration(minutes: 5)),
    );

    summary = await database.getSummaryForDay(dayStart);
    expect(summary?.status, RecordStatus.edited.value);
    expect(summary?.content, contains('启动偏慢'));

    await database.markSummaryDeleted(
      id: 'summary-1',
      updatedAt: now.add(const Duration(minutes: 10)),
    );

    expect(await database.getSummaryForDay(dayStart), null);
  });

  test('stores, confirms, edits, and soft deletes schedule plans', () async {
    final now = DateTime.utc(2026, 6, 23, 8);
    final dayStart = DateTime.utc(2026, 6, 23);

    await database.saveSchedulePlan(
      updatedAt: now,
      plan: SchedulePlan(
        id: 'plan-1',
        planDate: dayStart,
        title: '6月23日时间规划',
        overview: '上午轻启动，下午处理关键任务。',
        suggestionsJson: '["保留一点缓冲"]',
        unscheduledTaskIdsJson: '["task-2"]',
        status: RecordStatus.pending.value,
        generatedBy: 'deepseek',
        modelName: null,
        promptVersion: 'plan-daily-v1',
        confidence: 0.8,
        createdAt: now,
        updatedAt: now,
        confirmedAt: null,
        userEditedAt: null,
        deletedAt: null,
      ),
      blocks: [
        ScheduleBlocksCompanion.insert(
          id: 'block-1',
          planId: 'plan-1',
          title: '联系王总',
          blockType: 'task',
          startTime: dayStart.add(const Duration(hours: 15)),
          endTime: dayStart.add(const Duration(hours: 15, minutes: 30)),
          taskId: const Value('task-1'),
          note: const Value('先列沟通要点。'),
          reason: '任务有明确对象，适合下午处理。',
          sortOrder: 0,
          status: RecordStatus.pending.value,
          confidence: const Value(0.8),
          createdAt: now,
          updatedAt: now,
        ),
      ],
      sourcesByBlockId: {
        'block-1': [
          ScheduleBlockSourcesCompanion.insert(
            id: 'block-source-1',
            blockId: 'block-1',
            sourceTable: 'tasks',
            sourceRecordId: 'task-1',
            createdAt: now,
          ),
        ],
      },
    );

    var plan = await database.getSchedulePlanForDay(dayStart);
    expect(plan?.status, RecordStatus.pending.value);
    expect(await database.getScheduleBlocksForPlan('plan-1'), hasLength(1));
    expect(await database.getSourcesForScheduleBlock('block-1'), hasLength(1));

    await database.confirmSchedulePlan(
      id: 'plan-1',
      updatedAt: now.add(const Duration(minutes: 5)),
    );
    plan = await database.getSchedulePlanForDay(dayStart);
    expect(plan?.status, RecordStatus.confirmed.value);
    expect(plan?.confirmedAt, isA<DateTime>());

    await database.updateScheduleBlock(
      id: 'block-1',
      title: '联系王总前准备材料',
      blockType: 'task',
      startTime: dayStart.add(const Duration(hours: 14, minutes: 30)),
      endTime: dayStart.add(const Duration(hours: 15)),
      note: '先确认沟通材料。',
      reason: '用户手动调整到更早时间。',
      updatedAt: now.add(const Duration(minutes: 10)),
    );
    final block = (await database.getScheduleBlocksForPlan('plan-1')).single;
    expect(block.title, contains('准备材料'));
    plan = await database.getSchedulePlanForDay(dayStart);
    expect(plan?.status, RecordStatus.edited.value);

    await database.markScheduleBlockDeleted(
      id: 'block-1',
      updatedAt: now.add(const Duration(minutes: 15)),
    );
    expect(await database.getScheduleBlocksForPlan('plan-1'), isEmpty);

    await database.markSchedulePlanDeleted(
      id: 'plan-1',
      updatedAt: now.add(const Duration(minutes: 20)),
    );
    expect(await database.getSchedulePlanForDay(dayStart), null);
  });

  test('daily recurring rule generates unique task instances', () async {
    final now = DateTime(2026, 7, 6, 8);

    final rule = await database.createDailyRecurringTaskRule(
      title: '早上 7 点慢跑',
      description: '每日重复任务',
      startDate: now,
      endDate: now.add(const Duration(days: 2)),
      hour: 7,
      minute: 0,
      now: now,
    );

    var tasks = await database.getTasksForRange(
      start: DateTime(2026, 7, 6),
      end: DateTime(2026, 7, 10),
    );
    expect(
      tasks.where((task) => task.recurrenceRuleId == rule.id),
      hasLength(3),
    );

    await database.generateDailyRecurringTaskInstances(
      ruleId: rule.id,
      fromDay: now,
      days: 4,
      now: now.add(const Duration(minutes: 1)),
    );

    tasks = await database.getTasksForRange(
      start: DateTime(2026, 7, 6),
      end: DateTime(2026, 7, 10),
    );
    expect(
      tasks.where((task) => task.recurrenceRuleId == rule.id),
      hasLength(3),
    );
  });

  test('deleted recurring task instance is not regenerated', () async {
    final now = DateTime.utc(2026, 7, 6, 8);

    final rule = await database.createDailyRecurringTaskRule(
      title: '每日复习单词',
      startDate: now,
      hour: 21,
      minute: 30,
      now: now,
    );
    final tasks = await database.getTasksForRange(
      start: DateTime.utc(2026, 7, 6),
      end: DateTime.utc(2026, 7, 7),
    );
    final firstInstance = tasks.singleWhere(
      (task) => task.recurrenceRuleId == rule.id,
    );

    await database.markTaskDeleted(
      id: firstInstance.id,
      updatedAt: now.add(const Duration(minutes: 2)),
    );
    await database.generateDailyRecurringTaskInstances(
      ruleId: rule.id,
      fromDay: now,
      days: 1,
      now: now.add(const Duration(minutes: 3)),
    );

    final visibleTasks = await database.getTasksForRange(
      start: DateTime.utc(2026, 7, 6),
      end: DateTime.utc(2026, 7, 7),
    );
    expect(
      visibleTasks.where((task) => task.recurrenceRuleId == rule.id),
      isEmpty,
    );
  });

  test('starts and ends sedentary session', () async {
    final now = DateTime(2026, 7, 6, 9);

    final session = await database.startSedentarySession(startedAt: now);

    expect(session.reminderAt, now.add(const Duration(hours: 1)));
    expect((await database.getActiveSedentarySession())?.id, session.id);

    await database.endSedentarySession(
      id: session.id,
      endedAt: now.add(const Duration(minutes: 35)),
    );

    expect(await database.getActiveSedentarySession(), null);
    final sessions = await database.getSedentarySessionsForRange(
      start: DateTime(2026, 7, 6),
      end: DateTime(2026, 7, 7),
    );
    expect(sessions.single.endedAt, now.add(const Duration(minutes: 35)));
  });
}

Future<void> _insertRawInput(AppDatabase database, {required DateTime now}) {
  return database
      .into(database.rawInputs)
      .insert(
        RawInputsCompanion.insert(
          id: 'raw-1',
          inputText: '明天上午联系王总',
          createdAt: now,
        ),
      );
}

Future<void> _insertParseResult(AppDatabase database, {required DateTime now}) {
  return database
      .into(database.aiParseResults)
      .insert(
        AiParseResultsCompanion.insert(
          id: 'parse-1',
          rawInputId: 'raw-1',
          rawJson: '{}',
          validationState: 'valid',
          createdAt: now,
        ),
      );
}

Future<void> _insertExtractedTask(
  AppDatabase database, {
  required DateTime now,
}) {
  return database
      .into(database.extractedItems)
      .insert(
        ExtractedItemsCompanion.insert(
          id: 'item-task',
          rawInputId: 'raw-1',
          aiParseResultId: 'parse-1',
          type: ItemType.taskCreate.apiValue,
          title: const Value('联系王总'),
          sourceText: '明天上午联系王总',
          confidence: 0.9,
          needUserConfirm: true,
          status: RecordStatus.pending.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _insertExtractedProfile(
  AppDatabase database, {
  required DateTime now,
}) {
  return database
      .into(database.extractedItems)
      .insert(
        ExtractedItemsCompanion.insert(
          id: 'item-profile',
          rawInputId: 'raw-1',
          aiParseResultId: 'parse-1',
          type: ItemType.profileCandidate.apiValue,
          content: const Value('用户不喜欢太频繁的提醒'),
          sourceText: '我不喜欢太频繁的提醒',
          confidence: 0.86,
          needUserConfirm: true,
          status: RecordStatus.pending.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}
