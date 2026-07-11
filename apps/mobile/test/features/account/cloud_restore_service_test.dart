import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart';
import 'package:mobile/features/account/cloud_restore_service.dart';

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

  tearDown(() => database.close());

  test('restores a cloud backup in foreign-key order', () async {
    final result = await const CloudBackupImporter().restore(
      database: database,
      snapshot: _snapshot(
        taskTitle: '联系王总',
        taskUpdatedAt: '2026-07-10T08:00:00.000Z',
      ),
    );

    expect(result.preview.totalCount, 4);
    expect(result.restoredCount, 4);
    expect(result.preservedLocalCount, 0);

    final task = await database.getTaskById('task-1');
    expect(task?.title, '联系王总');
    expect(task?.dueTime?.toUtc(), DateTime.utc(2026, 7, 12, 2));
  });

  test('cloud updates never erase local-only calendar fields', () async {
    const importer = CloudBackupImporter();
    await importer.restore(
      database: database,
      snapshot: _snapshot(
        taskTitle: '云端旧标题',
        taskUpdatedAt: '2026-07-10T08:00:00.000Z',
      ),
    );

    final localStart = DateTime(2026, 7, 12, 9);
    final localEnd = DateTime(2026, 7, 12, 10);
    await (database.update(
      database.tasks,
    )..where((row) => row.id.equals('task-1'))).write(
      TasksCompanion(
        title: const Value('本机旧标题'),
        startTime: Value(localStart),
        endTime: Value(localEnd),
        recurrenceRuleId: const Value('local-rule'),
        recurrenceDate: Value(DateTime(2026, 7, 12)),
        updatedAt: Value(DateTime.utc(2026, 7, 10, 9)),
      ),
    );

    final result = await importer.restore(
      database: database,
      snapshot: _snapshot(
        taskTitle: '云端新标题',
        taskUpdatedAt: '2026-07-11T08:00:00.000Z',
      ),
    );

    final task = await database.getTaskById('task-1');
    expect(result.restoredCount, 1);
    expect(task?.title, '云端新标题');
    expect(task?.startTime, localStart);
    expect(task?.endTime, localEnd);
    expect(task?.recurrenceRuleId, 'local-rule');
    expect(task?.recurrenceDate, DateTime(2026, 7, 12));
  });

  test('preserves a newer local record instead of overwriting it', () async {
    const importer = CloudBackupImporter();
    await importer.restore(
      database: database,
      snapshot: _snapshot(
        taskTitle: '云端初始标题',
        taskUpdatedAt: '2026-07-10T08:00:00.000Z',
      ),
    );

    await (database.update(
      database.tasks,
    )..where((row) => row.id.equals('task-1'))).write(
      TasksCompanion(
        title: const Value('本机较新标题'),
        updatedAt: Value(DateTime.utc(2026, 7, 12, 8)),
      ),
    );

    final result = await importer.restore(
      database: database,
      snapshot: _snapshot(
        taskTitle: '云端较旧标题',
        taskUpdatedAt: '2026-07-11T08:00:00.000Z',
      ),
    );

    final task = await database.getTaskById('task-1');
    expect(result.restoredCount, 0);
    expect(result.preservedLocalCount, 4);
    expect(task?.title, '本机较新标题');
  });

  test('rejects an inconsistent backup before writing anything', () async {
    final snapshot = _snapshot(
      taskTitle: '联系王总',
      taskUpdatedAt: '2026-07-10T08:00:00.000Z',
    );
    final invalid = CloudBackupSnapshot(
      rawInputs: snapshot.rawInputs,
      aiParseResults: snapshot.aiParseResults,
      extractedItems: snapshot.extractedItems,
      tasks: [
        {...snapshot.tasks.single, 'source_raw_input_id': 'missing-raw'},
      ],
    );

    await expectLater(
      const CloudBackupImporter().restore(
        database: database,
        snapshot: invalid,
      ),
      throwsA(isA<CloudBackupImportException>()),
    );
    expect(await database.getVisibleTasks(), isEmpty);
  });
}

CloudBackupSnapshot _snapshot({
  required String taskTitle,
  required String taskUpdatedAt,
}) {
  return CloudBackupSnapshot(
    rawInputs: const [
      {
        'id': 'raw-1',
        'text': '后天上午联系王总',
        'source': 'user',
        'created_at': '2026-07-10T07:59:00.000Z',
      },
    ],
    aiParseResults: const [
      {
        'id': 'parse-1',
        'raw_input_id': 'raw-1',
        'raw_json': {'items': []},
        'validation_state': 'valid',
        'error_message': null,
        'retry_count': 0,
        'created_at': '2026-07-10T08:00:00.000Z',
      },
    ],
    extractedItems: const [
      {
        'id': 'item-1',
        'raw_input_id': 'raw-1',
        'ai_parse_result_id': 'parse-1',
        'type': 'task_create',
        'title': '联系王总',
        'content': null,
        'source_text': '后天上午联系王总',
        'tags': ['work'],
        'confidence': 0.9,
        'need_user_confirm': false,
        'status': 'confirmed',
        'expires_at': null,
        'created_at': '2026-07-10T08:00:00.000Z',
        'updated_at': '2026-07-10T08:00:00.000Z',
      },
    ],
    tasks: [
      {
        'id': 'task-1',
        'source_raw_input_id': 'raw-1',
        'source_extracted_item_id': 'item-1',
        'title': taskTitle,
        'description': null,
        'due_time_text': '后天上午',
        'due_time': '2026-07-12T02:00:00.000Z',
        'priority': 'medium',
        'status': 'confirmed',
        'task_status': 'active',
        'created_at': '2026-07-10T08:00:00.000Z',
        'updated_at': taskUpdatedAt,
      },
    ],
  );
}
