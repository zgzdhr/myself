import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local_db/app_database.dart';
import 'cloud_auth_service.dart';
import 'cloud_restore_service.dart';

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

  Future<CloudRestorePreview> previewCloudRestore();

  Future<CloudRestoreResult> restoreFromCloud(AppDatabase database);

  /// Removes the signed-in user's cloud copy only. Local SQLite records stay
  /// on the device, so the user can choose to sync again later.
  Future<void> deleteCloudCopy();
}

class DisabledCloudSyncService extends CloudSyncService {
  const DisabledCloudSyncService();

  @override
  Future<CloudSyncResult> syncFromLocal(AppDatabase database) {
    throw const CloudAuthNotConfiguredException();
  }

  @override
  Future<CloudRestorePreview> previewCloudRestore() {
    throw const CloudAuthNotConfiguredException();
  }

  @override
  Future<CloudRestoreResult> restoreFromCloud(AppDatabase database) {
    throw const CloudAuthNotConfiguredException();
  }

  @override
  Future<void> deleteCloudCopy() {
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
          // 5D.1 calendar, recurrence, and sedentary data are intentionally
          // local-only. A task carrying an explicit local schedule must not
          // leak that schedule through the legacy due-time cloud fields.
          'due_time_text': _cloudDueTimeText(row),
          'due_time': _cloudDueTime(row),
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
      schedulePlanCount: 0,
      scheduleBlockCount: 0,
      scheduleBlockSourceCount: 0,
    );
  }

  @override
  Future<CloudRestorePreview> previewCloudRestore() async {
    _requireSignedInUser();
    return (await _downloadCloudSnapshot()).preview;
  }

  @override
  Future<CloudRestoreResult> restoreFromCloud(AppDatabase database) async {
    _requireSignedInUser();
    final snapshot = await _downloadCloudSnapshot();
    return const CloudBackupImporter().restore(
      database: database,
      snapshot: snapshot,
    );
  }

  @override
  Future<void> deleteCloudCopy() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const CloudAuthNotSignedInException();
    }

    // Delete dependents before their sources so the operation works with the
    // documented foreign keys. Calendar tables are included to remove a copy
    // written by an older build, even though current calendar data is local.
    for (final table in const [
      'schedule_block_sources',
      'schedule_blocks',
      'schedule_plans',
      'summary_sources',
      'summaries',
      'profile_items',
      'life_events',
      'short_term_states',
      'tasks',
      'extracted_items',
      'ai_parse_results',
      'raw_inputs',
      'profiles',
    ]) {
      await _client.from(table).delete().eq('user_id', user.id);
    }
  }

  User _requireSignedInUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const CloudAuthNotSignedInException();
    }
    return user;
  }

  Future<CloudBackupSnapshot> _downloadCloudSnapshot() async {
    final tables = await Future.wait([
      _selectCloudRows('raw_inputs'),
      _selectCloudRows('ai_parse_results'),
      _selectCloudRows('extracted_items'),
      _selectCloudRows('tasks'),
      _selectCloudRows('short_term_states'),
      _selectCloudRows('life_events'),
      _selectCloudRows('profile_items'),
      _selectCloudRows('summaries'),
      _selectCloudRows('summary_sources'),
    ]);

    return CloudBackupSnapshot(
      rawInputs: tables[0],
      aiParseResults: tables[1],
      extractedItems: tables[2],
      tasks: tables[3],
      shortTermStates: tables[4],
      lifeEvents: tables[5],
      profileItems: tables[6],
      summaries: tables[7],
      summarySources: tables[8],
    );
  }

  Future<List<CloudBackupRow>> _selectCloudRows(String table) async {
    const pageSize = 500;
    const maxRowsPerTable = 50_000;
    final result = <CloudBackupRow>[];

    while (true) {
      final rows = await _client
          .from(table)
          .select()
          .order('id')
          .range(result.length, result.length + pageSize - 1);
      result.addAll([
        for (final row in rows) Map<String, Object?>.from(row),
      ]);

      if (result.length > maxRowsPerTable) {
        throw const CloudBackupImportException(
          'Cloud backup exceeds the private-trial restore limit.',
        );
      }
      if (rows.length < pageSize) return result;
    }
  }

  Future<void> _upsert(String table, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return;
    const batchSize = 250;
    for (var offset = 0; offset < rows.length; offset += batchSize) {
      final end = (offset + batchSize < rows.length)
          ? offset + batchSize
          : rows.length;
      await _client.from(table).upsert(
        rows.sublist(offset, end),
        onConflict: 'id',
      );
    }
  }

  static String _date(DateTime value) => value.toUtc().toIso8601String();

  static String? _dateOrNull(DateTime? value) {
    if (value == null) return null;
    return _date(value);
  }

  static bool _hasLocalOnlySchedule(Task row) {
    return row.startTime != null ||
        row.endTime != null ||
        row.recurrenceRuleId != null ||
        row.recurrenceDate != null;
  }

  static String? _cloudDueTimeText(Task row) {
    return _hasLocalOnlySchedule(row) ? null : row.dueTimeText;
  }

  static String? _cloudDueTime(Task row) {
    return _hasLocalOnlySchedule(row) ? null : _dateOrNull(row.dueTime);
  }

  static Object? _json(String value, {required Object fallback}) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return fallback;
    }
  }
}
