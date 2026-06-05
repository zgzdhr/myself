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
      final parseResult = await database.select(database.aiParseResults).getSingle();
      final extractedItems = await database.select(database.extractedItems).get();

      expect(result.rawInputId, 'raw-1');
      expect(rawInput.id, 'raw-1');
      expect(parseResult.rawInputId, rawInput.id);
      expect(
        extractedItems.map((item) => item.rawInputId).toSet(),
        {rawInput.id},
      );
      expect(
        extractedItems.map((item) => item.id),
        ['raw-1:0', 'raw-1:1', 'raw-1:2'],
      );
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

class _StaticParserClient implements ParserClient {
  const _StaticParserClient(this.result);

  final ParseResult result;

  @override
  Future<ParseResult> parseInput(String text) async {
    return result;
  }
}
