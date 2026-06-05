import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart' as db;
import 'package:mobile/data/parser/mock_parser_client.dart';
import 'package:mobile/data/parser/parser_client.dart';
import 'package:mobile/domain/extracted_item.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/domain/parse_result.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/features/extracted_items/extracted_item_card.dart';
import 'package:mobile/features/extracted_items/extracted_items_controller.dart';
import 'package:mobile/features/input/input_screen.dart';

void main() {
  testWidgets('profile candidate card shows confirmation warning', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ExtractedItemCard(
          item: _item(
            type: ItemType.profileCandidate,
            content: '用户不喜欢太频繁的提醒',
            sourceText: '我不喜欢太频繁的提醒',
          ),
        ),
      ),
    );

    expect(find.text('长期画像候选'), findsOneWidget);
    expect(find.text('确认后才会成为长期记忆'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);
  });

  testWidgets('short-term state card shows expiry', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ExtractedItemCard(
          item: _item(
            type: ItemType.shortTermState,
            content: '用户今天感觉疲惫',
            sourceText: '我今天很累',
            expiresAt: DateTime.utc(2026, 6, 1),
          ),
        ),
      ),
    );

    expect(find.text('短期状态'), findsOneWidget);
    expect(find.text('有效期至 2026-06-01'), findsOneWidget);
  });

  testWidgets('auto-saved card shows auto-save hint and undo action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ExtractedItemCard(
          item: _item(
            type: ItemType.taskCreate,
            title: '联系王总',
            sourceText: '明天上午联系王总',
            status: RecordStatus.confirmed,
          ),
        ),
      ),
    );

    expect(find.text('已自动整理，可修改或撤销'), findsOneWidget);
    expect(find.text('撤销'), findsOneWidget);
    expect(find.text('确认'), findsNothing);
  });

  testWidgets('input screen submits text and stores pending extracted items', (
    tester,
  ) async {
    final database = db.AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);

    final controller = ExtractedItemsController(
      database: database,
      parserClient: MockParserClient(
        parsedAtProvider: () => DateTime.utc(2026, 5, 31),
      ),
      rawInputIdFactory: () => 'raw-1',
      parseResultIdFactory: () => 'parse-1',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    await tester.pumpWidget(_wrap(InputScreen(controller: controller)));
    await tester.enterText(
      find.byType(TextField),
      '明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。',
    );
    await tester.tap(find.text('整理'));
    await tester.pumpAndSettle();

    expect(find.text('联系王总'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('确认后才会成为长期记忆'), findsOneWidget);

    final rawInputs = await database.select(database.rawInputs).get();
    final parseResults = await database.select(database.aiParseResults).get();
    final extractedItems = await database.select(database.extractedItems).get();
    final tasks = await database.select(database.tasks).get();

    expect(rawInputs.single.inputText, '明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');
    expect(parseResults.single.validationState, 'valid');
    expect(extractedItems, hasLength(3));
    expect(extractedItems.map((item) => item.status).toList(), [
      RecordStatus.confirmed.value,
      RecordStatus.confirmed.value,
      RecordStatus.pending.value,
    ]);
    expect(tasks, hasLength(1));
    expect(find.text('已自动整理，可修改或撤销'), findsNWidgets(2));
  });

  testWidgets('pure general answer shows assistant reply without save cards', (
    tester,
  ) async {
    final database = db.AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);

    final controller = ExtractedItemsController(
      database: database,
      parserClient: _StaticParserClient(
        ParseResult(
          userReply: 'Flutter 是一个跨平台 UI 开发框架，适合先做这类 MVP。',
          inputSummary: '用户在问 Flutter 是什么。',
          intentTypes: const [ItemType.generalAnswer],
          items: [
            ParsedExtractedItem(
              localId: 'parsed:0',
              type: ItemType.generalAnswer,
              content: 'Flutter 是一个跨平台 UI 开发框架。',
              sourceText: 'Flutter 是什么？',
              tags: const ['qa'],
              confidence: 0.98,
              needUserConfirm: false,
              parsedAt: DateTime.utc(2026, 5, 31),
            ),
          ],
        ),
      ),
      rawInputIdFactory: () => 'raw-general-1',
      parseResultIdFactory: () => 'parse-general-1',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    await tester.pumpWidget(_wrap(InputScreen(controller: controller)));
    await tester.enterText(find.byType(TextField), 'Flutter 是什么？');
    await tester.tap(find.text('整理'));
    await tester.pumpAndSettle();

    expect(
      find.text('Flutter 是一个跨平台 UI 开发框架，适合先做这类 MVP。'),
      findsOneWidget,
    );
    expect(find.text('待确认内容'), findsNothing);
    expect(find.text('普通问答'), findsNothing);
    expect(find.text('确认'), findsNothing);

    final extractedItems = await database.select(database.extractedItems).get();
    final tasks = await database.select(database.tasks).get();
    final states = await database.select(database.shortTermStates).get();
    final profiles = await database.select(database.profileItems).get();

    expect(extractedItems, isEmpty);
    expect(tasks, isEmpty);
    expect(states, isEmpty);
    expect(profiles, isEmpty);
  });

  testWidgets('mixed answer and memory result shows reply plus saveable cards', (
    tester,
  ) async {
    final database = db.AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);

    final controller = ExtractedItemsController(
      database: database,
      parserClient: _StaticParserClient(
        ParseResult(
          userReply: '我先回答你，也顺手帮你整理出一个任务。',
          inputSummary: '用户既在提问，也提到一个明天要做的动作。',
          intentTypes: const [ItemType.generalAnswer, ItemType.taskCreate],
          items: [
            ParsedExtractedItem(
              localId: 'parsed:0',
              type: ItemType.generalAnswer,
              content: '可以先做一个最小可运行版本。',
              sourceText: '我应该怎么开始做？',
              tags: const ['qa'],
              confidence: 0.95,
              needUserConfirm: false,
              parsedAt: DateTime.utc(2026, 5, 31),
            ),
            ParsedExtractedItem(
              localId: 'parsed:1',
              type: ItemType.taskCreate,
              title: '联系王总',
              sourceText: '明天上午联系王总',
              tags: const ['work'],
              confidence: 0.91,
              needUserConfirm: true,
              parsedAt: DateTime.utc(2026, 5, 31),
            ),
          ],
        ),
      ),
      rawInputIdFactory: () => 'raw-mixed-1',
      parseResultIdFactory: () => 'parse-mixed-1',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    await tester.pumpWidget(_wrap(InputScreen(controller: controller)));
    await tester.enterText(find.byType(TextField), '我应该怎么开始做？明天上午联系王总。');
    await tester.tap(find.text('整理'));
    await tester.pumpAndSettle();

    expect(find.text('我先回答你，也顺手帮你整理出一个任务。'), findsOneWidget);
    expect(find.text('待确认内容'), findsOneWidget);
    expect(find.text('联系王总'), findsOneWidget);
    expect(find.text('普通问答'), findsNothing);

    final extractedItems = await database.select(database.extractedItems).get();
    expect(extractedItems, hasLength(1));
    expect(extractedItems.single.type, ItemType.taskCreate.apiValue);
  });

  testWidgets('ambiguous task update lets user select which task to update', (
    tester,
  ) async {
    final database = db.AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    await _insertConfirmedTask(
      database,
      id: 'task-a',
      title: '联系王总-上海',
      dueTime: DateTime.utc(2026, 5, 31, 9),
    );
    await _insertConfirmedTask(
      database,
      id: 'task-b',
      title: '联系王总-北京',
      dueTime: DateTime.utc(2026, 5, 31, 10),
    );

    final controller = ExtractedItemsController(
      database: database,
      parserClient: _StaticParserClient(
        ParseResult(
          userReply: '我先整理出这条任务更新。',
          inputSummary: '用户提到把联系王总改到后天。',
          intentTypes: const [ItemType.taskUpdate],
          items: [
            ParsedExtractedItem(
              localId: 'parsed:0',
              type: ItemType.taskUpdate,
              title: '联系王总',
              sourceText: '把联系王总改到后天',
              tags: const ['task'],
              confidence: 0.91,
              needUserConfirm: true,
              parsedAt: DateTime.utc(2026, 5, 31),
              taskUpdateIntent: TaskUpdateIntent(
                action: TaskUpdateAction.delay,
                targetText: '联系王总',
                dueTimeText: '后天',
                dueTime: DateTime.utc(2026, 6, 2, 9),
              ),
            ),
          ],
        ),
      ),
      rawInputIdFactory: () => 'raw-task-update-ui',
      parseResultIdFactory: () => 'parse-task-update-ui',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    await tester.pumpWidget(_wrap(InputScreen(controller: controller)));
    await tester.enterText(find.byType(TextField), '把联系王总改到后天');
    await tester.tap(find.text('整理'));
    await tester.pumpAndSettle();

    expect(find.text('请选择要更新的任务'), findsOneWidget);
    expect(find.text('选择任务'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择任务'));
    await tester.pumpAndSettle();

    expect(find.text('联系王总-上海'), findsOneWidget);
    expect(find.text('联系王总-北京'), findsOneWidget);

    await tester.tap(find.text('联系王总-北京'));
    await tester.pumpAndSettle();

    final updatedTask = await _getTask(database, 'task-b');
    final untouchedTask = await _getTask(database, 'task-a');

    expect(updatedTask.dueTimeText, '后天');
    expect(updatedTask.dueTime!.toUtc(), DateTime.utc(2026, 6, 2, 9));
    expect(untouchedTask.dueTime!.toUtc(), DateTime.utc(2026, 5, 31, 9));
    expect(find.text('请选择要更新的任务'), findsNothing);
  });

  test(
    'controller records parser failures without creating extracted items',
    () async {
      final database = db.AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(database.close);

      final controller = ExtractedItemsController(
        database: database,
        parserClient: const _FailingParserClient(),
        rawInputIdFactory: () => 'raw-fail-1',
        parseResultIdFactory: () => 'parse-fail-1',
        nowProvider: () => DateTime.utc(2026, 5, 31),
      );

      await expectLater(
        controller.submitInput('明天联系王总'),
        throwsA(isA<ParserFailure>()),
      );

      final rawInputs = await database.select(database.rawInputs).get();
      final parseResults = await database.select(database.aiParseResults).get();
      final extractedItems = await database
          .select(database.extractedItems)
          .get();

      expect(rawInputs.single.inputText, '明天联系王总');
      expect(parseResults.single.validationState, 'error');
      expect(parseResults.single.errorMessage, 'network_error');
      expect(extractedItems, isEmpty);
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

class _FailingParserClient implements ParserClient {
  const _FailingParserClient();

  @override
  Future<ParseResult> parseInput(String text) async {
    throw const ParserFailure(
      code: 'network_error',
      userMessage: '暂时无法连接解析服务，请稍后再试。',
    );
  }
}

class _StaticParserClient implements ParserClient {
  const _StaticParserClient(this.result);

  final ParseResult result;

  @override
  Future<ParseResult> parseInput(String text) async {
    return result;
  }
}

Future<void> _insertConfirmedTask(
  db.AppDatabase database, {
  required String id,
  required String title,
  required DateTime dueTime,
}) async {
  await database.into(database.rawInputs).insert(
    db.RawInputsCompanion.insert(
      id: 'raw-$id',
      inputText: title,
      createdAt: DateTime.utc(2026, 5, 31),
    ),
  );
  await database.into(database.aiParseResults).insert(
    db.AiParseResultsCompanion.insert(
      id: 'parse-$id',
      rawInputId: 'raw-$id',
      rawJson: '{}',
      validationState: 'valid',
      createdAt: DateTime.utc(2026, 5, 31),
    ),
  );
  await database.into(database.extractedItems).insert(
    db.ExtractedItemsCompanion.insert(
      id: 'item-$id',
      rawInputId: 'raw-$id',
      aiParseResultId: 'parse-$id',
      type: ItemType.taskCreate.apiValue,
      title: Value(title),
      sourceText: title,
      confidence: 0.9,
      needUserConfirm: true,
      status: RecordStatus.confirmed.value,
      createdAt: DateTime.utc(2026, 5, 31),
      updatedAt: DateTime.utc(2026, 5, 31),
    ),
  );
  await database.into(database.tasks).insert(
    db.TasksCompanion.insert(
      id: id,
      sourceRawInputId: 'raw-$id',
      sourceExtractedItemId: 'item-$id',
      title: title,
      dueTimeText: const Value('今天'),
      dueTime: Value(dueTime),
      status: RecordStatus.confirmed.value,
      createdAt: DateTime.utc(2026, 5, 31),
      updatedAt: DateTime.utc(2026, 5, 31),
    ),
  );
}

Future<db.Task> _getTask(db.AppDatabase database, String id) {
  return (database.select(database.tasks)..where((task) => task.id.equals(id)))
      .getSingle();
}

ExtractedItem _item({
  required ItemType type,
  required String sourceText,
  String? title,
  String? content,
  RecordStatus status = RecordStatus.pending,
  DateTime? expiresAt,
}) {
  return ExtractedItem(
    localId: 'item-1',
    rawInputId: 'raw-1',
    type: type,
    title: title,
    content: content,
    sourceText: sourceText,
    tags: const ['test'],
    confidence: 0.86,
    needUserConfirm: true,
    status: status,
    createdAt: DateTime.utc(2026, 5, 31),
    updatedAt: DateTime.utc(2026, 5, 31),
    expiresAt: expiresAt,
  );
}
