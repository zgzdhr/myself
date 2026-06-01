import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/features/home/home_suggestion_service.dart';

void main() {
  late AppDatabase database;
  late HomeSuggestionService service;
  final now = DateTime.utc(2026, 5, 31, 10);

  setUp(() async {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    service = const HomeSuggestionService();
    await _insertSourceRows(database, now: now);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'loads only confirmed relevant tasks, active states, and confirmed profiles',
    () async {
      await _insertTask(
        database,
        id: 'task-overdue',
        title: '补交客户资料',
        status: RecordStatus.confirmed,
        dueTime: now.subtract(const Duration(hours: 2)),
      );
      await _insertTask(
        database,
        id: 'task-pending',
        title: '未确认任务',
        status: RecordStatus.pending,
        dueTime: now,
      );
      await _insertTask(
        database,
        id: 'task-no-time',
        title: '没有时间但已确认的任务',
        status: RecordStatus.confirmed,
        dueTime: null,
      );
      await _insertTask(
        database,
        id: 'task-upcoming-normal',
        title: '明天联系王总',
        status: RecordStatus.confirmed,
        dueTime: now.add(const Duration(days: 1)),
      );
      await _insertState(
        database,
        id: 'state-active',
        content: '用户今天感觉疲惫',
        status: RecordStatus.confirmed,
        validUntil: now.add(const Duration(days: 1)),
      );
      await _insertState(
        database,
        id: 'state-expired',
        content: '过期状态',
        status: RecordStatus.confirmed,
        validUntil: now.subtract(const Duration(minutes: 1)),
      );
      await _insertProfile(
        database,
        id: 'profile-active',
        content: '用户不喜欢太频繁的提醒',
        status: RecordStatus.confirmed,
      );
      await _insertProfile(
        database,
        id: 'profile-deleted',
        content: '已删除画像',
        status: RecordStatus.deleted,
      );

      final context = await service.loadContext(database: database, now: now);

      expect(context.tasks.map((task) => task.title), [
        '没有时间但已确认的任务',
        '补交客户资料',
        '明天联系王总',
      ]);
      expect(context.shortTermStates.map((state) => state.content), [
        '用户今天感觉疲惫',
      ]);
      expect(context.profileItems.map((profile) => profile.content), [
        '用户不喜欢太频繁的提醒',
      ]);
    },
  );

  test('prefers overdue task and adapts language for low energy state', () {
    final suggestions = service.buildSuggestions(
      HomeSuggestionContext(
        now: now,
        tasks: [
          HomeTask(
            id: 'future',
            title: '准备下周复盘',
            priority: 'high',
            dueTime: now.add(const Duration(days: 3)),
          ),
          HomeTask(
            id: 'overdue',
            title: '补交客户资料',
            priority: 'medium',
            dueTime: now.subtract(const Duration(hours: 2)),
          ),
        ],
        shortTermStates: [
          HomeShortTermState(
            id: 'state-1',
            content: '用户今天感觉疲惫',
            tags: const ['energy'],
            validUntil: now.add(const Duration(days: 1)),
          ),
        ],
        profileItems: const [],
      ),
    );

    expect(suggestions.first.text, contains('补交客户资料'));
    expect(suggestions.first.text, contains('低阻力'));
  });

  test('respects reminder preference and avoids pushy wording', () {
    final suggestions = service.buildSuggestions(
      HomeSuggestionContext(
        now: now,
        tasks: [
          HomeTask(
            id: 'today',
            title: '联系王总',
            priority: 'medium',
            dueTime: now.add(const Duration(hours: 1)),
          ),
        ],
        shortTermStates: const [],
        profileItems: const [
          HomeProfileItem(id: 'profile-1', content: '用户不喜欢太频繁的提醒'),
        ],
      ),
    );

    expect(suggestions.first.text, contains('可以考虑'));
    expect(suggestions.first.text, isNot(contains('必须')));
    expect(suggestions.first.text, isNot(contains('马上')));
  });
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
          inputText: '测试输入',
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
          title: const Value('测试条目'),
          sourceText: '测试输入',
          confidence: 0.9,
          needUserConfirm: true,
          status: RecordStatus.confirmed.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _insertTask(
  AppDatabase database, {
  required String id,
  required String title,
  required RecordStatus status,
  required DateTime? dueTime,
}) {
  return database
      .into(database.tasks)
      .insert(
        TasksCompanion.insert(
          id: id,
          sourceRawInputId: 'raw-1',
          sourceExtractedItemId: 'item-1',
          title: title,
          dueTime: Value(dueTime),
          priority: const Value('medium'),
          status: status.value,
          createdAt: dueTime ?? DateTime.utc(2026, 5, 31),
          updatedAt: dueTime ?? DateTime.utc(2026, 5, 31),
        ),
      );
}

Future<void> _insertState(
  AppDatabase database, {
  required String id,
  required String content,
  required RecordStatus status,
  required DateTime validUntil,
}) {
  return database
      .into(database.shortTermStates)
      .insert(
        ShortTermStatesCompanion.insert(
          id: id,
          sourceRawInputId: 'raw-1',
          sourceExtractedItemId: 'item-1',
          content: content,
          tagsJson: const Value('["energy"]'),
          validUntil: validUntil,
          status: status.value,
          createdAt: validUntil,
          updatedAt: validUntil,
        ),
      );
}

Future<void> _insertProfile(
  AppDatabase database, {
  required String id,
  required String content,
  required RecordStatus status,
}) {
  return database
      .into(database.profileItems)
      .insert(
        ProfileItemsCompanion.insert(
          id: id,
          sourceRawInputId: 'raw-1',
          sourceExtractedItemId: 'item-1',
          content: content,
          confidence: 0.9,
          status: status.value,
          createdAt: DateTime.utc(2026, 5, 31),
          updatedAt: DateTime.utc(2026, 5, 31),
        ),
      );
}
