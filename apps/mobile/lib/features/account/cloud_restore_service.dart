import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/local_db/app_database.dart';

typedef CloudBackupRow = Map<String, Object?>;

class CloudRestorePreview {
  const CloudRestorePreview({
    required this.rawInputCount,
    required this.aiParseResultCount,
    required this.extractedItemCount,
    required this.taskCount,
    required this.shortTermStateCount,
    required this.lifeEventCount,
    required this.profileItemCount,
    required this.summaryCount,
    required this.summarySourceCount,
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

  int get totalCount =>
      rawInputCount +
      aiParseResultCount +
      extractedItemCount +
      taskCount +
      shortTermStateCount +
      lifeEventCount +
      profileItemCount +
      summaryCount +
      summarySourceCount;
}

class CloudRestoreResult {
  const CloudRestoreResult({
    required this.preview,
    required this.restoredCount,
    required this.preservedLocalCount,
  });

  final CloudRestorePreview preview;
  final int restoredCount;
  final int preservedLocalCount;
}

class CloudBackupSnapshot {
  const CloudBackupSnapshot({
    this.rawInputs = const [],
    this.aiParseResults = const [],
    this.extractedItems = const [],
    this.tasks = const [],
    this.shortTermStates = const [],
    this.lifeEvents = const [],
    this.profileItems = const [],
    this.summaries = const [],
    this.summarySources = const [],
  });

  final List<CloudBackupRow> rawInputs;
  final List<CloudBackupRow> aiParseResults;
  final List<CloudBackupRow> extractedItems;
  final List<CloudBackupRow> tasks;
  final List<CloudBackupRow> shortTermStates;
  final List<CloudBackupRow> lifeEvents;
  final List<CloudBackupRow> profileItems;
  final List<CloudBackupRow> summaries;
  final List<CloudBackupRow> summarySources;

  CloudRestorePreview get preview => CloudRestorePreview(
    rawInputCount: rawInputs.length,
    aiParseResultCount: aiParseResults.length,
    extractedItemCount: extractedItems.length,
    taskCount: tasks.length,
    shortTermStateCount: shortTermStates.length,
    lifeEventCount: lifeEvents.length,
    profileItemCount: profileItems.length,
    summaryCount: summaries.length,
    summarySourceCount: summarySources.length,
  );
}

class CloudBackupImportException implements Exception {
  const CloudBackupImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudBackupImporter {
  const CloudBackupImporter();

  Future<CloudRestoreResult> restore({
    required AppDatabase database,
    required CloudBackupSnapshot snapshot,
  }) async {
    _validateReferences(snapshot);

    final existingRawInputs = {
      for (final row in await database.select(database.rawInputs).get())
        row.id: row,
    };
    final existingParseResults = {
      for (final row in await database.select(database.aiParseResults).get())
        row.id: row,
    };
    final existingExtractedItems = {
      for (final row in await database.select(database.extractedItems).get())
        row.id: row,
    };
    final existingTasks = {
      for (final row in await database.select(database.tasks).get())
        row.id: row,
    };
    final existingStates = {
      for (final row in await database.select(database.shortTermStates).get())
        row.id: row,
    };
    final existingEvents = {
      for (final row in await database.select(database.lifeEvents).get())
        row.id: row,
    };
    final existingProfiles = {
      for (final row in await database.select(database.profileItems).get())
        row.id: row,
    };
    final existingSummaries = {
      for (final row in await database.select(database.summaries).get())
        row.id: row,
    };
    final existingSummarySources = {
      for (final row in await database.select(database.summarySources).get())
        row.id: row,
    };

    var preservedLocalCount = 0;

    final rawInputs = <RawInputsCompanion>[];
    for (final row in snapshot.rawInputs) {
      final id = _requiredString(row, 'id');
      if (existingRawInputs.containsKey(id)) {
        preservedLocalCount += 1;
        continue;
      }
      rawInputs.add(
        RawInputsCompanion.insert(
          id: id,
          inputText: _requiredString(row, 'text'),
          source: Value(_nullableString(row, 'source') ?? 'user'),
          createdAt: _requiredDate(row, 'created_at'),
        ),
      );
    }

    final parseResults = <AiParseResultsCompanion>[];
    for (final row in snapshot.aiParseResults) {
      final id = _requiredString(row, 'id');
      if (existingParseResults.containsKey(id)) {
        preservedLocalCount += 1;
        continue;
      }
      parseResults.add(
        AiParseResultsCompanion.insert(
          id: id,
          rawInputId: _requiredString(row, 'raw_input_id'),
          rawJson: _jsonString(row['raw_json'], const {}),
          validationState: _requiredString(row, 'validation_state'),
          errorMessage: Value(_nullableString(row, 'error_message')),
          retryCount: Value(_integer(row, 'retry_count', fallback: 0)),
          createdAt: _requiredDate(row, 'created_at'),
        ),
      );
    }

    final extractedItems = <ExtractedItemsCompanion>[];
    for (final row in snapshot.extractedItems) {
      final id = _requiredString(row, 'id');
      final cloudUpdatedAt = _requiredDate(row, 'updated_at');
      final existing = existingExtractedItems[id];
      if (existing != null && !cloudUpdatedAt.isAfter(existing.updatedAt)) {
        preservedLocalCount += 1;
        continue;
      }
      extractedItems.add(
        ExtractedItemsCompanion.insert(
          id: id,
          rawInputId: _requiredString(row, 'raw_input_id'),
          aiParseResultId: _requiredString(row, 'ai_parse_result_id'),
          type: _requiredString(row, 'type'),
          title: Value(_nullableString(row, 'title')),
          content: Value(_nullableString(row, 'content')),
          sourceText: _requiredString(row, 'source_text'),
          tagsJson: Value(_jsonString(row['tags'], const [])),
          confidence: _number(row, 'confidence'),
          needUserConfirm: _boolean(row, 'need_user_confirm'),
          status: _requiredString(row, 'status'),
          expiresAt: Value(_nullableDate(row, 'expires_at')),
          createdAt: _requiredDate(row, 'created_at'),
          updatedAt: cloudUpdatedAt,
        ),
      );
    }

    final tasks = <TasksCompanion>[];
    for (final row in snapshot.tasks) {
      final id = _requiredString(row, 'id');
      final cloudUpdatedAt = _requiredDate(row, 'updated_at');
      final existing = existingTasks[id];
      if (existing != null && !cloudUpdatedAt.isAfter(existing.updatedAt)) {
        preservedLocalCount += 1;
        continue;
      }
      tasks.add(
        TasksCompanion.insert(
          id: id,
          sourceRawInputId: _requiredString(row, 'source_raw_input_id'),
          sourceExtractedItemId: _requiredString(
            row,
            'source_extracted_item_id',
          ),
          title: _requiredString(row, 'title'),
          description: Value(_nullableString(row, 'description')),
          dueTimeText: Value(_nullableString(row, 'due_time_text')),
          dueTime: Value(_nullableDate(row, 'due_time')),
          priority: Value(_nullableString(row, 'priority') ?? 'medium'),
          status: _requiredString(row, 'status'),
          taskStatus: Value(_nullableString(row, 'task_status') ?? 'active'),
          createdAt: _requiredDate(row, 'created_at'),
          updatedAt: cloudUpdatedAt,
        ),
      );
    }

    final states = <ShortTermStatesCompanion>[];
    for (final row in snapshot.shortTermStates) {
      final id = _requiredString(row, 'id');
      final cloudUpdatedAt = _requiredDate(row, 'updated_at');
      final existing = existingStates[id];
      if (existing != null && !cloudUpdatedAt.isAfter(existing.updatedAt)) {
        preservedLocalCount += 1;
        continue;
      }
      states.add(
        ShortTermStatesCompanion.insert(
          id: id,
          sourceRawInputId: _requiredString(row, 'source_raw_input_id'),
          sourceExtractedItemId: _requiredString(
            row,
            'source_extracted_item_id',
          ),
          content: _requiredString(row, 'content'),
          tagsJson: Value(_jsonString(row['tags'], const [])),
          validUntil: _requiredDate(row, 'valid_until'),
          status: _requiredString(row, 'status'),
          createdAt: _requiredDate(row, 'created_at'),
          updatedAt: cloudUpdatedAt,
        ),
      );
    }

    final events = <LifeEventsCompanion>[];
    for (final row in snapshot.lifeEvents) {
      final id = _requiredString(row, 'id');
      final cloudUpdatedAt = _requiredDate(row, 'updated_at');
      final existing = existingEvents[id];
      if (existing != null && !cloudUpdatedAt.isAfter(existing.updatedAt)) {
        preservedLocalCount += 1;
        continue;
      }
      events.add(
        LifeEventsCompanion.insert(
          id: id,
          sourceRawInputId: _requiredString(row, 'source_raw_input_id'),
          sourceExtractedItemId: _requiredString(
            row,
            'source_extracted_item_id',
          ),
          content: _requiredString(row, 'content'),
          tagsJson: Value(_jsonString(row['tags'], const [])),
          status: _requiredString(row, 'status'),
          createdAt: _requiredDate(row, 'created_at'),
          updatedAt: cloudUpdatedAt,
        ),
      );
    }

    final profiles = <ProfileItemsCompanion>[];
    for (final row in snapshot.profileItems) {
      final id = _requiredString(row, 'id');
      final cloudUpdatedAt = _requiredDate(row, 'updated_at');
      final existing = existingProfiles[id];
      if (existing != null && !cloudUpdatedAt.isAfter(existing.updatedAt)) {
        preservedLocalCount += 1;
        continue;
      }
      profiles.add(
        ProfileItemsCompanion.insert(
          id: id,
          sourceRawInputId: _requiredString(row, 'source_raw_input_id'),
          sourceExtractedItemId: _requiredString(
            row,
            'source_extracted_item_id',
          ),
          content: _requiredString(row, 'content'),
          category: Value(_nullableString(row, 'category')),
          tagsJson: Value(_jsonString(row['tags'], const [])),
          confidence: _number(row, 'confidence'),
          status: _requiredString(row, 'status'),
          createdAt: _requiredDate(row, 'created_at'),
          updatedAt: cloudUpdatedAt,
        ),
      );
    }

    final summaries = <SummariesCompanion>[];
    for (final row in snapshot.summaries) {
      final id = _requiredString(row, 'id');
      final cloudUpdatedAt = _requiredDate(row, 'updated_at');
      final existing = existingSummaries[id];
      if (existing != null && !cloudUpdatedAt.isAfter(existing.updatedAt)) {
        preservedLocalCount += 1;
        continue;
      }
      summaries.add(
        SummariesCompanion.insert(
          id: id,
          summaryType: _requiredString(row, 'summary_type'),
          title: _requiredString(row, 'title'),
          content: _requiredString(row, 'content'),
          encouragement: Value(_nullableString(row, 'encouragement')),
          improvementNotes: Value(_nullableString(row, 'improvement_notes')),
          taskGuidance: Value(_nullableString(row, 'task_guidance')),
          openItemsJson: Value(_jsonString(row['open_items'], const [])),
          timeRangeStart: _requiredDate(row, 'time_range_start'),
          timeRangeEnd: _requiredDate(row, 'time_range_end'),
          status: _requiredString(row, 'status'),
          generatedBy: _requiredString(row, 'generated_by'),
          modelName: Value(_nullableString(row, 'model_name')),
          promptVersion: Value(_nullableString(row, 'prompt_version')),
          confidence: Value(_nullableNumber(row, 'confidence')),
          createdAt: _requiredDate(row, 'created_at'),
          updatedAt: cloudUpdatedAt,
          userEditedAt: Value(_nullableDate(row, 'user_edited_at')),
          deletedAt: Value(_nullableDate(row, 'deleted_at')),
        ),
      );
    }

    final summarySources = <SummarySourcesCompanion>[];
    for (final row in snapshot.summarySources) {
      final id = _requiredString(row, 'id');
      if (existingSummarySources.containsKey(id)) {
        preservedLocalCount += 1;
        continue;
      }
      summarySources.add(
        SummarySourcesCompanion.insert(
          id: id,
          summaryId: _requiredString(row, 'summary_id'),
          sourceTable: _requiredString(row, 'source_table'),
          sourceRecordId: _requiredString(row, 'source_record_id'),
          sourceStatusAtGeneration: Value(
            _nullableString(row, 'source_status_at_generation'),
          ),
          createdAt: _requiredDate(row, 'created_at'),
        ),
      );
    }

    await database.transaction(() async {
      await database.batch((batch) {
        if (rawInputs.isNotEmpty) {
          batch.insertAllOnConflictUpdate(database.rawInputs, rawInputs);
        }
        if (parseResults.isNotEmpty) {
          batch.insertAllOnConflictUpdate(
            database.aiParseResults,
            parseResults,
          );
        }
        if (extractedItems.isNotEmpty) {
          batch.insertAllOnConflictUpdate(
            database.extractedItems,
            extractedItems,
          );
        }
        if (tasks.isNotEmpty) {
          batch.insertAllOnConflictUpdate(database.tasks, tasks);
        }
        if (states.isNotEmpty) {
          batch.insertAllOnConflictUpdate(database.shortTermStates, states);
        }
        if (events.isNotEmpty) {
          batch.insertAllOnConflictUpdate(database.lifeEvents, events);
        }
        if (profiles.isNotEmpty) {
          batch.insertAllOnConflictUpdate(database.profileItems, profiles);
        }
        if (summaries.isNotEmpty) {
          batch.insertAllOnConflictUpdate(database.summaries, summaries);
        }
        if (summarySources.isNotEmpty) {
          batch.insertAllOnConflictUpdate(
            database.summarySources,
            summarySources,
          );
        }
      });
    });

    final restoredCount =
        rawInputs.length +
        parseResults.length +
        extractedItems.length +
        tasks.length +
        states.length +
        events.length +
        profiles.length +
        summaries.length +
        summarySources.length;

    return CloudRestoreResult(
      preview: snapshot.preview,
      restoredCount: restoredCount,
      preservedLocalCount: preservedLocalCount,
    );
  }

  void _validateReferences(CloudBackupSnapshot snapshot) {
    final rawIds = _requiredIds(snapshot.rawInputs).toSet();
    final parseById = {
      for (final row in snapshot.aiParseResults)
        _requiredString(row, 'id'): row,
    };
    final extractedById = {
      for (final row in snapshot.extractedItems)
        _requiredString(row, 'id'): row,
    };
    final summaryIds = _requiredIds(snapshot.summaries).toSet();

    for (final row in snapshot.aiParseResults) {
      _requireReference(
        rawIds.contains(_requiredString(row, 'raw_input_id')),
        'ai_parse_results references a missing raw input',
      );
    }

    for (final row in snapshot.extractedItems) {
      final rawInputId = _requiredString(row, 'raw_input_id');
      final parseResultId = _requiredString(row, 'ai_parse_result_id');
      final parseResult = parseById[parseResultId];
      _requireReference(
        rawIds.contains(rawInputId) &&
            parseResult != null &&
            _requiredString(parseResult, 'raw_input_id') == rawInputId,
        'extracted_items references inconsistent source rows',
      );
    }

    for (final row in [
      ...snapshot.tasks,
      ...snapshot.shortTermStates,
      ...snapshot.lifeEvents,
      ...snapshot.profileItems,
    ]) {
      final rawInputId = _requiredString(row, 'source_raw_input_id');
      final extractedItemId = _requiredString(row, 'source_extracted_item_id');
      final extractedItem = extractedById[extractedItemId];
      _requireReference(
        rawIds.contains(rawInputId) &&
            extractedItem != null &&
            _requiredString(extractedItem, 'raw_input_id') == rawInputId,
        'memory record references inconsistent source rows',
      );
    }

    for (final row in snapshot.summarySources) {
      _requireReference(
        summaryIds.contains(_requiredString(row, 'summary_id')),
        'summary source references a missing summary',
      );
    }
  }

  Iterable<String> _requiredIds(List<CloudBackupRow> rows) sync* {
    for (final row in rows) {
      yield _requiredString(row, 'id');
    }
  }

  void _requireReference(bool condition, String message) {
    if (!condition) throw CloudBackupImportException(message);
  }

  String _requiredString(CloudBackupRow row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw CloudBackupImportException('Cloud field $key must be a string.');
  }

  String? _nullableString(CloudBackupRow row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is String) return value;
    throw CloudBackupImportException('Cloud field $key must be a string.');
  }

  DateTime _requiredDate(CloudBackupRow row, String key) {
    final value = _nullableDate(row, key);
    if (value != null) return value;
    throw CloudBackupImportException('Cloud field $key must be a date.');
  }

  DateTime? _nullableDate(CloudBackupRow row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is! String) {
      throw CloudBackupImportException('Cloud field $key must be a date.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw CloudBackupImportException('Cloud field $key must be a date.');
    }
    return parsed.toLocal();
  }

  double _number(CloudBackupRow row, String key) {
    final value = row[key];
    if (value is num) return value.toDouble();
    throw CloudBackupImportException('Cloud field $key must be a number.');
  }

  double? _nullableNumber(CloudBackupRow row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw CloudBackupImportException('Cloud field $key must be a number.');
  }

  int _integer(CloudBackupRow row, String key, {required int fallback}) {
    final value = row[key];
    if (value == null) return fallback;
    if (value is int) return value;
    throw CloudBackupImportException('Cloud field $key must be an integer.');
  }

  bool _boolean(CloudBackupRow row, String key) {
    final value = row[key];
    if (value is bool) return value;
    throw CloudBackupImportException('Cloud field $key must be a boolean.');
  }

  String _jsonString(Object? value, Object fallback) {
    if (value == null) return jsonEncode(fallback);
    if (value is String) {
      try {
        jsonDecode(value);
        return value;
      } on FormatException {
        throw const CloudBackupImportException(
          'Cloud JSON field is not valid JSON.',
        );
      }
    }
    return jsonEncode(value);
  }
}
