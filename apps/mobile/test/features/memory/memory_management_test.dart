import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/features/home/home_suggestion_service.dart';
import 'package:mobile/features/memory/life_events_screen.dart';
import 'package:mobile/features/memory/memory_screen.dart';
import 'package:mobile/features/memory/profile_items_screen.dart';
import 'package:mobile/features/memory/short_term_states_screen.dart';
import 'package:mobile/features/memory/tasks_screen.dart';

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 5, 31, 10);

  setUp(() async {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await _insertSourceRows(database, now: now);
    await _insertTask(database, now: now);
    await _insertShortTermState(database, now: now);
    await _insertLifeEvent(database, now: now);
    await _insertProfile(database, now: now);
  });

  tearDown(() async {
    await database.close();
  });

  group('MemoryScreen overview', () {
    testWidgets('shows remembered categories with counts and update time', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(MemoryScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      expect(find.text('记忆管理'), findsOneWidget);
      expect(find.text('任务'), findsOneWidget);
      expect(find.text('短期状态'), findsOneWidget);
      expect(find.text('生活事件'), findsOneWidget);
      expect(find.textContaining('最近更新'), findsWidgets);

      expect(find.text('1'), findsWidgets);
      expect(find.text('管理'), findsWidgets);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('长期画像'), findsOneWidget);
    });

    testWidgets('shows pending counts when extracted items are pending', (
      tester,
    ) async {
      await database
          .into(database.extractedItems)
          .insert(
            ExtractedItemsCompanion.insert(
              id: 'pending-profile',
              rawInputId: 'raw-1',
              aiParseResultId: 'parse-1',
              type: 'profile_candidate',
              sourceText: '我不喜欢提醒',
              confidence: 0.8,
              needUserConfirm: true,
              status: 'pending',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        _wrap(MemoryScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('待确认 1'), findsOneWidget);
    });

    testWidgets('shows task items with title in overview', (tester) async {
      await tester.pumpWidget(
        _wrap(MemoryScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      expect(find.text('联系王总'), findsOneWidget);
    });

    testWidgets('navigates to tasks detail screen', (tester) async {
      await tester.pumpWidget(
        _wrap(MemoryScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('管理').first);
      await tester.pumpAndSettle();

      expect(find.text('任务'), findsOneWidget);
    });
  });

  group('TasksScreen', () {
    testWidgets('shows active tasks with source text', (tester) async {
      await tester.pumpWidget(
        _wrap(TasksScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      expect(find.text('联系王总'), findsOneWidget);
      expect(find.text('6月1日 10:00｜原文：明天'), findsOneWidget);
      expect(find.textContaining('明天联系王总'), findsOneWidget);
    });

    testWidgets('delete task requires confirmation before marking deleted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(TasksScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(find.text('删除任务？'), findsOneWidget);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      var task = await database.select(database.tasks).getSingle();
      expect(task.status, RecordStatus.confirmed.value);

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();

      task = await database.select(database.tasks).getSingle();
      expect(task.status, RecordStatus.deleted.value);
    });

    testWidgets('edit task updates title and due time', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TasksScreen(
            database: database,
            nowProvider: () => now.add(const Duration(hours: 1)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();

      expect(find.text('选择日期'), findsOneWidget);
      expect(find.text('选择时间'), findsOneWidget);
      expect(find.text('清除时间'), findsOneWidget);

      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, '联系李总');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final task = await database.select(database.tasks).getSingle();
      expect(task.title, '联系李总');
      expect(task.dueTimeText, '明天');
      expect(task.dueTime, isNot(isNull));
    });

    testWidgets('edit task can clear due time', (tester) async {
      await tester.pumpWidget(
        _wrap(TasksScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('清除时间'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final task = await database.select(database.tasks).getSingle();
      expect(task.dueTimeText, isNull);
      expect(task.dueTime, isNull);
    });

    testWidgets('empty state shows no tasks message', (tester) async {
      await database.markTaskDeleted(id: 'task-1', updatedAt: now);

      await tester.pumpWidget(
        _wrap(TasksScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无任务'), findsOneWidget);
    });
  });

  group('LifeEventsScreen', () {
    testWidgets('shows life events with source text', (tester) async {
      await tester.pumpWidget(
        _wrap(LifeEventsScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      expect(find.text('今天和客户沟通不太顺利'), findsOneWidget);
    });

    testWidgets(
      'delete life event requires confirmation before marking deleted',
      (tester) async {
        await tester.pumpWidget(
          _wrap(LifeEventsScreen(database: database, nowProvider: () => now)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();
        expect(find.text('删除生活事件？'), findsOneWidget);

        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        var event = await database.select(database.lifeEvents).getSingle();
        expect(event.status, RecordStatus.confirmed.value);

        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('确认删除'));
        await tester.pumpAndSettle();

        event = await database.select(database.lifeEvents).getSingle();
        expect(event.status, RecordStatus.deleted.value);
      },
    );
  });

  group('ShortTermStatesScreen', () {
    testWidgets('shows short term states with valid until', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ShortTermStatesScreen(database: database, nowProvider: () => now),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('用户今天感觉疲惫'), findsOneWidget);
      expect(find.textContaining('有效期至'), findsOneWidget);
    });

    testWidgets(
      'delete short term state requires confirmation before marking deleted',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ShortTermStatesScreen(database: database, nowProvider: () => now),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();
        expect(find.text('删除短期状态？'), findsOneWidget);

        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        var state = await database.select(database.shortTermStates).getSingle();
        expect(state.status, RecordStatus.confirmed.value);

        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('确认删除'));
        await tester.pumpAndSettle();

        state = await database.select(database.shortTermStates).getSingle();
        expect(state.status, RecordStatus.deleted.value);
      },
    );
  });

  group('ProfileItemsScreen', () {
    testWidgets('shows profile items with source text', (tester) async {
      await tester.pumpWidget(
        _wrap(ProfileItemsScreen(database: database, nowProvider: () => now)),
      );
      await tester.pumpAndSettle();

      expect(find.text('用户不喜欢太频繁的提醒'), findsOneWidget);
    });

    testWidgets('edit action updates content', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileItemsScreen(
            database: database,
            nowProvider: () => now.add(const Duration(hours: 1)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '用户希望提醒少一点');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final profile = await database.select(database.profileItems).getSingle();
      expect(profile.content, '用户希望提醒少一点');
    });

    testWidgets(
      'delete profile item requires confirmation before marking deleted',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ProfileItemsScreen(database: database, nowProvider: () => now)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();
        expect(find.text('删除长期画像？'), findsOneWidget);

        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        var profile = await database.select(database.profileItems).getSingle();
        expect(profile.status, RecordStatus.confirmed.value);

        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('确认删除'));
        await tester.pumpAndSettle();

        profile = await database.select(database.profileItems).getSingle();
        expect(profile.status, RecordStatus.deleted.value);
      },
    );
  });

  group('suggestion exclusion', () {
    test('deleted task does not appear in suggestions', () async {
      final suggestionService = const HomeSuggestionService();
      final before = await suggestionService.loadContext(
        database: database,
        now: now,
      );
      expect(before.tasks, hasLength(1));

      await database.markTaskDeleted(id: 'task-1', updatedAt: now);

      final after = await suggestionService.loadContext(
        database: database,
        now: now,
      );
      expect(after.tasks, isEmpty);
    });

    test('deleted profile item does not appear in suggestions', () async {
      final suggestionService = const HomeSuggestionService();
      final before = await suggestionService.loadContext(
        database: database,
        now: now,
      );
      expect(before.profileItems, hasLength(1));

      await database.markProfileItemDeleted(id: 'profile-1', updatedAt: now);

      final after = await suggestionService.loadContext(
        database: database,
        now: now,
      );
      expect(after.profileItems, isEmpty);
    });

    test('deleted short term state does not appear in suggestions', () async {
      final suggestionService = const HomeSuggestionService();

      await database.markShortTermStateDeleted(id: 'state-1', updatedAt: now);

      final context = await suggestionService.loadContext(
        database: database,
        now: now,
      );
      expect(context.shortTermStates, isEmpty);
    });

    test('deleted life event does not appear in active query', () async {
      await database.markLifeEventDeleted(id: 'life-1', updatedAt: now);

      final events = await database.getActiveLifeEvents();
      expect(events, isEmpty);
    });
  });

  group('source text lookup', () {
    test('getSourceTextByExtractedItemId returns source text', () async {
      final text = await database.getSourceTextByExtractedItemId('item-1');
      expect(text, '明天联系王总');
    });

    test(
      'getSourceTextByExtractedItemId returns null for missing id',
      () async {
        final text = await database.getSourceTextByExtractedItemId('missing');
        expect(text, isNull);
      },
    );

    test('getSourceTextsByExtractedItemIds returns map', () async {
      final map = await database.getSourceTextsByExtractedItemIds(['item-1']);
      expect(map['item-1'], '明天联系王总');
    });

    test('getSourceTextsByExtractedItemIds handles empty list', () async {
      final map = await database.getSourceTextsByExtractedItemIds([]);
      expect(map, isEmpty);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

Future<void> _insertSourceRows(
  AppDatabase database, {
  required DateTime now,
}) async {
  await database
      .into(database.rawInputs)
      .insert(
        RawInputsCompanion.insert(
          id: 'raw-1',
          inputText: '明天联系王总，我今天很累，我不喜欢太频繁的提醒',
          createdAt: now,
        ),
      );
  await database
      .into(database.aiParseResults)
      .insert(
        AiParseResultsCompanion.insert(
          id: 'parse-1',
          rawInputId: 'raw-1',
          rawJson: '{}',
          validationState: 'valid',
          createdAt: now,
        ),
      );
  await database
      .into(database.extractedItems)
      .insert(
        ExtractedItemsCompanion.insert(
          id: 'item-1',
          rawInputId: 'raw-1',
          aiParseResultId: 'parse-1',
          type: ItemType.taskCreate.apiValue,
          title: const Value('联系王总'),
          sourceText: '明天联系王总',
          confidence: 0.9,
          needUserConfirm: true,
          status: RecordStatus.confirmed.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _insertTask(AppDatabase database, {required DateTime now}) {
  return database
      .into(database.tasks)
      .insert(
        TasksCompanion.insert(
          id: 'task-1',
          sourceRawInputId: 'raw-1',
          sourceExtractedItemId: 'item-1',
          title: '联系王总',
          dueTimeText: const Value('明天'),
          dueTime: Value(DateTime(2026, 6, 1, 10)),
          status: RecordStatus.confirmed.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _insertShortTermState(
  AppDatabase database, {
  required DateTime now,
}) {
  return database
      .into(database.shortTermStates)
      .insert(
        ShortTermStatesCompanion.insert(
          id: 'state-1',
          sourceRawInputId: 'raw-1',
          sourceExtractedItemId: 'item-1',
          content: '用户今天感觉疲惫',
          validUntil: now.add(const Duration(days: 1)),
          status: RecordStatus.confirmed.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _insertLifeEvent(AppDatabase database, {required DateTime now}) {
  return database
      .into(database.lifeEvents)
      .insert(
        LifeEventsCompanion.insert(
          id: 'life-1',
          sourceRawInputId: 'raw-1',
          sourceExtractedItemId: 'item-1',
          content: '今天和客户沟通不太顺利',
          status: RecordStatus.confirmed.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _insertProfile(AppDatabase database, {required DateTime now}) {
  return database
      .into(database.profileItems)
      .insert(
        ProfileItemsCompanion.insert(
          id: 'profile-1',
          sourceRawInputId: 'raw-1',
          sourceExtractedItemId: 'item-1',
          content: '用户不喜欢太频繁的提醒',
          confidence: 0.86,
          status: RecordStatus.confirmed.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}
