import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/local_db/app_database.dart';
import '../../domain/record_status.dart';

class HomeSuggestion {
  const HomeSuggestion({required this.text, required this.reason});

  final String text;
  final String reason;
}

class HomeSuggestionContext {
  const HomeSuggestionContext({
    required this.now,
    required this.tasks,
    required this.shortTermStates,
    required this.profileItems,
  });

  final DateTime now;
  final List<HomeTask> tasks;
  final List<HomeShortTermState> shortTermStates;
  final List<HomeProfileItem> profileItems;
}

class HomeTask {
  const HomeTask({
    required this.id,
    required this.title,
    required this.priority,
    this.dueTime,
  });

  final String id;
  final String title;
  final String priority;
  final DateTime? dueTime;
}

class HomeShortTermState {
  const HomeShortTermState({
    required this.id,
    required this.content,
    required this.tags,
    required this.validUntil,
  });

  final String id;
  final String content;
  final List<String> tags;
  final DateTime validUntil;
}

class HomeProfileItem {
  const HomeProfileItem({required this.id, required this.content});

  final String id;
  final String content;
}

class HomeSuggestionService {
  const HomeSuggestionService();

  Future<HomeSuggestionContext> loadContext({
    required AppDatabase database,
    required DateTime now,
  }) async {
    final tasks = await database.getSuggestionTasks(now: now);
    final states = await database.getActiveShortTermStates(now: now);
    final profiles = await database.getActiveProfileItems();

    return HomeSuggestionContext(
      now: now,
      tasks: [
        for (final task in tasks)
          HomeTask(
            id: task.id,
            title: task.title,
            priority: task.priority,
            dueTime: task.dueTime,
          ),
      ],
      shortTermStates: [
        for (final state in states)
          HomeShortTermState(
            id: state.id,
            content: state.content,
            tags: _decodeTags(state.tagsJson),
            validUntil: state.validUntil,
          ),
      ],
      profileItems: [
        for (final profile in profiles)
          HomeProfileItem(id: profile.id, content: profile.content),
      ],
    );
  }

  List<HomeSuggestion> buildSuggestions(HomeSuggestionContext context) {
    if (context.tasks.isEmpty) {
      return const [
        HomeSuggestion(
          text: '目前没有需要优先处理的任务，可以先补充一条今天最重要的事情。',
          reason: '首页建议只使用已确认任务、未过期短期状态和已确认长期画像。',
        ),
      ];
    }

    final sortedTasks = [...context.tasks]
      ..sort((left, right) {
        final leftDue = left.dueTime ?? DateTime(9999);
        final rightDue = right.dueTime ?? DateTime(9999);
        return leftDue.compareTo(rightDue);
      });
    final hasLowEnergy = _hasLowEnergy(context.shortTermStates);
    final avoidPushyLanguage = _avoidPushyLanguage(context.profileItems);

    return [
      for (final task in sortedTasks.take(3))
        HomeSuggestion(
          text: _buildSuggestionText(
            task: task,
            hasLowEnergy: hasLowEnergy,
            avoidPushyLanguage: avoidPushyLanguage,
          ),
          reason: _buildReason(task: task, context: context),
        ),
    ];
  }

  String _buildSuggestionText({
    required HomeTask task,
    required bool hasLowEnergy,
    required bool avoidPushyLanguage,
  }) {
    final prefix = avoidPushyLanguage ? '可以考虑' : '建议先';
    final effortHint = hasLowEnergy ? '用低阻力方式处理' : '处理';
    return '$prefix$effortHint：${task.title}。';
  }

  String _buildReason({
    required HomeTask task,
    required HomeSuggestionContext context,
  }) {
    final dueTime = task.dueTime;

    if (dueTime == null) {
      return '这是已确认任务，但目前没有明确时间。';
    }

    if (dueTime.isBefore(context.now)) {
      return '这个任务已经逾期，优先处理可以减少待办压力。';
    }

    if (_isSameDay(dueTime, context.now)) {
      return '这个任务安排在今天，适合作为当前行动入口。';
    }

    return '这是未来 7 天内的已确认任务，适合提前准备。';
  }

  bool _hasLowEnergy(List<HomeShortTermState> states) {
    return states.any((state) {
      final text = '${state.content} ${state.tags.join(' ')}'.toLowerCase();
      return text.contains('累') ||
          text.contains('疲惫') ||
          text.contains('energy') ||
          text.contains('low');
    });
  }

  bool _avoidPushyLanguage(List<HomeProfileItem> profiles) {
    return profiles.any((profile) {
      return profile.content.contains('不喜欢太频繁的提醒') ||
          profile.content.contains('提醒少一点') ||
          profile.content.contains('别太频繁提醒');
    });
  }

  bool _isSameDay(DateTime left, DateTime right) {
    final leftLocal = left.toLocal();
    final rightLocal = right.toLocal();
    return leftLocal.year == rightLocal.year &&
        leftLocal.month == rightLocal.month &&
        leftLocal.day == rightLocal.day;
  }

  static List<String> _decodeTags(String value) {
    final decoded = jsonDecode(value) as List<Object?>;
    return decoded.whereType<String>().toList();
  }
}

extension HomeSuggestionQueries on AppDatabase {
  Future<List<Task>> getSuggestionTasks({required DateTime now}) {
    final nextSevenDaysEnd = now.add(const Duration(days: 7));

    return (select(tasks)
          ..where(
            (task) =>
                task.status.equals(RecordStatus.confirmed.value) &
                (task.dueTime.isNull() |
                    task.dueTime.isSmallerOrEqualValue(nextSevenDaysEnd)),
          )
          ..orderBy([(task) => OrderingTerm(expression: task.dueTime)]))
        .get();
  }
}
