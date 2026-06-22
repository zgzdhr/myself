class ReviewResult {
  const ReviewResult({
    required this.title,
    required this.dailySummary,
    required this.encouragement,
    required this.improvementNotes,
    required this.taskGuidance,
    required this.openItems,
    required this.sourceRefs,
    required this.confidence,
  });

  final String title;
  final String dailySummary;
  final String encouragement;
  final String improvementNotes;
  final String taskGuidance;
  final List<String> openItems;
  final List<ReviewSourceRef> sourceRefs;
  final double confidence;

  factory ReviewResult.fromJson(Map<String, Object?> json) {
    return ReviewResult(
      title: json['title'] as String,
      dailySummary: json['daily_summary'] as String,
      encouragement: json['encouragement'] as String,
      improvementNotes: json['improvement_notes'] as String,
      taskGuidance: json['task_guidance'] as String,
      openItems: [
        for (final item in (json['open_items'] as List? ?? const []))
          item as String,
      ],
      sourceRefs: [
        for (final item in (json['source_refs'] as List? ?? const []))
          ReviewSourceRef.fromJson(item as Map<String, Object?>),
      ],
      confidence: (json['confidence'] as num? ?? 0.7).toDouble(),
    );
  }
}

class ReviewSourceRef {
  const ReviewSourceRef({
    required this.sourceTable,
    required this.sourceRecordId,
  });

  final String sourceTable;
  final String sourceRecordId;

  factory ReviewSourceRef.fromJson(Map<String, Object?> json) {
    return ReviewSourceRef(
      sourceTable: json['source_table'] as String,
      sourceRecordId: json['source_record_id'] as String,
    );
  }
}
