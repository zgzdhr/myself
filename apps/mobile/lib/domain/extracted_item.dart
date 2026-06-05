import 'item_type.dart';
import 'record_status.dart';

enum TaskUpdateAction {
  complete,
  cancel,
  delay,
  edit;

  static TaskUpdateAction fromApiValue(String value) {
    return switch (value) {
      'complete' => TaskUpdateAction.complete,
      'cancel' => TaskUpdateAction.cancel,
      'delay' => TaskUpdateAction.delay,
      'edit' => TaskUpdateAction.edit,
      _ => throw FormatException('Unsupported task update action: $value'),
    };
  }
}

enum TaskUpdateResolution {
  ready,
  needsSelection,
  noMatch,
}

class TaskUpdateCandidate {
  const TaskUpdateCandidate({
    required this.id,
    required this.title,
    this.dueTimeText,
  });

  final String id;
  final String title;
  final String? dueTimeText;
}

class TaskUpdateIntent {
  const TaskUpdateIntent({
    required this.action,
    this.targetTaskTitle,
    this.targetText,
    this.dueTimeText,
    this.dueTime,
    this.candidates = const [],
    this.resolution = TaskUpdateResolution.ready,
  });

  final TaskUpdateAction action;
  final String? targetTaskTitle;
  final String? targetText;
  final String? dueTimeText;
  final DateTime? dueTime;
  final List<TaskUpdateCandidate> candidates;
  final TaskUpdateResolution resolution;

  String get targetLabel => targetTaskTitle ?? targetText ?? '任务更新';

  TaskUpdateIntent copyWith({
    TaskUpdateAction? action,
    String? targetTaskTitle,
    String? targetText,
    String? dueTimeText,
    DateTime? dueTime,
    List<TaskUpdateCandidate>? candidates,
    TaskUpdateResolution? resolution,
  }) {
    return TaskUpdateIntent(
      action: action ?? this.action,
      targetTaskTitle: targetTaskTitle ?? this.targetTaskTitle,
      targetText: targetText ?? this.targetText,
      dueTimeText: dueTimeText ?? this.dueTimeText,
      dueTime: dueTime ?? this.dueTime,
      candidates: candidates ?? this.candidates,
      resolution: resolution ?? this.resolution,
    );
  }
}

List<String> _readTags(Object? value) {
  if (value == null) {
    return const [];
  }

  return (value as List<Object?>).whereType<String>().toList();
}

DateTime? _readExpiresAt({
  required Map<String, Object?> json,
  required DateTime parsedAt,
}) {
  final expiresAtText = json['expires_at'] as String?;
  if (expiresAtText != null) {
    return DateTime.parse(expiresAtText);
  }

  final validDays = json['valid_days'] as int?;
  if (validDays != null) {
    return parsedAt.add(Duration(days: validDays));
  }

  return null;
}

class ParsedExtractedItem {
  const ParsedExtractedItem({
    required this.localId,
    required this.type,
    required this.sourceText,
    required this.tags,
    required this.confidence,
    required this.needUserConfirm,
    required this.parsedAt,
    this.title,
    this.content,
    this.expiresAt,
    this.taskUpdateIntent,
  });

  final String localId;
  final ItemType type;
  final String? title;
  final String? content;
  final String sourceText;
  final List<String> tags;
  final double confidence;
  final bool needUserConfirm;
  final DateTime parsedAt;
  final DateTime? expiresAt;
  final TaskUpdateIntent? taskUpdateIntent;

  bool get hasExpiry => expiresAt != null;

  factory ParsedExtractedItem.fromAiJson({
    required Map<String, Object?> json,
    required String localId,
    required DateTime parsedAt,
  }) {
    final type = ItemTypeApiValue.fromApiValue(json['type'] as String);
    final needUserConfirm = type == ItemType.profileCandidate
        ? true
        : (json['need_user_confirm'] as bool? ?? false);

    return ParsedExtractedItem(
      localId: localId,
      type: type,
      title: json['title'] as String?,
      content: json['content'] as String?,
      sourceText: json['source_text'] as String,
      tags: _readTags(json['tags']),
      confidence: (json['confidence'] as num).toDouble(),
      needUserConfirm: needUserConfirm,
      parsedAt: parsedAt,
      expiresAt: _readExpiresAt(json: json, parsedAt: parsedAt),
      taskUpdateIntent: _readTaskUpdateIntent(json),
    );
  }

  static TaskUpdateIntent? _readTaskUpdateIntent(Map<String, Object?> json) {
    final actionValue = json['update_action'] as String?;
    if (actionValue == null) {
      return null;
    }

    final dueTimeIso = json['due_time_iso'] as String?;
    return TaskUpdateIntent(
      action: TaskUpdateAction.fromApiValue(actionValue),
      targetTaskTitle: json['target_task_title'] as String?,
      targetText: json['target_text'] as String?,
      dueTimeText: json['due_time_text'] as String?,
      dueTime: dueTimeIso == null ? null : DateTime.parse(dueTimeIso),
    );
  }
}

class ExtractedItem {
  const ExtractedItem({
    required this.localId,
    required this.rawInputId,
    required this.type,
    required this.sourceText,
    required this.tags,
    required this.confidence,
    required this.needUserConfirm,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.content,
    this.expiresAt,
    this.taskUpdateIntent,
  });

  final String localId;
  final String rawInputId;
  final ItemType type;
  final String? title;
  final String? content;
  final String sourceText;
  final List<String> tags;
  final double confidence;
  final bool needUserConfirm;
  final RecordStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final TaskUpdateIntent? taskUpdateIntent;

  bool get hasExpiry => expiresAt != null;
}
