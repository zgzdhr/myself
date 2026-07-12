import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/record_status.dart';
import '../../domain/task_status.dart';
import 'local_data_protection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    RawInputs,
    AiParseResults,
    ExtractedItems,
    Tasks,
    ShortTermStates,
    LifeEvents,
    ProfileItems,
    Summaries,
    SummarySources,
    SchedulePlans,
    ScheduleBlocks,
    ScheduleBlockSources,
    RecurringTaskRules,
    SedentarySessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(tasks, tasks.taskStatus);
          await customStatement(
            "UPDATE tasks SET task_status = '${TaskStatus.completed.value}', "
            "status = '${RecordStatus.confirmed.value}' "
            "WHERE status = '${RecordStatus.archived.value}'",
          );
        }
        if (from < 3) {
          await m.createTable(summaries);
          await m.createTable(summarySources);
        }
        if (from < 4) {
          await m.createTable(schedulePlans);
          await m.createTable(scheduleBlocks);
          await m.createTable(scheduleBlockSources);
        }
        if (from < 5) {
          await m.addColumn(tasks, tasks.recurrenceRuleId);
          await m.addColumn(tasks, tasks.recurrenceDate);
          await m.createTable(recurringTaskRules);
          await m.createTable(sedentarySessions);
        }
        if (from < 6) {
          await m.addColumn(tasks, tasks.startTime);
          await m.addColumn(tasks, tasks.endTime);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      final file = File(path.join(directory.path, 'personal_memory.sqlite'));
      // iOS cannot apply the backup-exclusion resource flag to a path that
      // does not exist yet. Creating the empty SQLite file first keeps the
      // privacy boundary reliable on the first app launch as well.
      await file.create(recursive: true);
      await excludeLocalDatabaseFromDeviceBackup(file.path);
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<void> updateExtractedItemStatus({
    required String id,
    required RecordStatus status,
    required DateTime updatedAt,
  }) {
    return (update(extractedItems)..where((item) => item.id.equals(id))).write(
      ExtractedItemsCompanion(
        status: Value(status.value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> confirmExtractedItemAsTask({
    required String taskId,
    required String extractedItemId,
    required DateTime now,
  }) async {
    final item = await (select(
      extractedItems,
    )..where((row) => row.id.equals(extractedItemId))).getSingle();

    await transaction(() async {
      await into(tasks).insert(
        TasksCompanion.insert(
          id: taskId,
          sourceRawInputId: item.rawInputId,
          sourceExtractedItemId: item.id,
          title: item.title ?? item.content ?? item.sourceText,
          description: Value(item.content),
          status: RecordStatus.confirmed.value,
          taskStatus: Value(TaskStatus.active.value),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await updateExtractedItemStatus(
        id: extractedItemId,
        status: RecordStatus.confirmed,
        updatedAt: now,
      );
    });
  }

  Future<Task> createManualTask({
    required String title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? dueTimeText,
    DateTime? dueTime,
    String priority = 'medium',
    String? recurrenceRuleId,
    DateTime? recurrenceDate,
    required DateTime now,
  }) async {
    final taskId = const Uuid().v4();
    final rawInputId = const Uuid().v4();
    final parseResultId = const Uuid().v4();
    final extractedItemId = const Uuid().v4();

    await transaction(() async {
      await into(rawInputs).insert(
        RawInputsCompanion.insert(
          id: rawInputId,
          inputText: title,
          source: const Value('manual'),
          createdAt: now,
        ),
      );
      await into(aiParseResults).insert(
        AiParseResultsCompanion.insert(
          id: parseResultId,
          rawInputId: rawInputId,
          rawJson: '{}',
          validationState: 'manual',
          createdAt: now,
        ),
      );
      await into(extractedItems).insert(
        ExtractedItemsCompanion.insert(
          id: extractedItemId,
          rawInputId: rawInputId,
          aiParseResultId: parseResultId,
          type: 'task_create',
          title: Value(title),
          content: Value(description),
          sourceText: title,
          confidence: 1,
          needUserConfirm: false,
          status: RecordStatus.confirmed.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await into(tasks).insert(
        TasksCompanion.insert(
          id: taskId,
          sourceRawInputId: rawInputId,
          sourceExtractedItemId: extractedItemId,
          title: title,
          description: Value(description),
          startTime: Value(startTime),
          endTime: Value(endTime),
          dueTimeText: Value(dueTimeText),
          dueTime: Value(dueTime ?? startTime),
          priority: Value(priority),
          status: RecordStatus.confirmed.value,
          taskStatus: Value(TaskStatus.active.value),
          recurrenceRuleId: Value(recurrenceRuleId),
          recurrenceDate: Value(recurrenceDate),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    return (select(tasks)..where((task) => task.id.equals(taskId))).getSingle();
  }

  Future<RecurringTaskRule> createDailyRecurringTaskRule({
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    required int hour,
    required int minute,
    required DateTime now,
  }) async {
    final ruleId = const Uuid().v4();
    final day = DateTime(startDate.year, startDate.month, startDate.day);
    await into(recurringTaskRules).insert(
      RecurringTaskRulesCompanion.insert(
        id: ruleId,
        title: title,
        description: Value(description),
        frequency: const Value('daily'),
        startDate: day,
        endDate: Value(
          endDate == null
              ? null
              : DateTime(endDate.year, endDate.month, endDate.day),
        ),
        hour: hour,
        minute: minute,
        status: RecordStatus.confirmed.value,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await generateDailyRecurringTaskInstances(
      ruleId: ruleId,
      fromDay: now,
      days: 8,
      now: now,
    );
    return (select(
      recurringTaskRules,
    )..where((rule) => rule.id.equals(ruleId))).getSingle();
  }

  Future<int> generateDueRecurringTaskInstances({
    required DateTime now,
    int days = 8,
  }) async {
    final rules =
        await (select(recurringTaskRules)..where(
              (rule) =>
                  rule.status.equals(RecordStatus.confirmed.value) &
                  rule.frequency.equals('daily'),
            ))
            .get();
    var created = 0;
    for (final rule in rules) {
      created += await generateDailyRecurringTaskInstances(
        ruleId: rule.id,
        fromDay: now,
        days: days,
        now: now,
      );
    }
    return created;
  }

  Future<int> generateDailyRecurringTaskInstances({
    required String ruleId,
    required DateTime fromDay,
    required int days,
    required DateTime now,
  }) async {
    final rule = await (select(
      recurringTaskRules,
    )..where((row) => row.id.equals(ruleId))).getSingle();
    if (rule.status != RecordStatus.confirmed.value ||
        rule.frequency != 'daily') {
      return 0;
    }

    final skippedDates = _decodeDateKeys(rule.skippedDatesJson);
    var created = 0;
    final start = DateTime(fromDay.year, fromDay.month, fromDay.day);

    for (var index = 0; index < days; index += 1) {
      final day = start.add(Duration(days: index));
      if (day.isBefore(_dayStart(rule.startDate))) continue;
      if (rule.endDate != null && day.isAfter(_dayStart(rule.endDate!))) {
        continue;
      }
      final dateKey = _dateKey(day);
      if (skippedDates.contains(dateKey)) continue;

      final existing =
          await (select(tasks)..where(
                (task) =>
                    task.recurrenceRuleId.equals(rule.id) &
                    task.recurrenceDate.equals(day),
              ))
              .getSingleOrNull();
      if (existing != null) continue;

      final dueTime = DateTime(
        day.year,
        day.month,
        day.day,
        rule.hour,
        rule.minute,
      );
      await createManualTask(
        title: rule.title,
        description: rule.description,
        startTime: dueTime,
        endTime: dueTime.add(const Duration(minutes: 30)),
        dueTimeText: '每日 ${_two(rule.hour)}:${_two(rule.minute)}',
        dueTime: dueTime,
        recurrenceRuleId: rule.id,
        recurrenceDate: day,
        now: now,
      );
      created += 1;
    }
    return created;
  }

  Future<void> confirmExtractedItemAsProfileItem({
    required String profileItemId,
    required String extractedItemId,
    required DateTime now,
  }) async {
    final item = await (select(
      extractedItems,
    )..where((row) => row.id.equals(extractedItemId))).getSingle();

    await transaction(() async {
      await into(profileItems).insert(
        ProfileItemsCompanion.insert(
          id: profileItemId,
          sourceRawInputId: item.rawInputId,
          sourceExtractedItemId: item.id,
          content: item.content ?? item.title ?? item.sourceText,
          confidence: item.confidence,
          status: RecordStatus.confirmed.value,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await updateExtractedItemStatus(
        id: extractedItemId,
        status: RecordStatus.confirmed,
        updatedAt: now,
      );
    });
  }

  Future<void> markProfileItemDeleted({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(profileItems)..where((item) => item.id.equals(id))).write(
      ProfileItemsCompanion(
        status: Value(RecordStatus.deleted.value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> updateProfileItemContent({
    required String id,
    required String content,
    required DateTime updatedAt,
  }) {
    return (update(profileItems)..where((item) => item.id.equals(id))).write(
      ProfileItemsCompanion(
        content: Value(content),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markTaskDeleted({
    required String id,
    required DateTime updatedAt,
  }) async {
    final task = await (select(
      tasks,
    )..where((row) => row.id.equals(id))).getSingle();

    await transaction(() async {
      await (update(tasks)..where((row) => row.id.equals(id))).write(
        TasksCompanion(
          status: Value(RecordStatus.deleted.value),
          updatedAt: Value(updatedAt),
        ),
      );

      if (task.recurrenceRuleId != null && task.recurrenceDate != null) {
        await _rememberSkippedRecurringDate(
          ruleId: task.recurrenceRuleId!,
          day: task.recurrenceDate!,
          updatedAt: updatedAt,
        );
      }
    });
  }

  Future<Task?> getTaskBySourceExtractedItemId(String extractedItemId) {
    return (select(tasks)
          ..where((task) => task.sourceExtractedItemId.equals(extractedItemId)))
        .getSingleOrNull();
  }

  Future<Task?> getTaskById(String id) {
    return (select(
      tasks,
    )..where((task) => task.id.equals(id))).getSingleOrNull();
  }

  Future<void> markTaskCompleted({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        status: Value(RecordStatus.confirmed.value),
        taskStatus: Value(TaskStatus.completed.value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markTaskCancelled({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        status: Value(RecordStatus.confirmed.value),
        taskStatus: Value(TaskStatus.cancelled.value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markTaskActive({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        status: Value(RecordStatus.confirmed.value),
        taskStatus: Value(TaskStatus.active.value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markTaskDeletedBySourceExtractedItemId({
    required String extractedItemId,
    required DateTime updatedAt,
  }) {
    return (update(tasks)
          ..where((task) => task.sourceExtractedItemId.equals(extractedItemId)))
        .write(
          TasksCompanion(
            status: Value(RecordStatus.deleted.value),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<void> markShortTermStateDeleted({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(
      shortTermStates,
    )..where((state) => state.id.equals(id))).write(
      ShortTermStatesCompanion(
        status: Value(RecordStatus.deleted.value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markShortTermStateDeletedBySourceExtractedItemId({
    required String extractedItemId,
    required DateTime updatedAt,
  }) {
    return (update(shortTermStates)..where(
          (state) => state.sourceExtractedItemId.equals(extractedItemId),
        ))
        .write(
          ShortTermStatesCompanion(
            status: Value(RecordStatus.deleted.value),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<void> markLifeEventDeleted({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(lifeEvents)..where((event) => event.id.equals(id))).write(
      LifeEventsCompanion(
        status: Value(RecordStatus.deleted.value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markLifeEventDeletedBySourceExtractedItemId({
    required String extractedItemId,
    required DateTime updatedAt,
  }) {
    return (update(lifeEvents)..where(
          (event) => event.sourceExtractedItemId.equals(extractedItemId),
        ))
        .write(
          LifeEventsCompanion(
            status: Value(RecordStatus.deleted.value),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<void> updateTaskBySourceExtractedItemId({
    required String extractedItemId,
    required String title,
    String? description,
    String? dueTimeText,
    DateTime? dueTime,
    required DateTime updatedAt,
  }) {
    return (update(tasks)
          ..where((task) => task.sourceExtractedItemId.equals(extractedItemId)))
        .write(
          TasksCompanion(
            title: Value(title),
            description: Value(description),
            dueTimeText: Value(dueTimeText),
            dueTime: Value(dueTime),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<void> updateTaskById({
    required String id,
    Value<String> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<DateTime?> startTime = const Value.absent(),
    Value<DateTime?> endTime = const Value.absent(),
    Value<String?> dueTimeText = const Value.absent(),
    Value<DateTime?> dueTime = const Value.absent(),
    Value<String> status = const Value.absent(),
    required DateTime updatedAt,
  }) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        dueTimeText: dueTimeText,
        dueTime: dueTime,
        status: status,
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> updateShortTermStateBySourceExtractedItemId({
    required String extractedItemId,
    required String content,
    required DateTime validUntil,
    required DateTime updatedAt,
  }) {
    return (update(shortTermStates)..where(
          (state) => state.sourceExtractedItemId.equals(extractedItemId),
        ))
        .write(
          ShortTermStatesCompanion(
            content: Value(content),
            validUntil: Value(validUntil),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<void> updateLifeEventBySourceExtractedItemId({
    required String extractedItemId,
    required String content,
    required DateTime updatedAt,
  }) {
    return (update(lifeEvents)..where(
          (event) => event.sourceExtractedItemId.equals(extractedItemId),
        ))
        .write(
          LifeEventsCompanion(
            content: Value(content),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<List<ProfileItem>> getActiveProfileItems() {
    return (select(
      profileItems,
    )..where((item) => item.status.equals(RecordStatus.confirmed.value))).get();
  }

  Future<List<Task>> getActiveTasks() {
    return (select(tasks)..where(
          (task) =>
              task.status.equals(RecordStatus.confirmed.value) &
              task.taskStatus.equals(TaskStatus.active.value),
        ))
        .get();
  }

  Future<List<Task>> getVisibleTasks() {
    return (select(
      tasks,
    )..where((task) => task.status.equals(RecordStatus.confirmed.value))).get();
  }

  Future<List<Task>> getSuggestionTasks({required DateTime now}) {
    final nextSevenDaysEnd = now.add(const Duration(days: 7));

    return (select(tasks)
          ..where(
            (task) =>
                task.status.equals(RecordStatus.confirmed.value) &
                task.taskStatus.equals(TaskStatus.active.value) &
                (task.dueTime.isNull() |
                    task.dueTime.isSmallerOrEqualValue(nextSevenDaysEnd)),
          )
          ..orderBy([(task) => OrderingTerm(expression: task.dueTime)]))
        .get();
  }

  Future<List<LifeEvent>> getActiveLifeEvents() {
    return (select(lifeEvents)
          ..where((event) => event.status.equals(RecordStatus.confirmed.value)))
        .get();
  }

  Future<List<ShortTermState>> getActiveShortTermStates({
    required DateTime now,
  }) {
    return (select(shortTermStates)..where(
          (state) =>
              state.status.equals(RecordStatus.confirmed.value) &
              state.validUntil.isBiggerThanValue(now),
        ))
        .get();
  }

  Future<String?> getSourceTextByExtractedItemId(String extractedItemId) {
    final query = select(extractedItems)
      ..where((item) => item.id.equals(extractedItemId));
    return query.map((item) => item.sourceText).getSingleOrNull();
  }

  Future<Map<String, String>> getSourceTextsByExtractedItemIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    final rows = await (select(
      extractedItems,
    )..where((item) => item.id.isIn(ids))).get();
    return {for (final row in rows) row.id: row.sourceText};
  }

  Future<int> countPendingExtractedItemsByType(String type) async {
    final rows =
        await (select(extractedItems)..where(
              (item) => item.type.equals(type) & item.status.equals('pending'),
            ))
            .get();
    return rows.length;
  }

  Future<List<Task>> getTasksForRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(tasks)
          ..where(
            (task) =>
                task.status.equals(RecordStatus.confirmed.value) &
                ((task.startTime.isBiggerOrEqualValue(start) &
                        task.startTime.isSmallerThanValue(end)) |
                    (task.startTime.isNull() &
                        task.dueTime.isBiggerOrEqualValue(start) &
                        task.dueTime.isSmallerThanValue(end)) |
                    (task.dueTime.isNull() &
                        task.createdAt.isBiggerOrEqualValue(start) &
                        task.createdAt.isSmallerThanValue(end))),
          )
          ..orderBy([
            (task) => OrderingTerm(expression: task.startTime),
            (task) => OrderingTerm(expression: task.dueTime),
          ]))
        .get();
  }

  Future<List<ScheduleBlock>> getScheduleBlocksForRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(scheduleBlocks)
          ..where(
            (block) =>
                block.status.equals(RecordStatus.deleted.value).not() &
                block.startTime.isBiggerOrEqualValue(start) &
                block.startTime.isSmallerThanValue(end),
          )
          ..orderBy([(block) => OrderingTerm(expression: block.startTime)]))
        .get();
  }

  Future<List<SedentarySession>> getSedentarySessionsForRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(sedentarySessions)
          ..where(
            (session) =>
                session.status.equals(RecordStatus.deleted.value).not() &
                session.startedAt.isBiggerOrEqualValue(start) &
                session.startedAt.isSmallerThanValue(end),
          )
          ..orderBy([(session) => OrderingTerm(expression: session.startedAt)]))
        .get();
  }

  Future<SedentarySession?> getActiveSedentarySession() {
    return (select(sedentarySessions)
          ..where((session) => session.status.equals('active'))
          ..orderBy([(session) => OrderingTerm.desc(session.startedAt)]))
        .getSingleOrNull();
  }

  Future<SedentarySession> startSedentarySession({
    required DateTime startedAt,
    Duration reminderAfter = const Duration(hours: 1),
  }) async {
    final id = const Uuid().v4();
    final now = startedAt;
    await (update(
      sedentarySessions,
    )..where((session) => session.status.equals('active'))).write(
      SedentarySessionsCompanion(
        status: const Value('ended'),
        endedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await into(sedentarySessions).insert(
      SedentarySessionsCompanion.insert(
        id: id,
        startedAt: startedAt,
        reminderAt: startedAt.add(reminderAfter),
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (select(
      sedentarySessions,
    )..where((session) => session.id.equals(id))).getSingle();
  }

  Future<void> endSedentarySession({
    required String id,
    required DateTime endedAt,
  }) {
    return (update(
      sedentarySessions,
    )..where((session) => session.id.equals(id))).write(
      SedentarySessionsCompanion(
        status: const Value('ended'),
        endedAt: Value(endedAt),
        updatedAt: Value(endedAt),
      ),
    );
  }

  Future<void> updateTaskDueTimeOnly({
    required String id,
    required DateTime dueTime,
    required DateTime updatedAt,
  }) async {
    final task = await (select(
      tasks,
    )..where((row) => row.id.equals(id))).getSingle();
    final duration = task.endTime == null || task.startTime == null
        ? const Duration(hours: 1)
        : task.endTime!.difference(task.startTime!);
    await (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        startTime: Value(dueTime),
        endTime: Value(dueTime.add(duration)),
        dueTime: Value(dueTime),
        dueTimeText: Value(
          '${dueTime.year}-${_two(dueTime.month)}-${_two(dueTime.day)} '
          '${_two(dueTime.hour)}:${_two(dueTime.minute)}-'
          '${_two(dueTime.add(duration).hour)}:${_two(dueTime.add(duration).minute)}',
        ),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> updateScheduleBlockTimes({
    required String id,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime updatedAt,
  }) async {
    final block = await (select(
      scheduleBlocks,
    )..where((row) => row.id.equals(id))).getSingle();

    await transaction(() async {
      await (update(scheduleBlocks)..where((row) => row.id.equals(id))).write(
        ScheduleBlocksCompanion(
          startTime: Value(startTime),
          endTime: Value(endTime),
          status: Value(RecordStatus.edited.value),
          updatedAt: Value(updatedAt),
        ),
      );
      await (update(
        schedulePlans,
      )..where((plan) => plan.id.equals(block.planId))).write(
        SchedulePlansCompanion(
          status: Value(RecordStatus.edited.value),
          updatedAt: Value(updatedAt),
          userEditedAt: Value(updatedAt),
        ),
      );
    });
  }

  Future<List<ShortTermState>> getShortTermStatesForRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(shortTermStates)
          ..where(
            (state) =>
                state.status.equals(RecordStatus.confirmed.value) &
                state.createdAt.isBiggerOrEqualValue(start) &
                state.createdAt.isSmallerThanValue(end),
          )
          ..orderBy([(state) => OrderingTerm(expression: state.createdAt)]))
        .get();
  }

  Future<List<LifeEvent>> getLifeEventsForRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(lifeEvents)
          ..where(
            (event) =>
                event.status.equals(RecordStatus.confirmed.value) &
                event.createdAt.isBiggerOrEqualValue(start) &
                event.createdAt.isSmallerThanValue(end),
          )
          ..orderBy([(event) => OrderingTerm(expression: event.createdAt)]))
        .get();
  }

  Future<List<Summary>> getSummariesForRange({
    required DateTime start,
    required DateTime end,
    String summaryType = 'daily_summary',
  }) {
    return (select(summaries)
          ..where(
            (summary) =>
                summary.summaryType.equals(summaryType) &
                (summary.status.equals(RecordStatus.confirmed.value) |
                    summary.status.equals(RecordStatus.edited.value)) &
                summary.timeRangeStart.isBiggerOrEqualValue(start) &
                summary.timeRangeStart.isSmallerThanValue(end),
          )
          ..orderBy([(summary) => OrderingTerm.desc(summary.timeRangeStart)]))
        .get();
  }

  Future<Summary?> getSummaryForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(summaries)
          ..where(
            (summary) =>
                summary.summaryType.equals('daily_summary') &
                (summary.status.equals(RecordStatus.confirmed.value) |
                    summary.status.equals(RecordStatus.edited.value)) &
                summary.timeRangeStart.isBiggerOrEqualValue(start) &
                summary.timeRangeStart.isSmallerThanValue(end),
          )
          ..orderBy([(summary) => OrderingTerm.desc(summary.updatedAt)]))
        .getSingleOrNull();
  }

  Future<List<Summary>> getRecentDailySummaries({
    required DateTime now,
    int days = 7,
    int limit = 3,
  }) {
    final end = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final start = end.subtract(Duration(days: days));

    return (select(summaries)
          ..where(
            (summary) =>
                summary.summaryType.equals('daily_summary') &
                (summary.status.equals(RecordStatus.confirmed.value) |
                    summary.status.equals(RecordStatus.edited.value)) &
                summary.timeRangeStart.isBiggerOrEqualValue(start) &
                summary.timeRangeStart.isSmallerThanValue(end),
          )
          ..orderBy([(summary) => OrderingTerm.desc(summary.timeRangeStart)])
          ..limit(limit))
        .get();
  }

  Future<List<Summary>> getRecentDailySummariesBeforeOrOn({
    required DateTime day,
    int days = 7,
    int limit = 3,
  }) {
    final end = DateTime(
      day.year,
      day.month,
      day.day,
    ).add(const Duration(days: 1));
    final start = end.subtract(Duration(days: days));

    return (select(summaries)
          ..where(
            (summary) =>
                summary.summaryType.equals('daily_summary') &
                (summary.status.equals(RecordStatus.confirmed.value) |
                    summary.status.equals(RecordStatus.edited.value)) &
                summary.timeRangeStart.isBiggerOrEqualValue(start) &
                summary.timeRangeStart.isSmallerThanValue(end),
          )
          ..orderBy([(summary) => OrderingTerm.desc(summary.timeRangeStart)])
          ..limit(limit))
        .get();
  }

  Future<List<SummarySource>> getSourcesForSummary(String summaryId) {
    return (select(summarySources)
          ..where((source) => source.summaryId.equals(summaryId))
          ..orderBy([(source) => OrderingTerm(expression: source.createdAt)]))
        .get();
  }

  Future<void> saveDailySummary({
    required Summary summary,
    required List<SummarySourcesCompanion> sources,
    required DateTime updatedAt,
  }) async {
    await transaction(() async {
      await (update(summaries)..where(
            (row) =>
                row.summaryType.equals(summary.summaryType) &
                row.timeRangeStart.equals(summary.timeRangeStart) &
                row.id.equals(summary.id).not(),
          ))
          .write(
            SummariesCompanion(
              status: Value(RecordStatus.archived.value),
              updatedAt: Value(updatedAt),
            ),
          );

      await into(summaries).insertOnConflictUpdate(
        SummariesCompanion.insert(
          id: summary.id,
          summaryType: summary.summaryType,
          title: summary.title,
          content: summary.content,
          encouragement: Value(summary.encouragement),
          improvementNotes: Value(summary.improvementNotes),
          taskGuidance: Value(summary.taskGuidance),
          openItemsJson: Value(summary.openItemsJson),
          timeRangeStart: summary.timeRangeStart,
          timeRangeEnd: summary.timeRangeEnd,
          status: summary.status,
          generatedBy: summary.generatedBy,
          modelName: Value(summary.modelName),
          promptVersion: Value(summary.promptVersion),
          confidence: Value(summary.confidence),
          createdAt: summary.createdAt,
          updatedAt: summary.updatedAt,
          userEditedAt: Value(summary.userEditedAt),
          deletedAt: Value(summary.deletedAt),
        ),
      );

      await (delete(
        summarySources,
      )..where((source) => source.summaryId.equals(summary.id))).go();

      for (final source in sources) {
        await into(summarySources).insert(source);
      }
    });
  }

  Future<void> updateSummaryContent({
    required String id,
    required String content,
    String? encouragement,
    String? improvementNotes,
    String? taskGuidance,
    required DateTime updatedAt,
  }) {
    return (update(summaries)..where((summary) => summary.id.equals(id))).write(
      SummariesCompanion(
        content: Value(content),
        encouragement: Value(encouragement),
        improvementNotes: Value(improvementNotes),
        taskGuidance: Value(taskGuidance),
        status: Value(RecordStatus.edited.value),
        updatedAt: Value(updatedAt),
        userEditedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markSummaryDeleted({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(summaries)..where((summary) => summary.id.equals(id))).write(
      SummariesCompanion(
        status: Value(RecordStatus.deleted.value),
        updatedAt: Value(updatedAt),
        deletedAt: Value(updatedAt),
      ),
    );
  }

  Future<SchedulePlan?> getSchedulePlanForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(schedulePlans)
          ..where(
            (plan) =>
                (plan.status.equals(RecordStatus.pending.value) |
                    plan.status.equals(RecordStatus.confirmed.value) |
                    plan.status.equals(RecordStatus.edited.value)) &
                plan.planDate.isBiggerOrEqualValue(start) &
                plan.planDate.isSmallerThanValue(end),
          )
          ..orderBy([(plan) => OrderingTerm.desc(plan.updatedAt)]))
        .getSingleOrNull();
  }

  Future<List<SchedulePlan>> getSchedulePlansForRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(schedulePlans)
          ..where(
            (plan) =>
                (plan.status.equals(RecordStatus.pending.value) |
                    plan.status.equals(RecordStatus.confirmed.value) |
                    plan.status.equals(RecordStatus.edited.value)) &
                plan.planDate.isBiggerOrEqualValue(start) &
                plan.planDate.isSmallerThanValue(end),
          )
          ..orderBy([(plan) => OrderingTerm.desc(plan.planDate)]))
        .get();
  }

  Future<List<ScheduleBlock>> getScheduleBlocksForPlan(String planId) {
    return (select(scheduleBlocks)
          ..where(
            (block) =>
                block.planId.equals(planId) &
                block.status.equals(RecordStatus.deleted.value).not(),
          )
          ..orderBy([
            (block) => OrderingTerm(expression: block.sortOrder),
            (block) => OrderingTerm(expression: block.startTime),
          ]))
        .get();
  }

  Future<List<ScheduleBlockSource>> getSourcesForScheduleBlock(String blockId) {
    return (select(scheduleBlockSources)
          ..where((source) => source.blockId.equals(blockId))
          ..orderBy([(source) => OrderingTerm(expression: source.createdAt)]))
        .get();
  }

  Future<void> saveSchedulePlan({
    required SchedulePlan plan,
    required List<ScheduleBlocksCompanion> blocks,
    required Map<String, List<ScheduleBlockSourcesCompanion>> sourcesByBlockId,
    required DateTime updatedAt,
  }) async {
    await transaction(() async {
      await (update(schedulePlans)..where(
            (row) =>
                row.planDate.equals(plan.planDate) &
                row.id.equals(plan.id).not(),
          ))
          .write(
            SchedulePlansCompanion(
              status: Value(RecordStatus.archived.value),
              updatedAt: Value(updatedAt),
            ),
          );

      await into(schedulePlans).insertOnConflictUpdate(
        SchedulePlansCompanion.insert(
          id: plan.id,
          planDate: plan.planDate,
          title: plan.title,
          overview: plan.overview,
          suggestionsJson: Value(plan.suggestionsJson),
          unscheduledTaskIdsJson: Value(plan.unscheduledTaskIdsJson),
          status: plan.status,
          generatedBy: plan.generatedBy,
          modelName: Value(plan.modelName),
          promptVersion: Value(plan.promptVersion),
          confidence: Value(plan.confidence),
          createdAt: plan.createdAt,
          updatedAt: plan.updatedAt,
          confirmedAt: Value(plan.confirmedAt),
          userEditedAt: Value(plan.userEditedAt),
          deletedAt: Value(plan.deletedAt),
        ),
      );

      final existingBlocks = await getScheduleBlocksForPlan(plan.id);
      final existingBlockIds = existingBlocks.map((block) => block.id).toList();
      if (existingBlockIds.isNotEmpty) {
        await (delete(
          scheduleBlockSources,
        )..where((source) => source.blockId.isIn(existingBlockIds))).go();
      }
      await (delete(
        scheduleBlocks,
      )..where((block) => block.planId.equals(plan.id))).go();

      for (final block in blocks) {
        await into(scheduleBlocks).insert(block);
      }

      for (final sources in sourcesByBlockId.values) {
        for (final source in sources) {
          await into(scheduleBlockSources).insert(source);
        }
      }
    });
  }

  Future<void> updateScheduleBlock({
    required String id,
    required String title,
    required String blockType,
    required DateTime startTime,
    required DateTime endTime,
    String? note,
    required String reason,
    required DateTime updatedAt,
  }) async {
    final block = await (select(
      scheduleBlocks,
    )..where((row) => row.id.equals(id))).getSingle();

    await transaction(() async {
      await (update(scheduleBlocks)..where((row) => row.id.equals(id))).write(
        ScheduleBlocksCompanion(
          title: Value(title),
          blockType: Value(blockType),
          startTime: Value(startTime),
          endTime: Value(endTime),
          note: Value(note),
          reason: Value(reason),
          status: Value(RecordStatus.edited.value),
          updatedAt: Value(updatedAt),
        ),
      );
      await (update(
        schedulePlans,
      )..where((plan) => plan.id.equals(block.planId))).write(
        SchedulePlansCompanion(
          status: Value(RecordStatus.edited.value),
          updatedAt: Value(updatedAt),
          userEditedAt: Value(updatedAt),
        ),
      );
    });
  }

  Future<void> markScheduleBlockDeleted({
    required String id,
    required DateTime updatedAt,
  }) async {
    final block = await (select(
      scheduleBlocks,
    )..where((row) => row.id.equals(id))).getSingle();

    await transaction(() async {
      await (update(scheduleBlocks)..where((row) => row.id.equals(id))).write(
        ScheduleBlocksCompanion(
          status: Value(RecordStatus.deleted.value),
          updatedAt: Value(updatedAt),
        ),
      );
      await (update(
        schedulePlans,
      )..where((plan) => plan.id.equals(block.planId))).write(
        SchedulePlansCompanion(
          status: Value(RecordStatus.edited.value),
          updatedAt: Value(updatedAt),
          userEditedAt: Value(updatedAt),
        ),
      );
    });
  }

  Future<void> confirmSchedulePlan({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(schedulePlans)..where((plan) => plan.id.equals(id))).write(
      SchedulePlansCompanion(
        status: Value(RecordStatus.confirmed.value),
        updatedAt: Value(updatedAt),
        confirmedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markSchedulePlanDeleted({
    required String id,
    required DateTime updatedAt,
  }) {
    return (update(schedulePlans)..where((plan) => plan.id.equals(id))).write(
      SchedulePlansCompanion(
        status: Value(RecordStatus.deleted.value),
        updatedAt: Value(updatedAt),
        deletedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> _rememberSkippedRecurringDate({
    required String ruleId,
    required DateTime day,
    required DateTime updatedAt,
  }) async {
    final rule = await (select(
      recurringTaskRules,
    )..where((row) => row.id.equals(ruleId))).getSingleOrNull();
    if (rule == null) return;

    final skipped = _decodeDateKeys(rule.skippedDatesJson)..add(_dateKey(day));
    await (update(
      recurringTaskRules,
    )..where((row) => row.id.equals(ruleId))).write(
      RecurringTaskRulesCompanion(
        skippedDatesJson: Value(jsonEncode(skipped.toList()..sort())),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Set<String> _decodeDateKeys(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) return {};
    return decoded.whereType<String>().toSet();
  }

  DateTime _dayStart(DateTime day) => DateTime(day.year, day.month, day.day);

  String _dateKey(DateTime day) {
    return '${day.year}-${_two(day.month)}-${_two(day.day)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
