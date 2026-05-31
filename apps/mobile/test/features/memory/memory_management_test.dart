import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/features/home/home_suggestion_service.dart';
import 'package:mobile/features/memory/memory_screen.dart';
import 'package:mobile/features/memory/profile_items_screen.dart';

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

  testWidgets('memory overview shows remembered categories', (tester) async {
    await tester.pumpWidget(_wrap(MemoryScreen(database: database)));
    await tester.pumpAndSettle();

    expect(find.text('记忆管理'), findsOneWidget);
    expect(find.text('任务'), findsOneWidget);
    expect(find.text('短期状态'), findsOneWidget);
    expect(find.text('生活事件'), findsOneWidget);
    expect(find.text('长期画像'), findsOneWidget);
    expect(find.text('联系王总'), findsOneWidget);
    expect(find.text('用户今天感觉疲惫'), findsOneWidget);
    expect(find.text('用户不喜欢太频繁的提醒'), findsOneWidget);
  });

  test(
    'delete sets status to deleted and removes item from suggestions',
    () async {
      final suggestionService = const HomeSuggestionService();
      expect(
        (await suggestionService.loadContext(
          database: database,
          now: now,
        )).profileItems,
        hasLength(1),
      );

      await database.markProfileItemDeleted(
        id: 'profile-1',
        updatedAt: now.add(const Duration(minutes: 1)),
      );

      final profile = await database.select(database.profileItems).getSingle();
      final context = await suggestionService.loadContext(
        database: database,
        now: now,
      );

      expect(profile.status, RecordStatus.deleted.value);
      expect(context.profileItems, isEmpty);
    },
  );

  testWidgets('profile item edit action updates wording and updated time', (
    tester,
  ) async {
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
    await tester.enterText(find.byType(TextField), '用户希望提醒少一点，语气直接一点');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final profile = await database.select(database.profileItems).getSingle();

    expect(profile.content, '用户希望提醒少一点，语气直接一点');
    expect(profile.sourceRawInputId, 'raw-1');
    expect(profile.updatedAt.toUtc(), now.add(const Duration(hours: 1)));
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
