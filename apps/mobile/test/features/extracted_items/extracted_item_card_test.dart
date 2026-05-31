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
        rawInputIdFactory: () => 'parser-raw-ignored',
        parsedAtProvider: () => DateTime.utc(2026, 5, 31),
      ),
      rawInputIdFactory: () => 'raw-1',
      parseResultIdFactory: () => 'parse-1',
      nowProvider: () => DateTime.utc(2026, 5, 31),
    );

    await tester.pumpWidget(_wrap(InputScreen(controller: controller)));
    await tester.enterText(find.byType(TextField), '明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');
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
    expect(
      extractedItems.map((item) => item.status).toSet(),
      {RecordStatus.pending.value},
    );
    expect(tasks, isEmpty);
  });

  test('controller records parser failures without creating extracted items', () async {
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
    final extractedItems = await database.select(database.extractedItems).get();

    expect(rawInputs.single.inputText, '明天联系王总');
    expect(parseResults.single.validationState, 'error');
    expect(parseResults.single.errorMessage, 'network_error');
    expect(extractedItems, isEmpty);
  });
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

ExtractedItem _item({
  required ItemType type,
  required String sourceText,
  String? title,
  String? content,
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
    status: RecordStatus.pending,
    createdAt: DateTime.utc(2026, 5, 31),
    updatedAt: DateTime.utc(2026, 5, 31),
    expiresAt: expiresAt,
  );
}
