import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local_db/app_database.dart' as db;
import '../../data/parser/parser_client.dart';
import '../../domain/extracted_item.dart';
import '../../domain/item_type.dart';
import '../../domain/parse_result.dart';
import '../../domain/record_status.dart';

class SubmitInputResult {
  const SubmitInputResult({
    required this.rawInputId,
    required this.aiParseResultId,
    required this.parseResult,
  });

  final String rawInputId;
  final String aiParseResultId;
  final ParseResult parseResult;
}

class ExtractedItemsController {
  ExtractedItemsController({
    required this.database,
    required this.parserClient,
    String Function()? rawInputIdFactory,
    String Function()? parseResultIdFactory,
    DateTime Function()? nowProvider,
  })  : rawInputIdFactory = rawInputIdFactory ?? const Uuid().v4,
        parseResultIdFactory = parseResultIdFactory ?? const Uuid().v4,
        nowProvider = nowProvider ?? DateTime.now;

  final db.AppDatabase database;
  final ParserClient parserClient;
  final String Function() rawInputIdFactory;
  final String Function() parseResultIdFactory;
  final DateTime Function() nowProvider;

  Future<SubmitInputResult> submitInput(String text) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      throw const ParserFailure(
        code: 'empty_input',
        userMessage: '请先输入你想整理的内容。',
      );
    }

    final now = nowProvider();
    final rawInputId = rawInputIdFactory();
    final aiParseResultId = parseResultIdFactory();

    await database.into(database.rawInputs).insert(
          db.RawInputsCompanion.insert(
            id: rawInputId,
            inputText: trimmedText,
            createdAt: now,
          ),
        );

    try {
      final parseResult = await parserClient.parseInput(trimmedText);

      await database.transaction(() async {
        await database.into(database.aiParseResults).insert(
              db.AiParseResultsCompanion.insert(
                id: aiParseResultId,
                rawInputId: rawInputId,
                rawJson: jsonEncode(_parseResultToJson(parseResult)),
                validationState: 'valid',
                createdAt: now,
              ),
            );

        for (final (index, item) in parseResult.items.indexed) {
          await database.into(database.extractedItems).insert(
                _toCompanion(
                  item: item,
                  index: index,
                  rawInputId: rawInputId,
                  aiParseResultId: aiParseResultId,
                  now: now,
                ),
              );
        }
      });

      return SubmitInputResult(
        rawInputId: rawInputId,
        aiParseResultId: aiParseResultId,
        parseResult: parseResult,
      );
    } on ParserFailure catch (error) {
      await _recordParseFailure(
        id: aiParseResultId,
        rawInputId: rawInputId,
        error: error,
        now: now,
      );
      rethrow;
    } catch (_) {
      await _recordParseFailure(
        id: aiParseResultId,
        rawInputId: rawInputId,
        error: const ParserFailure(
          code: 'submit_failed',
          userMessage: '整理失败，请稍后再试。',
        ),
        now: now,
      );
      throw const ParserFailure(
        code: 'submit_failed',
        userMessage: '整理失败，请稍后再试。',
      );
    }
  }

  Future<void> _recordParseFailure({
    required String id,
    required String rawInputId,
    required ParserFailure error,
    required DateTime now,
  }) {
    return database.into(database.aiParseResults).insert(
          db.AiParseResultsCompanion.insert(
            id: id,
            rawInputId: rawInputId,
            rawJson: '{}',
            validationState: 'error',
            errorMessage: Value(error.code),
            createdAt: now,
          ),
        );
  }

  db.ExtractedItemsCompanion _toCompanion({
    required ExtractedItem item,
    required int index,
    required String rawInputId,
    required String aiParseResultId,
    required DateTime now,
  }) {
    return db.ExtractedItemsCompanion.insert(
      id: '$rawInputId:$index',
      rawInputId: rawInputId,
      aiParseResultId: aiParseResultId,
      type: item.type.apiValue,
      title: Value(item.title),
      content: Value(item.content),
      sourceText: item.sourceText,
      tagsJson: Value(jsonEncode(item.tags)),
      confidence: item.confidence,
      needUserConfirm: item.needUserConfirm,
      status: RecordStatus.pending.value,
      expiresAt: Value(item.expiresAt),
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, Object?> _parseResultToJson(ParseResult result) {
    return {
      'user_reply': result.userReply,
      'input_summary': result.inputSummary,
      'intent_types': [
        for (final type in result.intentTypes) type.apiValue,
      ],
      'items': [
        for (final item in result.items) _itemToJson(item),
      ],
    };
  }

  Map<String, Object?> _itemToJson(ExtractedItem item) {
    return {
      'type': item.type.apiValue,
      'title': item.title,
      'content': item.content,
      'source_text': item.sourceText,
      'tags': item.tags,
      'confidence': item.confidence,
      'need_user_confirm': item.needUserConfirm,
      'expires_at': item.expiresAt?.toIso8601String(),
    };
  }
}
