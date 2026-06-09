import 'dart:convert';

import '../../data/local_db/app_database.dart';
import '../../domain/item_type.dart';
import '../../domain/record_status.dart';
import '../../domain/task_status.dart';

enum ContextIntent {
  currentSuggestion,
  taskUpdateResolution;

  String get value {
    return switch (this) {
      ContextIntent.currentSuggestion => 'current_suggestion',
      ContextIntent.taskUpdateResolution => 'task_update_resolution',
    };
  }
}

class ContextBuilder {
  const ContextBuilder();

  ContextIntent? detectIntent(String input) {
    final normalized = input.trim();
    if (normalized.contains('该干什么') ||
        normalized.contains('做什么') ||
        normalized.contains('先干嘛') ||
        normalized.contains('先做什么')) {
      return ContextIntent.currentSuggestion;
    }
    return null;
  }

  Future<ContextPackage> buildCurrentSuggestion({
    required AppDatabase database,
    required DateTime now,
  }) async {
    final suggestionTasks = await database.getSuggestionTasks(now: now);
    final states = await database.getActiveShortTermStates(now: now);
    final profiles = await database.getActiveProfileItems();
    final excludedReasonCounts = await _loadExcludedReasonCounts(
      database: database,
      now: now,
    );

    final contextTasks = [
      for (final task in suggestionTasks)
        ContextTask(
          id: task.id,
          title: task.title,
          priority: task.priority,
          dueTimeText: task.dueTimeText,
          dueTime: task.dueTime,
        ),
    ];

    return ContextPackage(
      intent: ContextIntent.currentSuggestion,
      currentTime: now,
      suggestionTasks: contextTasks,
      overdueTasks: [
        for (final task in contextTasks)
          if (task.dueTime != null && task.dueTime!.isBefore(now)) task,
      ],
      todayTasks: [
        for (final task in contextTasks)
          if (task.dueTime != null &&
              !task.dueTime!.isBefore(now) &&
              _isSameDay(task.dueTime!, now))
            task,
      ],
      nextSevenDaysTasks: [
        for (final task in contextTasks)
          if (task.dueTime != null &&
              task.dueTime!.isAfter(now) &&
              !_isSameDay(task.dueTime!, now) &&
              !task.dueTime!.isAfter(now.add(const Duration(days: 7))))
            task,
      ],
      unscheduledTasks: [
        for (final task in contextTasks)
          if (task.dueTime == null) task,
      ],
      activeShortTermStates: [
        for (final state in states)
          ContextShortTermState(
            id: state.id,
            content: state.content,
            tags: _decodeTags(state.tagsJson),
            validUntil: state.validUntil,
          ),
      ],
      confirmedProfileItems: [
        for (final profile in profiles)
          ContextProfileItem(id: profile.id, content: profile.content),
      ],
      memoryExplanations: _buildMemoryExplanations(
        now: now,
        tasks: contextTasks,
        states: states,
        profiles: profiles,
      ),
      excludedReasonCounts: excludedReasonCounts,
    );
  }

  Future<ContextTaskUpdatePackage> buildTaskUpdateResolution({
    required AppDatabase database,
    required DateTime now,
  }) async {
    final allTasks = await database.select(database.tasks).get();
    final candidates = <ContextTaskCandidate>[];
    var deletedCount = 0;
    var archivedCount = 0;
    var inactiveTaskCount = 0;

    for (final task in allTasks) {
      if (task.status == RecordStatus.confirmed.value &&
          task.taskStatus == TaskStatus.active.value) {
        candidates.add(
          ContextTaskCandidate(
            id: task.id,
            title: task.title,
            priority: task.priority,
            dueTimeText: task.dueTimeText,
            dueTime: task.dueTime,
          ),
        );
      } else if (task.status == RecordStatus.confirmed.value) {
        inactiveTaskCount++;
      } else if (task.status == RecordStatus.deleted.value) {
        deletedCount++;
      } else if (task.status == RecordStatus.archived.value) {
        archivedCount++;
      }
    }

    final excludedReasonCounts = <String, int>{};
    if (deletedCount > 0) excludedReasonCounts['deleted'] = deletedCount;
    if (archivedCount > 0) excludedReasonCounts['archived'] = archivedCount;
    if (inactiveTaskCount > 0) {
      excludedReasonCounts['inactive_tasks'] = inactiveTaskCount;
    }

    return ContextTaskUpdatePackage(
      candidates: candidates,
      excludedReasonCounts: excludedReasonCounts,
    );
  }

  Future<Map<String, int>> _loadExcludedReasonCounts({
    required AppDatabase database,
    required DateTime now,
  }) async {
    final tasks = await database.select(database.tasks).get();
    final states = await database.select(database.shortTermStates).get();
    final profiles = await database.select(database.profileItems).get();
    final extractedItems = await database.select(database.extractedItems).get();
    final rawInputs = await database.select(database.rawInputs).get();

    final counts = <String, int>{
      'deleted': 0,
      'rejected': 0,
      'pending': 0,
      'expired': 0,
      'inactive_tasks': 0,
      'unconfirmed_profile_candidate': 0,
      'raw_inputs_default_excluded': rawInputs.length,
    };

    for (final task in tasks) {
      if (task.status == RecordStatus.deleted.value) {
        counts['deleted'] = counts['deleted']! + 1;
      } else if (task.status == RecordStatus.confirmed.value &&
          task.taskStatus != TaskStatus.active.value) {
        counts['inactive_tasks'] = counts['inactive_tasks']! + 1;
      }
    }

    for (final state in states) {
      if (state.status == RecordStatus.deleted.value) {
        counts['deleted'] = counts['deleted']! + 1;
      }
      if (state.status == RecordStatus.expired.value ||
          (state.status == RecordStatus.confirmed.value &&
              !state.validUntil.isAfter(now))) {
        counts['expired'] = counts['expired']! + 1;
      }
    }

    for (final profile in profiles) {
      if (profile.status == RecordStatus.deleted.value) {
        counts['deleted'] = counts['deleted']! + 1;
      }
    }

    for (final item in extractedItems) {
      if (item.status == RecordStatus.deleted.value) {
        counts['deleted'] = counts['deleted']! + 1;
      }
      if (item.status == RecordStatus.rejected.value) {
        counts['rejected'] = counts['rejected']! + 1;
      }
      if (item.status == RecordStatus.pending.value) {
        counts['pending'] = counts['pending']! + 1;
      }
      if (item.type == ItemType.profileCandidate.apiValue &&
          item.status != RecordStatus.confirmed.value &&
          item.status != RecordStatus.deleted.value &&
          item.status != RecordStatus.rejected.value) {
        counts['unconfirmed_profile_candidate'] =
            counts['unconfirmed_profile_candidate']! + 1;
      }
    }

    return {
      for (final entry in counts.entries)
        if (entry.value > 0) entry.key: entry.value,
    };
  }

  static List<String> _decodeTags(String value) {
    final decoded = jsonDecode(value) as List<Object?>;
    return decoded.whereType<String>().toList();
  }

  static List<ContextMemoryExplanation> _buildMemoryExplanations({
    required DateTime now,
    required List<ContextTask> tasks,
    required List<ShortTermState> states,
    required List<ProfileItem> profiles,
  }) {
    return [
      for (final task in tasks)
        ContextMemoryExplanation(
          sourceType: 'tasks',
          sourceId: task.id,
          label: '已确认任务：${task.title}',
          reason: _taskExplanationReason(task: task, now: now),
        ),
      for (final state in states)
        ContextMemoryExplanation(
          sourceType: 'short_term_states',
          sourceId: state.id,
          label: '短期状态：${state.content}',
          reason: '状态仍在有效期内，参与当前建议语气调整。',
        ),
      for (final profile in profiles)
        ContextMemoryExplanation(
          sourceType: 'profile_items',
          sourceId: profile.id,
          label: '长期偏好：${profile.content}',
          reason: '用户已确认的长期画像，参与当前建议语气调整。',
        ),
    ];
  }

  static String _taskExplanationReason({
    required ContextTask task,
    required DateTime now,
  }) {
    final dueTime = task.dueTime;
    if (dueTime == null) {
      return '没有明确到期时间，但仍是已确认任务，参与当前建议排序。';
    }
    if (dueTime.isBefore(now)) {
      return '已经逾期，参与当前建议排序。';
    }
    if (_isSameDay(dueTime, now)) {
      return '今天到期，参与当前建议排序。';
    }
    return '未来 7 天内到期，参与当前建议排序。';
  }

  static Map<String, int> _countMemoryExplanationsBySourceType(
    List<ContextMemoryExplanation> explanations,
  ) {
    final counts = <String, int>{};
    for (final explanation in explanations) {
      counts[explanation.sourceType] =
          (counts[explanation.sourceType] ?? 0) + 1;
    }
    return counts;
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    final leftLocal = left.toLocal();
    final rightLocal = right.toLocal();
    return leftLocal.year == rightLocal.year &&
        leftLocal.month == rightLocal.month &&
        leftLocal.day == rightLocal.day;
  }
}

class ContextPackage {
  const ContextPackage({
    required this.intent,
    required this.currentTime,
    required this.suggestionTasks,
    required this.overdueTasks,
    required this.todayTasks,
    required this.nextSevenDaysTasks,
    required this.unscheduledTasks,
    required this.activeShortTermStates,
    required this.confirmedProfileItems,
    required this.memoryExplanations,
    required this.excludedReasonCounts,
  });

  final ContextIntent intent;
  final DateTime currentTime;
  final List<ContextTask> suggestionTasks;
  final List<ContextTask> overdueTasks;
  final List<ContextTask> todayTasks;
  final List<ContextTask> nextSevenDaysTasks;
  final List<ContextTask> unscheduledTasks;
  final List<ContextShortTermState> activeShortTermStates;
  final List<ContextProfileItem> confirmedProfileItems;
  final List<ContextMemoryExplanation> memoryExplanations;
  final Map<String, int> excludedReasonCounts;

  Map<String, Object?> toDebugJson() {
    return {
      'intent': intent.value,
      'current_time': currentTime.toIso8601String(),
      'section_counts': {
        'overdue_tasks': overdueTasks.length,
        'today_tasks': todayTasks.length,
        'next_7_days_tasks': nextSevenDaysTasks.length,
        'unscheduled_tasks': unscheduledTasks.length,
        'active_short_term_states': activeShortTermStates.length,
        'confirmed_profile_items': confirmedProfileItems.length,
      },
      'excluded_reason_counts': excludedReasonCounts,
      'memory_explanation_counts':
          ContextBuilder._countMemoryExplanationsBySourceType(
            memoryExplanations,
          ),
    };
  }
}

class ContextTask {
  const ContextTask({
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
}

class ContextShortTermState {
  const ContextShortTermState({
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

class ContextProfileItem {
  const ContextProfileItem({required this.id, required this.content});

  final String id;
  final String content;
}

class ContextMemoryExplanation {
  const ContextMemoryExplanation({
    required this.sourceType,
    required this.sourceId,
    required this.label,
    required this.reason,
  });

  final String sourceType;
  final String sourceId;
  final String label;
  final String reason;
}

class ContextTaskUpdatePackage {
  const ContextTaskUpdatePackage({
    required this.candidates,
    required this.excludedReasonCounts,
  });

  final List<ContextTaskCandidate> candidates;
  final Map<String, int> excludedReasonCounts;

  Map<String, Object?> toDebugJson() {
    return {
      'intent': ContextIntent.taskUpdateResolution.value,
      'candidate_count': candidates.length,
      'excluded_reason_counts': excludedReasonCounts,
    };
  }
}

class ContextTaskCandidate {
  const ContextTaskCandidate({
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
}
