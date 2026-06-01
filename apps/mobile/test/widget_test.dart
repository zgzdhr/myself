import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mobile/app/app_shell.dart';
import 'package:mobile/data/local_db/app_database.dart' as db;
import 'package:mobile/data/parser/mock_parser_client.dart';
import 'package:mobile/features/home/home_screen.dart';

void main() {
  testWidgets('App shell shows warm private assistant home screen', (
    WidgetTester tester,
  ) async {
    final database = db.AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          parserClientProvider.overrideWithValue(const MockParserClient()),
        ],
        child: const AppShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('早上好'), findsOneWidget);
    expect(find.text('今天想记点什么？'), findsOneWidget);
    expect(find.text('AI 建议'), findsOneWidget);
    expect(find.text('今日行动'), findsOneWidget);
    expect(find.text('记忆入口'), findsOneWidget);
    expect(find.text('最近状态'), findsNothing);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
