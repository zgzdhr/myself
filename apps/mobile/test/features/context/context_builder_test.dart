import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local_db/app_database.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/features/context/context_builder.dart';
import 'package:mobile/features/home/home_suggestion_service.dart';

void main() {
  late AppDatabase database;
  late ContextBuilder builder;
  final now = DateTime.utc(2026, 6, 5, 10);

  setUp(() async {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    builder = const ContextBuilder();
    await _insertSourceRows(database, now: now);
  });

  tearDown(() async {
    await database.close();
  });

  test('detects only current suggestion intent with simple rules', () {
    expect(builder.detectIntent('我现在该干什么？'), ContextIntent.currentSuggestion);
    expect(builder.detectIntent('帮我复盘今天'), equals(null));
  });

  test('excludes deleted records from current suggestion context', () async {
    await _insertTask(
      database,
      id: 'task-active',
      title: '联系王总',
      status: RecordStatus.confirmed,
      dueTime: now,
    );
    await _insertTask(
      database,
      id: 'task-deleted',
      title: '已删除任务不应出现',
      status: RecordStatus.deleted,
      dueTime: now,
    );

    final package = await builder.buildCurrentSuggestion(
      database: database,
      now: now,
    );

    expect(package.todayTasks.map((task) => task.title), ['联系王总']);
    expect(package.excludedReasonCounts['deleted'], greaterThanOrEqualTo(1));
  });

  test('excludes expired short-term states from current suggestions', () async {
    await _insertState(
      database,
      id: 'state-active',
      content: '今天有点累',
      status: RecordStatus.confirmed,
      validUntil: now.add(const Duration(hours: 2)),
    );
    await _insertState(
      database,
      id: 'state-expired',
      content: '过期状态不应出现',
      status: RecordStatus.confirmed,
      validUntil: now.subtract(const Duration(minutes: 1)),
    );

    final package = await builder.buildCurrentSuggestion(
      database: database,
      now: now,
    );

    expect(package.activeShortTermStates.map((state) => state.content), [
      '今天有点累',
    ]);
    expect(package.excludedReasonCounts['expired'], 1);
  });

  test('includes confirmed profile items', () async {
    await _insertProfile(
      database,
      id: 'profile-confirmed',
      content: '用户不喜欢太频繁的提醒',
      status: RecordStatus.confirmed,
    );
    await _insertProfile(
      database,
      id: 'profile-deleted',
      content: '已删除画像不应出现',
      status: RecordStatus.deleted,
    );

    final package = await builder.buildCurrentSuggestion(
      database: database,
      now: now,
    );

    expect(package.confirmedProfileItems.map((profile) => profile.content), [
      '用户不喜欢太频繁的提醒',
    ]);
  });

  test('does not treat pending extracted items as truth', () async {
    await _insertPendingExtractedProfile(database, now: now);

    final package = await builder.buildCurrentSuggestion(
      database: database,
      now: now,
    );

    expect(package.confirmedProfileItems, isEmpty);
    expect(package.todayTasks, isEmpty);
    expect(package.excludedReasonCounts['pending'], 1);
    expect(package.excludedReasonCounts['unconfirmed_profile_candidate'], 1);
  });

  test('debug summary includes excluded counts without raw text', () async {
    await _insertSensitiveRawInput(database, now: now);
    await _insertPendingExtractedProfile(database, now: now);

    final package = await builder.buildCurrentSuggestion(
      database: database,
      now: now,
    );
    final debugText = jsonEncode(package.toDebugJson());

    expect(debugText, contains('excluded_reason_counts'));
    expect(debugText, contains('pending'));
    expect(debugText, isNot(contains('我的银行卡密码')));
    expect(debugText, isNot(contains('用户不喜欢太频繁的提醒')));
  });

  test(
    'builds rule-based memory explanations from confirmed records',
    () async {
      await _insertTask(
        database,
        id: 'task-today',
        title: '联系王总',
        status: RecordStatus.confirmed,
        dueTime: now.add(const Duration(hours: 1)),
      );
      await _insertState(
        database,
        id: 'state-active',
        content: '今天有点累',
        status: RecordStatus.confirmed,
        validUntil: now.add(const Duration(hours: 2)),
      );
      await _insertProfile(
        database,
        id: 'profile-confirmed',
        content: '用户不喜欢太频繁的提醒',
        status: RecordStatus.confirmed,
      );

      final package = await builder.buildCurrentSuggestion(
        database: database,
        now: now,
      );

      expect(package.memoryExplanations.map((entry) => entry.sourceType), [
        'tasks',
        'short_term_states',
        'profile_items',
      ]);
      expect(package.memoryExplanations.map((entry) => entry.label), [
        '已确认任务：联系王总',
        '短期状态：今天有点累',
        '长期偏好：用户不喜欢太频繁的提醒',
      ]);
      expect(package.memoryExplanations.map((entry) => entry.reason), [
        '今天到期，参与当前建议排序。',
        '状态仍在有效期内，参与当前建议语气调整。',
        '用户已确认的长期画像，参与当前建议语气调整。',
      ]);
    },
  );

  test(
    'memory explanation excludes pending, deleted, expired, and raw input',
    () async {
      await _insertSensitiveRawInput(database, now: now);
      await _insertTask(
        database,
        id: 'task-deleted',
        title: '已删除任务不应解释',
        status: RecordStatus.deleted,
        dueTime: now,
      );
      await _insertState(
        database,
        id: 'state-expired',
        content: '过期状态不应解释',
        status: RecordStatus.confirmed,
        validUntil: now.subtract(const Duration(minutes: 1)),
      );
      await _insertPendingExtractedProfile(database, now: now);

      final package = await builder.buildCurrentSuggestion(
        database: database,
        now: now,
      );
      final explanationText = package.memoryExplanations
          .map((entry) => '${entry.label} ${entry.reason}')
          .join('\n');

      expect(package.memoryExplanations, isEmpty);
      expect(explanationText, isNot(contains('我的银行卡密码')));
      expect(explanationText, isNot(contains('已删除任务不应解释')));
      expect(explanationText, isNot(contains('过期状态不应解释')));
      expect(explanationText, isNot(contains('我不喜欢太频繁的提醒')));
    },
  );

  test(
    'memory explanation debug json contains counts, not user text',
    () async {
      await _insertSensitiveRawInput(database, now: now);
      await _insertTask(
        database,
        id: 'task-today',
        title: '联系王总',
        status: RecordStatus.confirmed,
        dueTime: now,
      );
      await _insertState(
        database,
        id: 'state-active',
        content: '今天有点累',
        status: RecordStatus.confirmed,
        validUntil: now.add(const Duration(hours: 2)),
      );

      final package = await builder.buildCurrentSuggestion(
        database: database,
        now: now,
      );
      final debugText = jsonEncode(package.toDebugJson());

      expect(debugText, contains('memory_explanation_counts'));
      expect(debugText, contains('tasks'));
      expect(debugText, contains('short_term_states'));
      expect(debugText, isNot(contains('联系王总')));
      expect(debugText, isNot(contains('今天有点累')));
      expect(debugText, isNot(contains('我的银行卡密码')));
    },
  );

  test('task update resolution includes confirmed tasks', () async {
    await _insertTask(
      database,
      id: 'task-active-1',
      title: '联系王总',
      status: RecordStatus.confirmed,
      dueTime: now,
    );
    await _insertTask(
      database,
      id: 'task-active-2',
      title: '客户资料',
      status: RecordStatus.confirmed,
      dueTime: now,
    );

    final package = await builder.buildTaskUpdateResolution(
      database: database,
      now: now,
    );

    expect(package.candidates.map((c) => c.title), ['联系王总', '客户资料']);
  });

  test('task update resolution excludes deleted tasks', () async {
    await _insertTask(
      database,
      id: 'task-deleted-1',
      title: '已删除任务',
      status: RecordStatus.deleted,
      dueTime: now,
    );
    await _insertTask(
      database,
      id: 'task-active-1',
      title: '联系王总',
      status: RecordStatus.confirmed,
      dueTime: now,
    );

    final package = await builder.buildTaskUpdateResolution(
      database: database,
      now: now,
    );

    expect(package.candidates.map((c) => c.title), ['联系王总']);
    expect(package.excludedReasonCounts['deleted'], greaterThanOrEqualTo(1));
  });

  test('task update resolution excludes archived tasks', () async {
    await _insertTask(
      database,
      id: 'task-archived-1',
      title: '已归档任务',
      status: RecordStatus.archived,
      dueTime: now,
    );
    await _insertTask(
      database,
      id: 'task-active-1',
      title: '联系王总',
      status: RecordStatus.confirmed,
      dueTime: now,
    );

    final package = await builder.buildTaskUpdateResolution(
      database: database,
      now: now,
    );

    expect(package.candidates.map((c) => c.title), ['联系王总']);
    expect(package.excludedReasonCounts['archived'], greaterThanOrEqualTo(1));
  });

  test('task update resolution candidate has only minimal fields', () async {
    await _insertTask(
      database,
      id: 'task-active-1',
      title: '联系王总',
      status: RecordStatus.confirmed,
      dueTime: now,
    );

    final package = await builder.buildTaskUpdateResolution(
      database: database,
      now: now,
    );

    final candidate = package.candidates.single;
    expect(candidate.id, 'task-active-1');
    expect(candidate.title, '联系王总');
    expect(candidate.priority, 'medium');
    expect(candidate.dueTime?.toUtc(), now);
    expect(candidate.dueTimeText, null);
  });

  test('task update resolution debug json excludes raw text', () async {
    await _insertSensitiveRawInput(database, now: now);
    await _insertTask(
      database,
      id: 'task-active-1',
      title: '联系王总',
      status: RecordStatus.confirmed,
      dueTime: now,
    );

    final package = await builder.buildTaskUpdateResolution(
      database: database,
      now: now,
    );
    final debugText = jsonEncode(package.toDebugJson());

    expect(debugText, contains('candidate_count'));
    expect(debugText, contains('excluded_reason_counts'));
    expect(debugText, isNot(contains('我的银行卡密码')));
    expect(debugText, isNot(contains('联系王总')));
  });

  test(
    'current suggestion package matches existing home suggestion context',
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
        id: 'task-today',
        title: '联系王总',
        status: RecordStatus.confirmed,
        dueTime: now.add(const Duration(hours: 1)),
      );
      await _insertTask(
        database,
        id: 'task-upcoming',
        title: '准备周会',
        status: RecordStatus.confirmed,
        dueTime: now.add(const Duration(days: 3)),
      );
      await _insertState(
        database,
        id: 'state-active',
        content: '今天有点累',
        status: RecordStatus.confirmed,
        validUntil: now.add(const Duration(hours: 2)),
      );
      await _insertProfile(
        database,
        id: 'profile-confirmed',
        content: '用户不喜欢太频繁的提醒',
        status: RecordStatus.confirmed,
      );

      final package = await builder.buildCurrentSuggestion(
        database: database,
        now: now,
      );
      final homeContext = await const HomeSuggestionService().loadContext(
        database: database,
        now: now,
      );

      expect(package.suggestionTasks.map((task) => task.title), [
        for (final task in homeContext.tasks) task.title,
      ]);
      expect(package.activeShortTermStates.map((state) => state.content), [
        for (final state in homeContext.shortTermStates) state.content,
      ]);
      expect(package.confirmedProfileItems.map((profile) => profile.content), [
        for (final profile in homeContext.profileItems) profile.content,
      ]);
    },
  );
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

Future<void> _insertSensitiveRawInput(
  AppDatabase database, {
  required DateTime now,
}) {
  return database
      .into(database.rawInputs)
      .insert(
        RawInputsCompanion.insert(
          id: 'raw-sensitive',
          inputText: '我的银行卡密码是 123456',
          createdAt: now,
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
          createdAt: nowForTests(dueTime),
          updatedAt: nowForTests(dueTime),
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
          createdAt: DateTime.utc(2026, 6, 5),
          updatedAt: DateTime.utc(2026, 6, 5),
        ),
      );
}

Future<void> _insertPendingExtractedProfile(
  AppDatabase database, {
  required DateTime now,
}) {
  return database
      .into(database.extractedItems)
      .insert(
        ExtractedItemsCompanion.insert(
          id: 'item-profile-pending',
          rawInputId: 'raw-1',
          aiParseResultId: 'parse-1',
          type: ItemType.profileCandidate.apiValue,
          content: const Value('用户不喜欢太频繁的提醒'),
          sourceText: '我不喜欢太频繁的提醒',
          confidence: 0.9,
          needUserConfirm: true,
          status: RecordStatus.pending.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

DateTime nowForTests(DateTime? value) {
  return value ?? DateTime.utc(2026, 6, 5, 10);
}
