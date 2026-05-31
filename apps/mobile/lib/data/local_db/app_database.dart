import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/record_status.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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

  Future<List<ProfileItem>> getActiveProfileItems() {
    return (select(
      profileItems,
    )..where((item) => item.status.equals(RecordStatus.confirmed.value))).get();
  }

  Future<List<Task>> getActiveTasks() {
    return (select(
      tasks,
    )..where((task) => task.status.equals(RecordStatus.confirmed.value))).get();
  }
}
