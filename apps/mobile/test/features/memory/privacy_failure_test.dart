import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart';
import 'package:mobile/data/parser/parser_client.dart';
import 'package:mobile/domain/parse_result.dart';
import 'package:mobile/features/extracted_items/extracted_items_controller.dart';
import 'package:mobile/features/input/input_screen.dart';
import 'package:mobile/features/memory/privacy_screen.dart';

void main() {
  testWidgets('privacy screen explains the MVP privacy boundaries', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));

    expect(find.text('隐私说明'), findsOneWidget);
    expect(find.textContaining('本地优先'), findsOneWidget);
    expect(find.textContaining('当前输入'), findsWidgets);
    expect(find.textContaining('API proxy'), findsOneWidget);
    expect(find.textContaining('可以删除'), findsOneWidget);
    expect(find.textContaining('长期画像'), findsWidgets);
    expect(find.textContaining('确认后'), findsWidgets);
  });

  testWidgets('input screen shows stable parser failure message', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = ExtractedItemsController(
      database: database,
      parserClient: const _FailingParserClient(),
      rawInputIdFactory: () => 'raw-privacy-1',
      parseResultIdFactory: () => 'parse-privacy-1',
      nowProvider: () => DateTime.utc(2026, 6, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: InputScreen(controller: controller)),
      ),
    );
    await tester.enterText(find.byType(TextField), '明天联系王总');
    await tester.tap(find.text('整理'));
    await tester.pumpAndSettle();

    expect(find.text('这次我没能稳定解析成可保存的数据。你可以重试，或者先手动记录。'), findsOneWidget);
  });

  testWidgets('input screen rejects input that is too long', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = ExtractedItemsController(
      database: database,
      parserClient: const _FailingParserClient(),
      rawInputIdFactory: () => 'raw-length-1',
      parseResultIdFactory: () => 'parse-length-1',
      nowProvider: () => DateTime.utc(2026, 6, 1),
    );
    final longText = '测试' * 1001; // 2002 chars

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: InputScreen(controller: controller)),
      ),
    );
    await tester.enterText(find.byType(TextField), longText);
    await tester.tap(find.text('整理'));
    await tester.pumpAndSettle();

    // The error message should be user-friendly and not expose raw text
    expect(
      find.textContaining('输入内容过长'),
      findsOneWidget,
    );
  });
}

class _FailingParserClient implements ParserClient {
  const _FailingParserClient();

  @override
  Future<ParseResult> parseInput(String text) async {
    throw const ParserFailure(
      code: 'network_error',
      userMessage: 'raw socket failure should not be shown',
    );
  }
}
