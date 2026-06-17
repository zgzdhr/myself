import '../../domain/extracted_item.dart';

class TaskUpdateMatchResult {
  const TaskUpdateMatchResult({
    required this.candidates,
    required this.resolution,
  });

  final List<TaskUpdateCandidate> candidates;
  final TaskUpdateResolution resolution;
}

class TaskUpdateMatcher {
  const TaskUpdateMatcher();

  TaskUpdateMatchResult match({
    required TaskUpdateIntent intent,
    required String sourceText,
    required List<TaskUpdateCandidate> activeTaskCandidates,
  }) {
    final normalizedQueries = _taskUpdateMatchQueries(
      taskUpdateIntent: intent,
      sourceText: sourceText,
    );

    if (normalizedQueries.isEmpty) {
      return const TaskUpdateMatchResult(
        candidates: [],
        resolution: TaskUpdateResolution.noMatch,
      );
    }

    final matches = _matchTaskUpdateCandidates(
      activeTaskCandidates: activeTaskCandidates,
      normalizedQueries: normalizedQueries,
    );
    final resolution = resolveTaskUpdateResolution(
      intent: intent,
      matches: matches,
    );

    return TaskUpdateMatchResult(candidates: matches, resolution: resolution);
  }

  TaskUpdateResolution resolveTaskUpdateResolution({
    required TaskUpdateIntent intent,
    required List<TaskUpdateCandidate> matches,
  }) {
    if (matches.isEmpty) {
      return TaskUpdateResolution.noMatch;
    }

    if (isDelayMissingNewTime(intent)) {
      return TaskUpdateResolution.needsSelection;
    }

    return matches.length == 1
        ? TaskUpdateResolution.ready
        : TaskUpdateResolution.needsSelection;
  }

  bool isDelayMissingNewTime(TaskUpdateIntent intent) {
    return intent.action == TaskUpdateAction.delay &&
        intent.dueTimeText == null &&
        intent.dueTime == null;
  }

  TaskUpdateCandidate? firstCandidateOrNull(
    List<TaskUpdateCandidate> candidates,
  ) {
    return candidates.isEmpty ? null : candidates.first;
  }

  TaskUpdateCandidate? firstTaskUpdateCandidate(
    List<TaskUpdateCandidate> candidates,
    String id,
  ) {
    for (final candidate in candidates) {
      if (candidate.id == id) {
        return candidate;
      }
    }
    return null;
  }

  String _normalizeTaskText(String value) {
    var normalized = value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[，。！？、,.!?；;：:]'), '')
        .toLowerCase();

    const noisePhrases = [
      '这件事情',
      '那件事情',
      '这个事情',
      '那个事情',
      '这件事',
      '那件事',
      '这个事',
      '那个事',
      '这个任务',
      '那个任务',
      '的事情',
      '这事',
      '那事',
      '事情',
      '任务',
      '一下',
    ];
    for (final phrase in noisePhrases) {
      normalized = normalized.replaceAll(phrase, '');
    }

    const actionNoise = [
      '已经做完了',
      '做完了',
      '完成了',
      '搞定了',
      '处理好了',
      '不用去了',
      '不想去了',
      '不去了',
      '不用做了',
      '不想做了',
      '先不做了',
      '不用开了',
      '不想开了',
      '不开了',
      '取消掉',
      '取消了',
      '取消',
      '改天再说',
      '算了',
    ];
    for (final phrase in actionNoise) {
      normalized = normalized.replaceAll(phrase, '');
    }

    return normalized;
  }

  List<String> _taskUpdateMatchQueries({
    required TaskUpdateIntent taskUpdateIntent,
    required String sourceText,
  }) {
    final rawQueries = [
      taskUpdateIntent.targetTaskTitle,
      taskUpdateIntent.targetText,
      sourceText,
    ];

    final queries = <String>[];
    for (final rawQuery in rawQueries) {
      final normalizedQuery = _normalizeTaskText(rawQuery ?? '');
      if (normalizedQuery.isEmpty || _isGenericTaskTarget(normalizedQuery)) {
        continue;
      }
      if (!queries.contains(normalizedQuery)) {
        queries.add(normalizedQuery);
      }
    }
    return queries;
  }

  List<TaskUpdateCandidate> _matchTaskUpdateCandidates({
    required List<TaskUpdateCandidate> activeTaskCandidates,
    required List<String> normalizedQueries,
  }) {
    final exactMatches = _uniqueTaskUpdateCandidates([
      for (final candidate in activeTaskCandidates)
        if (normalizedQueries.contains(_normalizeTaskText(candidate.title)))
          candidate,
    ]);
    if (exactMatches.isNotEmpty) {
      return exactMatches;
    }

    final containsMatches = _uniqueTaskUpdateCandidates([
      for (final candidate in activeTaskCandidates)
        if (_taskTitleContainsAnyQuery(candidate.title, normalizedQueries))
          candidate,
    ]);
    if (containsMatches.isNotEmpty) {
      return containsMatches;
    }

    return _uniqueTaskUpdateCandidates([
      for (final candidate in activeTaskCandidates)
        if (_hasStrongTaskTokenOverlap(
          title: candidate.title,
          normalizedQueries: normalizedQueries,
        ))
          candidate,
    ]);
  }

  bool _taskTitleContainsAnyQuery(
    String title,
    List<String> normalizedQueries,
  ) {
    final normalizedTitle = _normalizeTaskText(title);
    return normalizedQueries.any(
      (query) =>
          normalizedTitle.contains(query) || query.contains(normalizedTitle),
    );
  }

  bool _hasStrongTaskTokenOverlap({
    required String title,
    required List<String> normalizedQueries,
  }) {
    final titleTokens = _taskMatchTokens(title);
    if (titleTokens.isEmpty) {
      return false;
    }

    for (final query in normalizedQueries) {
      final queryTokens = _taskMatchTokens(query);
      if (queryTokens.isEmpty) {
        continue;
      }
      if (queryTokens.any(titleTokens.contains)) {
        return true;
      }
    }
    return false;
  }

  List<String> _taskMatchTokens(String value) {
    final normalized = _normalizeTaskText(value);
    if (normalized.isEmpty || _isGenericTaskTarget(normalized)) {
      return const [];
    }

    const semanticTokens = [
      '高考',
      '健身',
      '开会',
      '会议',
      '王总',
      '张总',
      '李总',
      '客户',
      '资料',
      '方案',
      '周报',
      'ppt',
      '合同',
    ];

    final tokens = <String>[];
    for (final token in semanticTokens) {
      if (normalized.contains(token.toLowerCase())) {
        tokens.add(token.toLowerCase());
      }
    }

    final chineseChunks = RegExp(r'[\u4e00-\u9fa5]{2,}')
        .allMatches(normalized)
        .map((match) => match.group(0)!)
        .where((chunk) => chunk.length >= 2);
    for (final chunk in chineseChunks) {
      if (!tokens.contains(chunk)) {
        tokens.add(chunk);
      }
    }

    final latinChunks = RegExp(r'[a-z0-9]{2,}')
        .allMatches(normalized)
        .map((match) => match.group(0)!)
        .where((chunk) => chunk.length >= 2);
    for (final chunk in latinChunks) {
      if (!tokens.contains(chunk)) {
        tokens.add(chunk);
      }
    }

    return tokens;
  }

  List<TaskUpdateCandidate> _uniqueTaskUpdateCandidates(
    List<TaskUpdateCandidate> candidates,
  ) {
    final seen = <String>{};
    final unique = <TaskUpdateCandidate>[];
    for (final candidate in candidates) {
      if (seen.add(candidate.id)) {
        unique.add(candidate);
      }
    }
    return unique;
  }

  bool _isGenericTaskTarget(String normalizedQuery) {
    const genericTargets = {
      '那个事',
      '这个事',
      '那件事',
      '这件事',
      '这个任务',
      '那个任务',
      '刚才那个',
      '之前那个',
      '刚才',
      '之前',
      '它',
    };
    return genericTargets.contains(normalizedQuery);
  }
}
