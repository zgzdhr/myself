class PlanResult {
  const PlanResult({
    required this.title,
    required this.overview,
    required this.blocks,
    required this.unscheduledTaskIds,
    required this.suggestions,
    required this.sourceRefs,
    required this.confidence,
  });

  final String title;
  final String overview;
  final List<PlanBlockResult> blocks;
  final List<String> unscheduledTaskIds;
  final List<String> suggestions;
  final List<PlanSourceRef> sourceRefs;
  final double confidence;

  factory PlanResult.fromJson(Map<String, Object?> json) {
    return PlanResult(
      title: json['title'] as String,
      overview: json['overview'] as String,
      blocks: [
        for (final item in (json['blocks'] as List? ?? const []))
          PlanBlockResult.fromJson(item as Map<String, Object?>),
      ],
      unscheduledTaskIds: [
        for (final item in (json['unscheduled_task_ids'] as List? ?? const []))
          item as String,
      ],
      suggestions: [
        for (final item in (json['suggestions'] as List? ?? const []))
          item as String,
      ],
      sourceRefs: [
        for (final item in (json['source_refs'] as List? ?? const []))
          PlanSourceRef.fromJson(item as Map<String, Object?>),
      ],
      confidence: (json['confidence'] as num? ?? 0.7).toDouble(),
    );
  }
}

class PlanBlockResult {
  const PlanBlockResult({
    required this.title,
    required this.blockType,
    required this.startTime,
    required this.endTime,
    required this.taskId,
    required this.note,
    required this.reason,
    required this.confidence,
    required this.sourceRefs,
  });

  final String title;
  final String blockType;
  final DateTime startTime;
  final DateTime endTime;
  final String? taskId;
  final String note;
  final String reason;
  final double confidence;
  final List<PlanSourceRef> sourceRefs;

  factory PlanBlockResult.fromJson(Map<String, Object?> json) {
    return PlanBlockResult(
      title: json['title'] as String,
      blockType: json['block_type'] as String,
      startTime: DateTime.parse(json['start_time_iso'] as String),
      endTime: DateTime.parse(json['end_time_iso'] as String),
      taskId: json['task_id'] as String?,
      note: json['note'] as String? ?? '',
      reason: json['reason'] as String,
      confidence: (json['confidence'] as num? ?? 0.7).toDouble(),
      sourceRefs: [
        for (final item in (json['source_refs'] as List? ?? const []))
          PlanSourceRef.fromJson(item as Map<String, Object?>),
      ],
    );
  }
}

class PlanSourceRef {
  const PlanSourceRef({
    required this.sourceTable,
    required this.sourceRecordId,
  });

  final String sourceTable;
  final String sourceRecordId;

  factory PlanSourceRef.fromJson(Map<String, Object?> json) {
    return PlanSourceRef(
      sourceTable: json['source_table'] as String,
      sourceRecordId: json['source_record_id'] as String,
    );
  }
}
