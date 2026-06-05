import 'item_type.dart';
import 'record_status.dart';

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

  bool get hasExpiry => expiresAt != null;
}
