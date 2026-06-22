import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/record_status.dart';
import '../../domain/task_status.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

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
      },
    );
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      final file = File(path.join(directory.path, 'personal_memory.sqlite'));
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
  }) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        status: Value(RecordStatus.deleted.value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<Task?> getTaskBySourceExtractedItemId(String extractedItemId) {
    return (select(tasks)
          ..where((task) => task.sourceExtractedItemId.equals(extractedItemId)))
        .getSingleOrNull();
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
    String? title,
    String? description,
    String? dueTimeText,
    DateTime? dueTime,
    String? status,
    required DateTime updatedAt,
  }) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        title: title == null ? const Value.absent() : Value(title),
        description: Value(description),
        dueTimeText: Value(dueTimeText),
        dueTime: Value(dueTime),
        status: status == null ? const Value.absent() : Value(status),
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
                ((task.dueTime.isBiggerOrEqualValue(start) &
                        task.dueTime.isSmallerThanValue(end)) |
                    (task.dueTime.isNull() &
                        task.createdAt.isBiggerOrEqualValue(start) &
                        task.createdAt.isSmallerThanValue(end))),
          )
          ..orderBy([(task) => OrderingTerm(expression: task.dueTime)]))
        .get();
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
}
