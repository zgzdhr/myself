import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mobile/app/app_shell.dart';
import 'package:mobile/data/local_db/app_database.dart' as db;
import 'package:mobile/data/parser/mock_parser_client.dart';
import 'package:mobile/data/parser/parser_client.dart';
import 'package:mobile/domain/parse_result.dart';
import 'package:mobile/features/home/home_screen.dart';
import 'package:mobile/features/reminders/task_reminder_scheduler.dart';

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
          taskReminderSchedulerProvider.overrideWithValue(
            const NoopTaskReminderScheduler(),
          ),
        ],
        child: const AppShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('早上好'), findsOneWidget);
    expect(find.text('今天想记点什么？'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('任务'), findsOneWidget);
    expect(find.text('复盘'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('最近状态'), findsNothing);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('AI 建议'), findsOneWidget);
    expect(find.text('今日行动'), findsOneWidget);
    expect(find.text('记忆入口'), findsOneWidget);
  });

  testWidgets('debug date switcher changes date-sensitive home context', (
    WidgetTester tester,
  ) async {
    final database = db.AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);

    final now = DateTime.now();
    await database
        .into(database.rawInputs)
        .insert(
          db.RawInputsCompanion.insert(
            id: 'raw-state',
            inputText: '我今天有点累',
            createdAt: now,
          ),
        );
    await database
        .into(database.aiParseResults)
        .insert(
          db.AiParseResultsCompanion.insert(
            id: 'parse-state',
            rawInputId: 'raw-state',
            rawJson: '{}',
            validationState: 'valid',
            createdAt: now,
          ),
        );
    await database
        .into(database.extractedItems)
        .insert(
          db.ExtractedItemsCompanion.insert(
            id: 'item-state',
            rawInputId: 'raw-state',
            aiParseResultId: 'parse-state',
            type: 'short_term_state',
            content: const Value('我今天有点累'),
            sourceText: '我今天有点累',
            confidence: 0.9,
            needUserConfirm: false,
            status: 'confirmed',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.shortTermStates)
        .insert(
          db.ShortTermStatesCompanion.insert(
            id: 'state-1',
            sourceRawInputId: 'raw-state',
            sourceExtractedItemId: 'item-state',
            content: '我今天有点累',
            validUntil: now.add(const Duration(hours: 12)),
            status: 'confirmed',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          parserClientProvider.overrideWithValue(const MockParserClient()),
          taskReminderSchedulerProvider.overrideWithValue(
            const NoopTaskReminderScheduler(),
          ),
        ],
        child: const AppShell(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试日期'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.text('状态 1 条 · 长期画像 0 条'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 520));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('后一天'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.text('状态 0 条 · 长期画像 0 条'), findsOneWidget);
  });

  testWidgets('organizing a timed task refreshes today actions immediately', (
    WidgetTester tester,
  ) async {
    final database = db.AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final now = DateTime(2026, 6, 24, 10);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appNowProvider.overrideWithValue(() => now),
          parserClientProvider.overrideWithValue(
            _MeetingParserClient(parsedAt: now),
          ),
          taskReminderSchedulerProvider.overrideWithValue(
            const NoopTaskReminderScheduler(),
          ),
        ],
        child: const AppShell(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '今天下午4点要和朋友见面');
    await tester.tap(find.text('整理'));
    await tester.pumpAndSettle();

    expect(find.text('已纳入行动：和朋友见面'), findsOneWidget);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, -2400),
      3000,
    );
    await tester.pumpAndSettle();
    expect(find.text('今日行动 · 1'), findsOneWidget);
    expect(find.textContaining('和朋友见面'), findsWidgets);
  });

  testWidgets('bottom navigation opens review and profile settings pages', (
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
          taskReminderSchedulerProvider.overrideWithValue(
            const NoopTaskReminderScheduler(),
          ),
        ],
        child: const AppShell(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    expect(find.textContaining('年'), findsWidgets);
    expect(find.text('第1周'), findsOneWidget);
    expect(find.byIcon(Icons.folder_rounded), findsWidgets);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('未配置云端'), findsOneWidget);
    expect(find.text('通知设置'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('复盘设置'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('复盘设置'));
    await tester.pumpAndSettle();
    expect(find.text('复盘结果参与首页建议'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('App 与帮助'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('App 与帮助'));
    await tester.pumpAndSettle();
    expect(find.text('API 连接状态'), findsOneWidget);
  });
}

class _MeetingParserClient implements ParserClient {
  const _MeetingParserClient({required this.parsedAt});

  final DateTime parsedAt;

  @override
  Future<ParseResult> parseInput(String text) async {
    return ParseResult.fromAiJson(
      parsedAt: parsedAt,
      json: {
        'user_reply': '已经整理成一个今天的任务。',
        'input_summary': '今天下午4点和朋友见面。',
        'intent_types': ['task_create'],
        'items': [
          {
            'type': 'task_create',
            'title': '和朋友见面',
            'source_text': text,
            'tags': ['social'],
            'confidence': 0.95,
            'need_user_confirm': false,
            'due_time_text': '今天下午4点',
            'due_time_iso': '2026-06-24T16:00:00+08:00',
          },
        ],
      },
    );
  }
}
