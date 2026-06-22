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
