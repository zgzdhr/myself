import 'extracted_item.dart';
import 'item_type.dart';

class ParseResult {
  const ParseResult({
    required this.userReply,
    required this.inputSummary,
    required this.intentTypes,
    required this.items,
  });

  final String userReply;
  final String inputSummary;
  final List<ItemType> intentTypes;
  final List<ExtractedItem> items;

  factory ParseResult.fromAiJson({
    required Map<String, Object?> json,
    required String rawInputId,
    required DateTime parsedAt,
  }) {
    final itemJsonList = json['items'] as List<Object?>;

    return ParseResult(
      userReply: json['user_reply'] as String,
      inputSummary: json['input_summary'] as String,
      intentTypes: (json['intent_types'] as List<Object?>)
          .whereType<String>()
          .map(ItemTypeApiValue.fromApiValue)
          .toList(),
      items: [
        for (final (index, itemJson) in itemJsonList.indexed)
          ExtractedItem.fromAiJson(
            json: itemJson as Map<String, Object?>,
            localId: '$rawInputId:$index',
            rawInputId: rawInputId,
            parsedAt: parsedAt,
          ),
      ],
    );
  }
}
