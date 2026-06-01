import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart';
import 'package:mobile/data/parser/mock_parser_client.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/features/extracted_items/extracted_items_controller.dart';

void main() {
  late AppDatabase database;
  late ExtractedItemsController controller;

  setUp(() async {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    controller = ExtractedItemsController(
      database: database,
      parserClient: MockParserClient(
        rawInputIdFactory: () => 'parser-raw-ignored',
        parsedAtProvider: () => DateTime.utc(2026, 5, 31),
      ),
      rawInputIdFactory: () => 'raw-1',
      parseResultIdFactory: () => 'parse-1',
      officialRecordIdFactory: () => 'official-1',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    await controller.submitInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'confirms task item into tasks and marks extracted item confirmed',
    () async {
      await controller.confirmExtractedItem(extractedItemId: 'raw-1:0');

      final task = await database.select(database.tasks).getSingle();
      final extractedItem = await _getExtractedItem(database, 'raw-1:0');

      expect(task.title, '联系王总');
      expect(task.dueTimeText, '明天上午');
      expect(task.dueTime, DateTime(2026, 6, 1, 9));
      expect(task.status, RecordStatus.confirmed.value);
      expect(extractedItem.status, RecordStatus.confirmed.value);
    },
  );

  test('confirms short-term state with expiry into active states', () async {
    await controller.confirmExtractedItem(extractedItemId: 'raw-1:1');

    final activeStates = await database.getActiveShortTermStates(
      now: DateTime.utc(2026, 5, 31, 12),
    );
    final extractedItem = await _getExtractedItem(database, 'raw-1:1');

    expect(activeStates.single.content, '用户今天感觉疲惫');
    expect(activeStates.single.validUntil.toUtc(), DateTime.utc(2026, 6, 1));
    expect(extractedItem.status, RecordStatus.confirmed.value);
  });

  test(
    'profile candidate only becomes profile item after confirmation',
    () async {
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
      await controller.confirmExtractedItem(
        extractedItemId: 'raw-1:0',
        editedTitle: '给王总发微信',
        editedContent: '先发微信确认明天上午沟通时间',
      );

      final task = await database.select(database.tasks).getSingle();
      final extractedItem = await _getExtractedItem(database, 'raw-1:0');

      expect(task.title, '给王总发微信');
      expect(task.description, '先发微信确认明天上午沟通时间');
      expect(extractedItem.title, '给王总发微信');
      expect(extractedItem.content, '先发微信确认明天上午沟通时间');
      expect(extractedItem.status, RecordStatus.edited.value);
    },
  );

  test('rejects item without creating an official record', () async {
    await controller.rejectExtractedItem(extractedItemId: 'raw-1:2');

    final extractedItem = await _getExtractedItem(database, 'raw-1:2');

    expect(extractedItem.status, RecordStatus.rejected.value);
    expect(await database.getActiveProfileItems(), isEmpty);
  });
}

Future<ExtractedItem> _getExtractedItem(AppDatabase database, String id) {
  return (database.select(
    database.extractedItems,
  )..where((item) => item.id.equals(id))).getSingle();
}
