import '../../data/local_db/app_database.dart';
import '../context/context_builder.dart';
import '../memory/task_time_formatter.dart';

class HomeSuggestion {
  const HomeSuggestion({required this.text, required this.reason});

  final String text;
  final String reason;
}

class HomeSuggestionContext {
  const HomeSuggestionContext({
    required this.now,
    required this.tasks,
    this.todayTasks = const [],
    required this.shortTermStates,
    required this.profileItems,
    this.summaries = const [],
  });

  final DateTime now;
  final List<HomeTask> tasks;
  final List<HomeTask> todayTasks;
  final List<HomeShortTermState> shortTermStates;
  final List<HomeProfileItem> profileItems;
  final List<HomeSummary> summaries;
}

class HomeTask {
  const HomeTask({
    required this.id,
    required this.title,
    required this.priority,
    this.dueTimeText,
    this.dueTime,
  });

  final String id;
  final String title;
  final String priority;
  final String? dueTimeText;
  final DateTime? dueTime;

  String get displayText {
    return '$title｜${formatTaskDueText(dueTime: dueTime, dueTimeText: dueTimeText)}';
  }
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

class HomeSummary {
  const HomeSummary({
    required this.id,
    required this.title,
    required this.content,
    required this.taskGuidance,
  });

  final String id;
  final String title;
  final String content;
  final String? taskGuidance;
}

class HomeSuggestionService {
  const HomeSuggestionService();

  Future<HomeSuggestionContext> loadContext({
    required AppDatabase database,
    required DateTime now,
    bool includeReviewSummaries = true,
  }) async {
    final package = await const ContextBuilder().buildCurrentSuggestion(
      database: database,
      now: now,
      includeSummaries: includeReviewSummaries,
    );

    return HomeSuggestionContext(
      now: now,
      tasks: [
        for (final task in package.suggestionTasks)
          HomeTask(
            id: task.id,
            title: task.title,
            priority: task.priority,
            dueTimeText: task.dueTimeText,
            dueTime: task.dueTime,
          ),
      ],
      todayTasks: [
        for (final task in package.todayTasks)
          HomeTask(
            id: task.id,
            title: task.title,
            priority: task.priority,
            dueTimeText: task.dueTimeText,
            dueTime: task.dueTime,
          ),
      ],
      shortTermStates: [
        for (final state in package.activeShortTermStates)
          HomeShortTermState(
            id: state.id,
            content: state.content,
            tags: state.tags,
            validUntil: state.validUntil,
          ),
      ],
      profileItems: [
        for (final profile in package.confirmedProfileItems)
          HomeProfileItem(id: profile.id, content: profile.content),
      ],
      summaries: [
        for (final summary in package.relevantSummaries)
          HomeSummary(
            id: summary.id,
            title: summary.title,
            content: summary.content,
            taskGuidance: summary.taskGuidance,
          ),
      ],
    );
  }

  List<HomeSuggestion> buildSuggestions(HomeSuggestionContext context) {
    if (context.tasks.isEmpty) {
      return [
        HomeSuggestion(
          text: '目前没有需要优先处理的任务，可以先补充一条今天最重要的事情。',
          reason: _buildEmptyReason(context),
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
    final parts = <String>[];
    parts.add('基于任务：${task.title}');

    final dueTime = task.dueTime;
    if (dueTime != null && dueTime.isBefore(context.now)) {
      parts.add('（已逾期）');
    } else if (dueTime != null && _isSameDay(dueTime, context.now)) {
      parts.add('（今日）');
    } else if (dueTime != null) {
      parts.add('（未来 7 天）');
    }

    if (context.shortTermStates.isNotEmpty) {
      final statesText = context.shortTermStates
          .map((s) => s.content)
          .join('，');
      parts.add('| 当前状态：$statesText');
    }

    if (context.profileItems.isNotEmpty) {
      final profilesText = context.profileItems
          .map((p) => p.content)
          .take(2)
          .join('，');
      parts.add('| 长期偏好：$profilesText');
    }

    if (context.summaries.isNotEmpty) {
      parts.add('| 近期复盘：${_summaryHint(context.summaries.first)}');
    }

    return parts.join(' ');
  }

  String _buildEmptyReason(HomeSuggestionContext context) {
    final parts = <String>['首页建议只使用已确认任务、未过期短期状态、已确认长期画像和近期复盘弱上下文。'];
    if (context.summaries.isNotEmpty) {
      parts.add('近期复盘：${_summaryHint(context.summaries.first)}');
    }
    return parts.join(' ');
  }

  String _summaryHint(HomeSummary summary) {
    final taskGuidance = summary.taskGuidance?.trim();
    final text = taskGuidance != null && taskGuidance.isNotEmpty
        ? taskGuidance
        : summary.content.trim();
    return _clip(text, 42);
  }

  String _clip(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
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
}
