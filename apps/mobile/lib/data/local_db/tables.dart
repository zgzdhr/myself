import 'package:drift/drift.dart';

class RawInputs extends Table {
  TextColumn get id => text()();
  TextColumn get inputText => text().named('text')();
  TextColumn get source => text().withDefault(const Constant('user'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class AiParseResults extends Table {
  TextColumn get id => text()();
  TextColumn get rawInputId => text().references(RawInputs, #id)();
  TextColumn get rawJson => text()();
  TextColumn get validationState => text()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExtractedItems extends Table {
  TextColumn get id => text()();
  TextColumn get rawInputId => text().references(RawInputs, #id)();
  TextColumn get aiParseResultId => text().references(AiParseResults, #id)();
  TextColumn get type => text()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text().nullable()();
  TextColumn get sourceText => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  RealColumn get confidence => real()();
  BoolColumn get needUserConfirm => boolean()();
  TextColumn get status => text()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get sourceRawInputId => text().references(RawInputs, #id)();
  TextColumn get sourceExtractedItemId =>
      text().references(ExtractedItems, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime().named('start_time').nullable()();
  DateTimeColumn get endTime => dateTime().named('end_time').nullable()();
  TextColumn get dueTimeText => text().nullable()();
  DateTimeColumn get dueTime => dateTime().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text()();
  TextColumn get taskStatus =>
      text().named('task_status').withDefault(const Constant('active'))();
  TextColumn get recurrenceRuleId =>
      text().named('recurrence_rule_id').nullable()();
  DateTimeColumn get recurrenceDate =>
      dateTime().named('recurrence_date').nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecurringTaskRules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get endDate => dateTime().named('end_date').nullable()();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  TextColumn get status => text()();
  TextColumn get skippedDatesJson =>
      text().named('skipped_dates_json').withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get disabledAt => dateTime().named('disabled_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShortTermStates extends Table {
  TextColumn get id => text()();
  TextColumn get sourceRawInputId => text().references(RawInputs, #id)();
  TextColumn get sourceExtractedItemId =>
      text().references(ExtractedItems, #id)();
  TextColumn get content => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get validUntil => dateTime()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LifeEvents extends Table {
  TextColumn get id => text()();
  TextColumn get sourceRawInputId => text().references(RawInputs, #id)();
  TextColumn get sourceExtractedItemId =>
      text().references(ExtractedItems, #id)();
  TextColumn get content => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProfileItems extends Table {
  TextColumn get id => text()();
  TextColumn get sourceRawInputId => text().references(RawInputs, #id)();
  TextColumn get sourceExtractedItemId =>
      text().references(ExtractedItems, #id)();
  TextColumn get content => text()();
  TextColumn get category => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  RealColumn get confidence => real()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Summaries extends Table {
  TextColumn get id => text()();
  TextColumn get summaryType => text().named('summary_type')();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get encouragement => text().nullable()();
  TextColumn get improvementNotes =>
      text().named('improvement_notes').nullable()();
  TextColumn get taskGuidance => text().named('task_guidance').nullable()();
  TextColumn get openItemsJson =>
      text().named('open_items_json').withDefault(const Constant('[]'))();
  DateTimeColumn get timeRangeStart => dateTime().named('time_range_start')();
  DateTimeColumn get timeRangeEnd => dateTime().named('time_range_end')();
  TextColumn get status => text()();
  TextColumn get generatedBy => text().named('generated_by')();
  TextColumn get modelName => text().named('model_name').nullable()();
  TextColumn get promptVersion => text().named('prompt_version').nullable()();
  RealColumn get confidence => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get userEditedAt =>
      dateTime().named('user_edited_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SummarySources extends Table {
  TextColumn get id => text()();
  TextColumn get summaryId =>
      text().named('summary_id').references(Summaries, #id)();
  TextColumn get sourceTable => text().named('source_table')();
  TextColumn get sourceRecordId => text().named('source_record_id')();
  TextColumn get sourceStatusAtGeneration =>
      text().named('source_status_at_generation').nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SchedulePlans extends Table {
  TextColumn get id => text()();
  DateTimeColumn get planDate => dateTime().named('plan_date')();
  TextColumn get title => text()();
  TextColumn get overview => text()();
  TextColumn get suggestionsJson =>
      text().named('suggestions_json').withDefault(const Constant('[]'))();
  TextColumn get unscheduledTaskIdsJson => text()
      .named('unscheduled_task_ids_json')
      .withDefault(const Constant('[]'))();
  TextColumn get status => text()();
  TextColumn get generatedBy => text().named('generated_by')();
  TextColumn get modelName => text().named('model_name').nullable()();
  TextColumn get promptVersion => text().named('prompt_version').nullable()();
  RealColumn get confidence => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get confirmedAt =>
      dateTime().named('confirmed_at').nullable()();
  DateTimeColumn get userEditedAt =>
      dateTime().named('user_edited_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ScheduleBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get planId =>
      text().named('plan_id').references(SchedulePlans, #id)();
  TextColumn get title => text()();
  TextColumn get blockType => text().named('block_type')();
  DateTimeColumn get startTime => dateTime().named('start_time')();
  DateTimeColumn get endTime => dateTime().named('end_time')();
  TextColumn get taskId => text().named('task_id').nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get reason => text()();
  IntColumn get sortOrder => integer().named('sort_order')();
  TextColumn get status => text()();
  RealColumn get confidence => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ScheduleBlockSources extends Table {
  TextColumn get id => text()();
  TextColumn get blockId =>
      text().named('block_id').references(ScheduleBlocks, #id)();
  TextColumn get sourceTable => text().named('source_table')();
  TextColumn get sourceRecordId => text().named('source_record_id')();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SedentarySessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime().named('started_at')();
  DateTimeColumn get reminderAt => dateTime().named('reminder_at')();
  DateTimeColumn get endedAt => dateTime().named('ended_at').nullable()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
