import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local_db/app_database.dart';
import 'cloud_auth_service.dart';

class CloudSyncResult {
  const CloudSyncResult({
    required this.rawInputCount,
    required this.aiParseResultCount,
    required this.extractedItemCount,
    required this.taskCount,
    required this.shortTermStateCount,
    required this.lifeEventCount,
    required this.profileItemCount,
    required this.summaryCount,
    required this.summarySourceCount,
    required this.schedulePlanCount,
    required this.scheduleBlockCount,
    required this.scheduleBlockSourceCount,
  });

  final int rawInputCount;
  final int aiParseResultCount;
  final int extractedItemCount;
  final int taskCount;
  final int shortTermStateCount;
  final int lifeEventCount;
  final int profileItemCount;
  final int summaryCount;
  final int summarySourceCount;
  final int schedulePlanCount;
  final int scheduleBlockCount;
  final int scheduleBlockSourceCount;

  int get totalCount =>
      rawInputCount +
      aiParseResultCount +
      extractedItemCount +
      taskCount +
      shortTermStateCount +
      lifeEventCount +
      profileItemCount +
      summaryCount +
      summarySourceCount +
      schedulePlanCount +
      scheduleBlockCount +
      scheduleBlockSourceCount;
}

abstract class CloudSyncService {
  const CloudSyncService();

  Future<CloudSyncResult> syncFromLocal(AppDatabase database);
}

class DisabledCloudSyncService extends CloudSyncService {
  const DisabledCloudSyncService();

  @override
  Future<CloudSyncResult> syncFromLocal(AppDatabase database) {
    throw const CloudAuthNotConfiguredException();
  }
}

class SupabaseCloudSyncService extends CloudSyncService {
  const SupabaseCloudSyncService(this._client);

  final SupabaseClient _client;

  @override
  Future<CloudSyncResult> syncFromLocal(AppDatabase database) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const CloudAuthNotSignedInException();
    }

    final userId = user.id;
    final rawInputs = await database.select(database.rawInputs).get();
    final aiParseResults = await database.select(database.aiParseResults).get();
    final extractedItems = await database.select(database.extractedItems).get();
    final tasks = await database.select(database.tasks).get();
    final shortTermStates = await database
        .select(database.shortTermStates)
        .get();
    final lifeEvents = await database.select(database.lifeEvents).get();
    final profileItems = await database.select(database.profileItems).get();
    final summaries = await database.select(database.summaries).get();
    final summarySources = await database.select(database.summarySources).get();
    final schedulePlans = await database.select(database.schedulePlans).get();
    final scheduleBlocks = await database.select(database.scheduleBlocks).get();
    final scheduleBlockSources = await database
        .select(database.scheduleBlockSources)
        .get();

    await _upsert('raw_inputs', [
      for (final row in rawInputs)
        {
          'id': row.id,
          'user_id': userId,
          'text': row.inputText,
          'source': row.source,
          'created_at': _date(row.createdAt),
        },
    ]);

    await _upsert('ai_parse_results', [
      for (final row in aiParseResults)
        {
          'id': row.id,
          'user_id': userId,
          'raw_input_id': row.rawInputId,
          'raw_json': _json(row.rawJson, fallback: const {}),
          'validation_state': row.validationState,
          'error_message': row.errorMessage,
          'retry_count': row.retryCount,
          'created_at': _date(row.createdAt),
        },
    ]);

    await _upsert('extracted_items', [
      for (final row in extractedItems)
        {
          'id': row.id,
          'user_id': userId,
          'raw_input_id': row.rawInputId,
          'ai_parse_result_id': row.aiParseResultId,
          'type': row.type,
          'title': row.title,
          'content': row.content,
          'source_text': row.sourceText,
          'tags': _json(row.tagsJson, fallback: const []),
          'confidence': row.confidence,
          'need_user_confirm': row.needUserConfirm,
          'status': row.status,
          'expires_at': _dateOrNull(row.expiresAt),
          'created_at': _date(row.createdAt),
          'updated_at': _date(row.updatedAt),
        },
    ]);

    await _upsert('tasks', [
      for (final row in tasks)
        {
          'id': row.id,
          'user_id': userId,
          'source_raw_input_id': row.sourceRawInputId,
          'source_extracted_item_id': row.sourceExtractedItemId,
          'title': row.title,
          'description': row.description,
          'due_time_text': row.dueTimeText,
          'due_time': _dateOrNull(row.dueTime),
          'priority': row.priority,
          'status': row.status,
          'task_status': row.taskStatus,
          'created_at': _date(row.createdAt),
          'updated_at': _date(row.updatedAt),
        },
    ]);

    await _upsert('short_term_states', [
      for (final row in shortTermStates)
        {
          'id': row.id,
          'user_id': userId,
          'source_raw_input_id': row.sourceRawInputId,
          'source_extracted_item_id': row.sourceExtractedItemId,
          'content': row.content,
          'tags': _json(row.tagsJson, fallback: const []),
          'valid_until': _date(row.validUntil),
          'status': row.status,
          'created_at': _date(row.createdAt),
          'updated_at': _date(row.updatedAt),
        },
    ]);

    await _upsert('life_events', [
      for (final row in lifeEvents)
        {
          'id': row.id,
          'user_id': userId,
          'source_raw_input_id': row.sourceRawInputId,
          'source_extracted_item_id': row.sourceExtractedItemId,
          'content': row.content,
          'tags': _json(row.tagsJson, fallback: const []),
          'status': row.status,
          'created_at': _date(row.createdAt),
          'updated_at': _date(row.updatedAt),
        },
    ]);

    await _upsert('profile_items', [
      for (final row in profileItems)
        {
          'id': row.id,
          'user_id': userId,
          'source_raw_input_id': row.sourceRawInputId,
          'source_extracted_item_id': row.sourceExtractedItemId,
          'content': row.content,
          'category': row.category,
          'tags': _json(row.tagsJson, fallback: const []),
          'confidence': row.confidence,
          'status': row.status,
          'created_at': _date(row.createdAt),
          'updated_at': _date(row.updatedAt),
        },
    ]);

    await _upsert('summaries', [
      for (final row in summaries)
        {
          'id': row.id,
          'user_id': userId,
          'summary_type': row.summaryType,
          'title': row.title,
          'content': row.content,
          'encouragement': row.encouragement,
          'improvement_notes': row.improvementNotes,
          'task_guidance': row.taskGuidance,
          'open_items': _json(row.openItemsJson, fallback: const []),
          'time_range_start': _date(row.timeRangeStart),
          'time_range_end': _date(row.timeRangeEnd),
          'status': row.status,
          'generated_by': row.generatedBy,
          'model_name': row.modelName,
          'prompt_version': row.promptVersion,
          'confidence': row.confidence,
          'created_at': _date(row.createdAt),
          'updated_at': _date(row.updatedAt),
          'user_edited_at': _dateOrNull(row.userEditedAt),
          'deleted_at': _dateOrNull(row.deletedAt),
        },
    ]);

    await _upsert('summary_sources', [
      for (final row in summarySources)
        {
          'id': row.id,
          'user_id': userId,
          'summary_id': row.summaryId,
          'source_table': row.sourceTable,
          'source_record_id': row.sourceRecordId,
          'source_status_at_generation': row.sourceStatusAtGeneration,
          'created_at': _date(row.createdAt),
        },
    ]);

    await _upsert('schedule_plans', [
      for (final row in schedulePlans)
        {
          'id': row.id,
          'user_id': userId,
          'plan_date': _date(row.planDate),
          'title': row.title,
          'overview': row.overview,
          'suggestions': _json(row.suggestionsJson, fallback: const []),
          'unscheduled_task_ids': _json(
            row.unscheduledTaskIdsJson,
            fallback: const [],
          ),
          'status': row.status,
          'generated_by': row.generatedBy,
          'model_name': row.modelName,
          'prompt_version': row.promptVersion,
          'confidence': row.confidence,
          'created_at': _date(row.createdAt),
          'updated_at': _date(row.updatedAt),
          'confirmed_at': _dateOrNull(row.confirmedAt),
          'user_edited_at': _dateOrNull(row.userEditedAt),
          'deleted_at': _dateOrNull(row.deletedAt),
        },
    ]);

    await _upsert('schedule_blocks', [
      for (final row in scheduleBlocks)
        {
          'id': row.id,
          'user_id': userId,
          'plan_id': row.planId,
          'title': row.title,
          'block_type': row.blockType,
          'start_time': _date(row.startTime),
          'end_time': _date(row.endTime),
          'task_id': row.taskId,
          'note': row.note,
          'reason': row.reason,
          'sort_order': row.sortOrder,
          'status': row.status,
          'confidence': row.confidence,
          'created_at': _date(row.createdAt),
          'updated_at': _date(row.updatedAt),
        },
    ]);

    await _upsert('schedule_block_sources', [
      for (final row in scheduleBlockSources)
        {
          'id': row.id,
          'user_id': userId,
          'block_id': row.blockId,
          'source_table': row.sourceTable,
          'source_record_id': row.sourceRecordId,
          'created_at': _date(row.createdAt),
        },
    ]);

    return CloudSyncResult(
      rawInputCount: rawInputs.length,
      aiParseResultCount: aiParseResults.length,
      extractedItemCount: extractedItems.length,
      taskCount: tasks.length,
      shortTermStateCount: shortTermStates.length,
      lifeEventCount: lifeEvents.length,
      profileItemCount: profileItems.length,
      summaryCount: summaries.length,
      summarySourceCount: summarySources.length,
      schedulePlanCount: schedulePlans.length,
      scheduleBlockCount: scheduleBlocks.length,
      scheduleBlockSourceCount: scheduleBlockSources.length,
    );
  }

  Future<void> _upsert(String table, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return;
    await _client.from(table).upsert(rows, onConflict: 'id');
  }

  static String _date(DateTime value) => value.toUtc().toIso8601String();

  static String? _dateOrNull(DateTime? value) {
    if (value == null) return null;
    return _date(value);
  }

  static Object? _json(String value, {required Object fallback}) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return fallback;
    }
  }
}
