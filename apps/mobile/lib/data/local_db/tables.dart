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
  TextColumn get dueTimeText => text().nullable()();
  DateTimeColumn get dueTime => dateTime().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

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
