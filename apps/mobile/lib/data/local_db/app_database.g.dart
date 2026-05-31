// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RawInputsTable extends RawInputs
    with TableInfo<$RawInputsTable, RawInput> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawInputsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputTextMeta = const VerificationMeta(
    'inputText',
  );
  @override
  late final GeneratedColumn<String> inputText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, inputText, source, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_inputs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RawInput> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _inputTextMeta,
        inputText.isAcceptableOrUnknown(data['text']!, _inputTextMeta),
      );
    } else if (isInserting) {
      context.missing(_inputTextMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RawInput map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawInput(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inputText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RawInputsTable createAlias(String alias) {
    return $RawInputsTable(attachedDatabase, alias);
  }
}

class RawInput extends DataClass implements Insertable<RawInput> {
  final String id;
  final String inputText;
  final String source;
  final DateTime createdAt;
  const RawInput({
    required this.id,
    required this.inputText,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text'] = Variable<String>(inputText);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RawInputsCompanion toCompanion(bool nullToAbsent) {
    return RawInputsCompanion(
      id: Value(id),
      inputText: Value(inputText),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory RawInput.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawInput(
      id: serializer.fromJson<String>(json['id']),
      inputText: serializer.fromJson<String>(json['inputText']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inputText': serializer.toJson<String>(inputText),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RawInput copyWith({
    String? id,
    String? inputText,
    String? source,
    DateTime? createdAt,
  }) => RawInput(
    id: id ?? this.id,
    inputText: inputText ?? this.inputText,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  RawInput copyWithCompanion(RawInputsCompanion data) {
    return RawInput(
      id: data.id.present ? data.id.value : this.id,
      inputText: data.inputText.present ? data.inputText.value : this.inputText,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawInput(')
          ..write('id: $id, ')
          ..write('inputText: $inputText, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, inputText, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawInput &&
          other.id == this.id &&
          other.inputText == this.inputText &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class RawInputsCompanion extends UpdateCompanion<RawInput> {
  final Value<String> id;
  final Value<String> inputText;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RawInputsCompanion({
    this.id = const Value.absent(),
    this.inputText = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RawInputsCompanion.insert({
    required String id,
    required String inputText,
    this.source = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inputText = Value(inputText),
       createdAt = Value(createdAt);
  static Insertable<RawInput> custom({
    Expression<String>? id,
    Expression<String>? inputText,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inputText != null) 'text': inputText,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RawInputsCompanion copyWith({
    Value<String>? id,
    Value<String>? inputText,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RawInputsCompanion(
      id: id ?? this.id,
      inputText: inputText ?? this.inputText,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inputText.present) {
      map['text'] = Variable<String>(inputText.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawInputsCompanion(')
          ..write('id: $id, ')
          ..write('inputText: $inputText, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiParseResultsTable extends AiParseResults
    with TableInfo<$AiParseResultsTable, AiParseResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiParseResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawInputIdMeta = const VerificationMeta(
    'rawInputId',
  );
  @override
  late final GeneratedColumn<String> rawInputId = GeneratedColumn<String>(
    'raw_input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES raw_inputs (id)',
    ),
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validationStateMeta = const VerificationMeta(
    'validationState',
  );
  @override
  late final GeneratedColumn<String> validationState = GeneratedColumn<String>(
    'validation_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawInputId,
    rawJson,
    validationState,
    errorMessage,
    retryCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_parse_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiParseResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('raw_input_id')) {
      context.handle(
        _rawInputIdMeta,
        rawInputId.isAcceptableOrUnknown(
          data['raw_input_id']!,
          _rawInputIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawInputIdMeta);
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('validation_state')) {
      context.handle(
        _validationStateMeta,
        validationState.isAcceptableOrUnknown(
          data['validation_state']!,
          _validationStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_validationStateMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiParseResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiParseResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rawInputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_input_id'],
      )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      validationState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validation_state'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AiParseResultsTable createAlias(String alias) {
    return $AiParseResultsTable(attachedDatabase, alias);
  }
}

class AiParseResult extends DataClass implements Insertable<AiParseResult> {
  final String id;
  final String rawInputId;
  final String rawJson;
  final String validationState;
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  const AiParseResult({
    required this.id,
    required this.rawInputId,
    required this.rawJson,
    required this.validationState,
    this.errorMessage,
    required this.retryCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['raw_input_id'] = Variable<String>(rawInputId);
    map['raw_json'] = Variable<String>(rawJson);
    map['validation_state'] = Variable<String>(validationState);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiParseResultsCompanion toCompanion(bool nullToAbsent) {
    return AiParseResultsCompanion(
      id: Value(id),
      rawInputId: Value(rawInputId),
      rawJson: Value(rawJson),
      validationState: Value(validationState),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory AiParseResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiParseResult(
      id: serializer.fromJson<String>(json['id']),
      rawInputId: serializer.fromJson<String>(json['rawInputId']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      validationState: serializer.fromJson<String>(json['validationState']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rawInputId': serializer.toJson<String>(rawInputId),
      'rawJson': serializer.toJson<String>(rawJson),
      'validationState': serializer.toJson<String>(validationState),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiParseResult copyWith({
    String? id,
    String? rawInputId,
    String? rawJson,
    String? validationState,
    Value<String?> errorMessage = const Value.absent(),
    int? retryCount,
    DateTime? createdAt,
  }) => AiParseResult(
    id: id ?? this.id,
    rawInputId: rawInputId ?? this.rawInputId,
    rawJson: rawJson ?? this.rawJson,
    validationState: validationState ?? this.validationState,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
  );
  AiParseResult copyWithCompanion(AiParseResultsCompanion data) {
    return AiParseResult(
      id: data.id.present ? data.id.value : this.id,
      rawInputId: data.rawInputId.present
          ? data.rawInputId.value
          : this.rawInputId,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      validationState: data.validationState.present
          ? data.validationState.value
          : this.validationState,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiParseResult(')
          ..write('id: $id, ')
          ..write('rawInputId: $rawInputId, ')
          ..write('rawJson: $rawJson, ')
          ..write('validationState: $validationState, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawInputId,
    rawJson,
    validationState,
    errorMessage,
    retryCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiParseResult &&
          other.id == this.id &&
          other.rawInputId == this.rawInputId &&
          other.rawJson == this.rawJson &&
          other.validationState == this.validationState &&
          other.errorMessage == this.errorMessage &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class AiParseResultsCompanion extends UpdateCompanion<AiParseResult> {
  final Value<String> id;
  final Value<String> rawInputId;
  final Value<String> rawJson;
  final Value<String> validationState;
  final Value<String?> errorMessage;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AiParseResultsCompanion({
    this.id = const Value.absent(),
    this.rawInputId = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.validationState = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiParseResultsCompanion.insert({
    required String id,
    required String rawInputId,
    required String rawJson,
    required String validationState,
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawInputId = Value(rawInputId),
       rawJson = Value(rawJson),
       validationState = Value(validationState),
       createdAt = Value(createdAt);
  static Insertable<AiParseResult> custom({
    Expression<String>? id,
    Expression<String>? rawInputId,
    Expression<String>? rawJson,
    Expression<String>? validationState,
    Expression<String>? errorMessage,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawInputId != null) 'raw_input_id': rawInputId,
      if (rawJson != null) 'raw_json': rawJson,
      if (validationState != null) 'validation_state': validationState,
      if (errorMessage != null) 'error_message': errorMessage,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiParseResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? rawInputId,
    Value<String>? rawJson,
    Value<String>? validationState,
    Value<String?>? errorMessage,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AiParseResultsCompanion(
      id: id ?? this.id,
      rawInputId: rawInputId ?? this.rawInputId,
      rawJson: rawJson ?? this.rawJson,
      validationState: validationState ?? this.validationState,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rawInputId.present) {
      map['raw_input_id'] = Variable<String>(rawInputId.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (validationState.present) {
      map['validation_state'] = Variable<String>(validationState.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiParseResultsCompanion(')
          ..write('id: $id, ')
          ..write('rawInputId: $rawInputId, ')
          ..write('rawJson: $rawJson, ')
          ..write('validationState: $validationState, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtractedItemsTable extends ExtractedItems
    with TableInfo<$ExtractedItemsTable, ExtractedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtractedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawInputIdMeta = const VerificationMeta(
    'rawInputId',
  );
  @override
  late final GeneratedColumn<String> rawInputId = GeneratedColumn<String>(
    'raw_input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES raw_inputs (id)',
    ),
  );
  static const VerificationMeta _aiParseResultIdMeta = const VerificationMeta(
    'aiParseResultId',
  );
  @override
  late final GeneratedColumn<String> aiParseResultId = GeneratedColumn<String>(
    'ai_parse_result_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ai_parse_results (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTextMeta = const VerificationMeta(
    'sourceText',
  );
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
    'source_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needUserConfirmMeta = const VerificationMeta(
    'needUserConfirm',
  );
  @override
  late final GeneratedColumn<bool> needUserConfirm = GeneratedColumn<bool>(
    'need_user_confirm',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("need_user_confirm" IN (0, 1))',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawInputId,
    aiParseResultId,
    type,
    title,
    content,
    sourceText,
    tagsJson,
    confidence,
    needUserConfirm,
    status,
    expiresAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extracted_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtractedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('raw_input_id')) {
      context.handle(
        _rawInputIdMeta,
        rawInputId.isAcceptableOrUnknown(
          data['raw_input_id']!,
          _rawInputIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawInputIdMeta);
    }
    if (data.containsKey('ai_parse_result_id')) {
      context.handle(
        _aiParseResultIdMeta,
        aiParseResultId.isAcceptableOrUnknown(
          data['ai_parse_result_id']!,
          _aiParseResultIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aiParseResultIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('source_text')) {
      context.handle(
        _sourceTextMeta,
        sourceText.isAcceptableOrUnknown(data['source_text']!, _sourceTextMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTextMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('need_user_confirm')) {
      context.handle(
        _needUserConfirmMeta,
        needUserConfirm.isAcceptableOrUnknown(
          data['need_user_confirm']!,
          _needUserConfirmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_needUserConfirmMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtractedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtractedItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rawInputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_input_id'],
      )!,
      aiParseResultId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_parse_result_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      sourceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_text'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      needUserConfirm: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}need_user_confirm'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExtractedItemsTable createAlias(String alias) {
    return $ExtractedItemsTable(attachedDatabase, alias);
  }
}

class ExtractedItem extends DataClass implements Insertable<ExtractedItem> {
  final String id;
  final String rawInputId;
  final String aiParseResultId;
  final String type;
  final String? title;
  final String? content;
  final String sourceText;
  final String tagsJson;
  final double confidence;
  final bool needUserConfirm;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExtractedItem({
    required this.id,
    required this.rawInputId,
    required this.aiParseResultId,
    required this.type,
    this.title,
    this.content,
    required this.sourceText,
    required this.tagsJson,
    required this.confidence,
    required this.needUserConfirm,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['raw_input_id'] = Variable<String>(rawInputId);
    map['ai_parse_result_id'] = Variable<String>(aiParseResultId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['source_text'] = Variable<String>(sourceText);
    map['tags_json'] = Variable<String>(tagsJson);
    map['confidence'] = Variable<double>(confidence);
    map['need_user_confirm'] = Variable<bool>(needUserConfirm);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExtractedItemsCompanion toCompanion(bool nullToAbsent) {
    return ExtractedItemsCompanion(
      id: Value(id),
      rawInputId: Value(rawInputId),
      aiParseResultId: Value(aiParseResultId),
      type: Value(type),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      sourceText: Value(sourceText),
      tagsJson: Value(tagsJson),
      confidence: Value(confidence),
      needUserConfirm: Value(needUserConfirm),
      status: Value(status),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExtractedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtractedItem(
      id: serializer.fromJson<String>(json['id']),
      rawInputId: serializer.fromJson<String>(json['rawInputId']),
      aiParseResultId: serializer.fromJson<String>(json['aiParseResultId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      sourceText: serializer.fromJson<String>(json['sourceText']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      confidence: serializer.fromJson<double>(json['confidence']),
      needUserConfirm: serializer.fromJson<bool>(json['needUserConfirm']),
      status: serializer.fromJson<String>(json['status']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rawInputId': serializer.toJson<String>(rawInputId),
      'aiParseResultId': serializer.toJson<String>(aiParseResultId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String?>(content),
      'sourceText': serializer.toJson<String>(sourceText),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'confidence': serializer.toJson<double>(confidence),
      'needUserConfirm': serializer.toJson<bool>(needUserConfirm),
      'status': serializer.toJson<String>(status),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExtractedItem copyWith({
    String? id,
    String? rawInputId,
    String? aiParseResultId,
    String? type,
    Value<String?> title = const Value.absent(),
    Value<String?> content = const Value.absent(),
    String? sourceText,
    String? tagsJson,
    double? confidence,
    bool? needUserConfirm,
    String? status,
    Value<DateTime?> expiresAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExtractedItem(
    id: id ?? this.id,
    rawInputId: rawInputId ?? this.rawInputId,
    aiParseResultId: aiParseResultId ?? this.aiParseResultId,
    type: type ?? this.type,
    title: title.present ? title.value : this.title,
    content: content.present ? content.value : this.content,
    sourceText: sourceText ?? this.sourceText,
    tagsJson: tagsJson ?? this.tagsJson,
    confidence: confidence ?? this.confidence,
    needUserConfirm: needUserConfirm ?? this.needUserConfirm,
    status: status ?? this.status,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExtractedItem copyWithCompanion(ExtractedItemsCompanion data) {
    return ExtractedItem(
      id: data.id.present ? data.id.value : this.id,
      rawInputId: data.rawInputId.present
          ? data.rawInputId.value
          : this.rawInputId,
      aiParseResultId: data.aiParseResultId.present
          ? data.aiParseResultId.value
          : this.aiParseResultId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      sourceText: data.sourceText.present
          ? data.sourceText.value
          : this.sourceText,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      needUserConfirm: data.needUserConfirm.present
          ? data.needUserConfirm.value
          : this.needUserConfirm,
      status: data.status.present ? data.status.value : this.status,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtractedItem(')
          ..write('id: $id, ')
          ..write('rawInputId: $rawInputId, ')
          ..write('aiParseResultId: $aiParseResultId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('sourceText: $sourceText, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('confidence: $confidence, ')
          ..write('needUserConfirm: $needUserConfirm, ')
          ..write('status: $status, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawInputId,
    aiParseResultId,
    type,
    title,
    content,
    sourceText,
    tagsJson,
    confidence,
    needUserConfirm,
    status,
    expiresAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtractedItem &&
          other.id == this.id &&
          other.rawInputId == this.rawInputId &&
          other.aiParseResultId == this.aiParseResultId &&
          other.type == this.type &&
          other.title == this.title &&
          other.content == this.content &&
          other.sourceText == this.sourceText &&
          other.tagsJson == this.tagsJson &&
          other.confidence == this.confidence &&
          other.needUserConfirm == this.needUserConfirm &&
          other.status == this.status &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExtractedItemsCompanion extends UpdateCompanion<ExtractedItem> {
  final Value<String> id;
  final Value<String> rawInputId;
  final Value<String> aiParseResultId;
  final Value<String> type;
  final Value<String?> title;
  final Value<String?> content;
  final Value<String> sourceText;
  final Value<String> tagsJson;
  final Value<double> confidence;
  final Value<bool> needUserConfirm;
  final Value<String> status;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExtractedItemsCompanion({
    this.id = const Value.absent(),
    this.rawInputId = const Value.absent(),
    this.aiParseResultId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.confidence = const Value.absent(),
    this.needUserConfirm = const Value.absent(),
    this.status = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtractedItemsCompanion.insert({
    required String id,
    required String rawInputId,
    required String aiParseResultId,
    required String type,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    required String sourceText,
    this.tagsJson = const Value.absent(),
    required double confidence,
    required bool needUserConfirm,
    required String status,
    this.expiresAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawInputId = Value(rawInputId),
       aiParseResultId = Value(aiParseResultId),
       type = Value(type),
       sourceText = Value(sourceText),
       confidence = Value(confidence),
       needUserConfirm = Value(needUserConfirm),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExtractedItem> custom({
    Expression<String>? id,
    Expression<String>? rawInputId,
    Expression<String>? aiParseResultId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? sourceText,
    Expression<String>? tagsJson,
    Expression<double>? confidence,
    Expression<bool>? needUserConfirm,
    Expression<String>? status,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawInputId != null) 'raw_input_id': rawInputId,
      if (aiParseResultId != null) 'ai_parse_result_id': aiParseResultId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (sourceText != null) 'source_text': sourceText,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (confidence != null) 'confidence': confidence,
      if (needUserConfirm != null) 'need_user_confirm': needUserConfirm,
      if (status != null) 'status': status,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtractedItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? rawInputId,
    Value<String>? aiParseResultId,
    Value<String>? type,
    Value<String?>? title,
    Value<String?>? content,
    Value<String>? sourceText,
    Value<String>? tagsJson,
    Value<double>? confidence,
    Value<bool>? needUserConfirm,
    Value<String>? status,
    Value<DateTime?>? expiresAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExtractedItemsCompanion(
      id: id ?? this.id,
      rawInputId: rawInputId ?? this.rawInputId,
      aiParseResultId: aiParseResultId ?? this.aiParseResultId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      sourceText: sourceText ?? this.sourceText,
      tagsJson: tagsJson ?? this.tagsJson,
      confidence: confidence ?? this.confidence,
      needUserConfirm: needUserConfirm ?? this.needUserConfirm,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rawInputId.present) {
      map['raw_input_id'] = Variable<String>(rawInputId.value);
    }
    if (aiParseResultId.present) {
      map['ai_parse_result_id'] = Variable<String>(aiParseResultId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (needUserConfirm.present) {
      map['need_user_confirm'] = Variable<bool>(needUserConfirm.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtractedItemsCompanion(')
          ..write('id: $id, ')
          ..write('rawInputId: $rawInputId, ')
          ..write('aiParseResultId: $aiParseResultId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('sourceText: $sourceText, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('confidence: $confidence, ')
          ..write('needUserConfirm: $needUserConfirm, ')
          ..write('status: $status, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRawInputIdMeta = const VerificationMeta(
    'sourceRawInputId',
  );
  @override
  late final GeneratedColumn<String> sourceRawInputId = GeneratedColumn<String>(
    'source_raw_input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES raw_inputs (id)',
    ),
  );
  static const VerificationMeta _sourceExtractedItemIdMeta =
      const VerificationMeta('sourceExtractedItemId');
  @override
  late final GeneratedColumn<String> sourceExtractedItemId =
      GeneratedColumn<String>(
        'source_extracted_item_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES extracted_items (id)',
        ),
      );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueTimeTextMeta = const VerificationMeta(
    'dueTimeText',
  );
  @override
  late final GeneratedColumn<String> dueTimeText = GeneratedColumn<String>(
    'due_time_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueTimeMeta = const VerificationMeta(
    'dueTime',
  );
  @override
  late final GeneratedColumn<DateTime> dueTime = GeneratedColumn<DateTime>(
    'due_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceRawInputId,
    sourceExtractedItemId,
    title,
    description,
    dueTimeText,
    dueTime,
    priority,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_raw_input_id')) {
      context.handle(
        _sourceRawInputIdMeta,
        sourceRawInputId.isAcceptableOrUnknown(
          data['source_raw_input_id']!,
          _sourceRawInputIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRawInputIdMeta);
    }
    if (data.containsKey('source_extracted_item_id')) {
      context.handle(
        _sourceExtractedItemIdMeta,
        sourceExtractedItemId.isAcceptableOrUnknown(
          data['source_extracted_item_id']!,
          _sourceExtractedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceExtractedItemIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('due_time_text')) {
      context.handle(
        _dueTimeTextMeta,
        dueTimeText.isAcceptableOrUnknown(
          data['due_time_text']!,
          _dueTimeTextMeta,
        ),
      );
    }
    if (data.containsKey('due_time')) {
      context.handle(
        _dueTimeMeta,
        dueTime.isAcceptableOrUnknown(data['due_time']!, _dueTimeMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceRawInputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_raw_input_id'],
      )!,
      sourceExtractedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_extracted_item_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      dueTimeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_time_text'],
      ),
      dueTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_time'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String sourceRawInputId;
  final String sourceExtractedItemId;
  final String title;
  final String? description;
  final String? dueTimeText;
  final DateTime? dueTime;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Task({
    required this.id,
    required this.sourceRawInputId,
    required this.sourceExtractedItemId,
    required this.title,
    this.description,
    this.dueTimeText,
    this.dueTime,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_raw_input_id'] = Variable<String>(sourceRawInputId);
    map['source_extracted_item_id'] = Variable<String>(sourceExtractedItemId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || dueTimeText != null) {
      map['due_time_text'] = Variable<String>(dueTimeText);
    }
    if (!nullToAbsent || dueTime != null) {
      map['due_time'] = Variable<DateTime>(dueTime);
    }
    map['priority'] = Variable<String>(priority);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      sourceRawInputId: Value(sourceRawInputId),
      sourceExtractedItemId: Value(sourceExtractedItemId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      dueTimeText: dueTimeText == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTimeText),
      dueTime: dueTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTime),
      priority: Value(priority),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      sourceRawInputId: serializer.fromJson<String>(json['sourceRawInputId']),
      sourceExtractedItemId: serializer.fromJson<String>(
        json['sourceExtractedItemId'],
      ),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      dueTimeText: serializer.fromJson<String?>(json['dueTimeText']),
      dueTime: serializer.fromJson<DateTime?>(json['dueTime']),
      priority: serializer.fromJson<String>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceRawInputId': serializer.toJson<String>(sourceRawInputId),
      'sourceExtractedItemId': serializer.toJson<String>(sourceExtractedItemId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'dueTimeText': serializer.toJson<String?>(dueTimeText),
      'dueTime': serializer.toJson<DateTime?>(dueTime),
      'priority': serializer.toJson<String>(priority),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? sourceRawInputId,
    String? sourceExtractedItemId,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> dueTimeText = const Value.absent(),
    Value<DateTime?> dueTime = const Value.absent(),
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Task(
    id: id ?? this.id,
    sourceRawInputId: sourceRawInputId ?? this.sourceRawInputId,
    sourceExtractedItemId: sourceExtractedItemId ?? this.sourceExtractedItemId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    dueTimeText: dueTimeText.present ? dueTimeText.value : this.dueTimeText,
    dueTime: dueTime.present ? dueTime.value : this.dueTime,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      sourceRawInputId: data.sourceRawInputId.present
          ? data.sourceRawInputId.value
          : this.sourceRawInputId,
      sourceExtractedItemId: data.sourceExtractedItemId.present
          ? data.sourceExtractedItemId.value
          : this.sourceExtractedItemId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      dueTimeText: data.dueTimeText.present
          ? data.dueTimeText.value
          : this.dueTimeText,
      dueTime: data.dueTime.present ? data.dueTime.value : this.dueTime,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('sourceRawInputId: $sourceRawInputId, ')
          ..write('sourceExtractedItemId: $sourceExtractedItemId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueTimeText: $dueTimeText, ')
          ..write('dueTime: $dueTime, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceRawInputId,
    sourceExtractedItemId,
    title,
    description,
    dueTimeText,
    dueTime,
    priority,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.sourceRawInputId == this.sourceRawInputId &&
          other.sourceExtractedItemId == this.sourceExtractedItemId &&
          other.title == this.title &&
          other.description == this.description &&
          other.dueTimeText == this.dueTimeText &&
          other.dueTime == this.dueTime &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> sourceRawInputId;
  final Value<String> sourceExtractedItemId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> dueTimeText;
  final Value<DateTime?> dueTime;
  final Value<String> priority;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.sourceRawInputId = const Value.absent(),
    this.sourceExtractedItemId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.dueTimeText = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String sourceRawInputId,
    required String sourceExtractedItemId,
    required String title,
    this.description = const Value.absent(),
    this.dueTimeText = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.priority = const Value.absent(),
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceRawInputId = Value(sourceRawInputId),
       sourceExtractedItemId = Value(sourceExtractedItemId),
       title = Value(title),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? sourceRawInputId,
    Expression<String>? sourceExtractedItemId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? dueTimeText,
    Expression<DateTime>? dueTime,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceRawInputId != null) 'source_raw_input_id': sourceRawInputId,
      if (sourceExtractedItemId != null)
        'source_extracted_item_id': sourceExtractedItemId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueTimeText != null) 'due_time_text': dueTimeText,
      if (dueTime != null) 'due_time': dueTime,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceRawInputId,
    Value<String>? sourceExtractedItemId,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? dueTimeText,
    Value<DateTime?>? dueTime,
    Value<String>? priority,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      sourceRawInputId: sourceRawInputId ?? this.sourceRawInputId,
      sourceExtractedItemId:
          sourceExtractedItemId ?? this.sourceExtractedItemId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueTimeText: dueTimeText ?? this.dueTimeText,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceRawInputId.present) {
      map['source_raw_input_id'] = Variable<String>(sourceRawInputId.value);
    }
    if (sourceExtractedItemId.present) {
      map['source_extracted_item_id'] = Variable<String>(
        sourceExtractedItemId.value,
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (dueTimeText.present) {
      map['due_time_text'] = Variable<String>(dueTimeText.value);
    }
    if (dueTime.present) {
      map['due_time'] = Variable<DateTime>(dueTime.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('sourceRawInputId: $sourceRawInputId, ')
          ..write('sourceExtractedItemId: $sourceExtractedItemId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueTimeText: $dueTimeText, ')
          ..write('dueTime: $dueTime, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShortTermStatesTable extends ShortTermStates
    with TableInfo<$ShortTermStatesTable, ShortTermState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShortTermStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRawInputIdMeta = const VerificationMeta(
    'sourceRawInputId',
  );
  @override
  late final GeneratedColumn<String> sourceRawInputId = GeneratedColumn<String>(
    'source_raw_input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES raw_inputs (id)',
    ),
  );
  static const VerificationMeta _sourceExtractedItemIdMeta =
      const VerificationMeta('sourceExtractedItemId');
  @override
  late final GeneratedColumn<String> sourceExtractedItemId =
      GeneratedColumn<String>(
        'source_extracted_item_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES extracted_items (id)',
        ),
      );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _validUntilMeta = const VerificationMeta(
    'validUntil',
  );
  @override
  late final GeneratedColumn<DateTime> validUntil = GeneratedColumn<DateTime>(
    'valid_until',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceRawInputId,
    sourceExtractedItemId,
    content,
    tagsJson,
    validUntil,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'short_term_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShortTermState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_raw_input_id')) {
      context.handle(
        _sourceRawInputIdMeta,
        sourceRawInputId.isAcceptableOrUnknown(
          data['source_raw_input_id']!,
          _sourceRawInputIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRawInputIdMeta);
    }
    if (data.containsKey('source_extracted_item_id')) {
      context.handle(
        _sourceExtractedItemIdMeta,
        sourceExtractedItemId.isAcceptableOrUnknown(
          data['source_extracted_item_id']!,
          _sourceExtractedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceExtractedItemIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('valid_until')) {
      context.handle(
        _validUntilMeta,
        validUntil.isAcceptableOrUnknown(data['valid_until']!, _validUntilMeta),
      );
    } else if (isInserting) {
      context.missing(_validUntilMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShortTermState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShortTermState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceRawInputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_raw_input_id'],
      )!,
      sourceExtractedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_extracted_item_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      validUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_until'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ShortTermStatesTable createAlias(String alias) {
    return $ShortTermStatesTable(attachedDatabase, alias);
  }
}

class ShortTermState extends DataClass implements Insertable<ShortTermState> {
  final String id;
  final String sourceRawInputId;
  final String sourceExtractedItemId;
  final String content;
  final String tagsJson;
  final DateTime validUntil;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ShortTermState({
    required this.id,
    required this.sourceRawInputId,
    required this.sourceExtractedItemId,
    required this.content,
    required this.tagsJson,
    required this.validUntil,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_raw_input_id'] = Variable<String>(sourceRawInputId);
    map['source_extracted_item_id'] = Variable<String>(sourceExtractedItemId);
    map['content'] = Variable<String>(content);
    map['tags_json'] = Variable<String>(tagsJson);
    map['valid_until'] = Variable<DateTime>(validUntil);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ShortTermStatesCompanion toCompanion(bool nullToAbsent) {
    return ShortTermStatesCompanion(
      id: Value(id),
      sourceRawInputId: Value(sourceRawInputId),
      sourceExtractedItemId: Value(sourceExtractedItemId),
      content: Value(content),
      tagsJson: Value(tagsJson),
      validUntil: Value(validUntil),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ShortTermState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShortTermState(
      id: serializer.fromJson<String>(json['id']),
      sourceRawInputId: serializer.fromJson<String>(json['sourceRawInputId']),
      sourceExtractedItemId: serializer.fromJson<String>(
        json['sourceExtractedItemId'],
      ),
      content: serializer.fromJson<String>(json['content']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      validUntil: serializer.fromJson<DateTime>(json['validUntil']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceRawInputId': serializer.toJson<String>(sourceRawInputId),
      'sourceExtractedItemId': serializer.toJson<String>(sourceExtractedItemId),
      'content': serializer.toJson<String>(content),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'validUntil': serializer.toJson<DateTime>(validUntil),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ShortTermState copyWith({
    String? id,
    String? sourceRawInputId,
    String? sourceExtractedItemId,
    String? content,
    String? tagsJson,
    DateTime? validUntil,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ShortTermState(
    id: id ?? this.id,
    sourceRawInputId: sourceRawInputId ?? this.sourceRawInputId,
    sourceExtractedItemId: sourceExtractedItemId ?? this.sourceExtractedItemId,
    content: content ?? this.content,
    tagsJson: tagsJson ?? this.tagsJson,
    validUntil: validUntil ?? this.validUntil,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ShortTermState copyWithCompanion(ShortTermStatesCompanion data) {
    return ShortTermState(
      id: data.id.present ? data.id.value : this.id,
      sourceRawInputId: data.sourceRawInputId.present
          ? data.sourceRawInputId.value
          : this.sourceRawInputId,
      sourceExtractedItemId: data.sourceExtractedItemId.present
          ? data.sourceExtractedItemId.value
          : this.sourceExtractedItemId,
      content: data.content.present ? data.content.value : this.content,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      validUntil: data.validUntil.present
          ? data.validUntil.value
          : this.validUntil,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShortTermState(')
          ..write('id: $id, ')
          ..write('sourceRawInputId: $sourceRawInputId, ')
          ..write('sourceExtractedItemId: $sourceExtractedItemId, ')
          ..write('content: $content, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('validUntil: $validUntil, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceRawInputId,
    sourceExtractedItemId,
    content,
    tagsJson,
    validUntil,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShortTermState &&
          other.id == this.id &&
          other.sourceRawInputId == this.sourceRawInputId &&
          other.sourceExtractedItemId == this.sourceExtractedItemId &&
          other.content == this.content &&
          other.tagsJson == this.tagsJson &&
          other.validUntil == this.validUntil &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShortTermStatesCompanion extends UpdateCompanion<ShortTermState> {
  final Value<String> id;
  final Value<String> sourceRawInputId;
  final Value<String> sourceExtractedItemId;
  final Value<String> content;
  final Value<String> tagsJson;
  final Value<DateTime> validUntil;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ShortTermStatesCompanion({
    this.id = const Value.absent(),
    this.sourceRawInputId = const Value.absent(),
    this.sourceExtractedItemId = const Value.absent(),
    this.content = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShortTermStatesCompanion.insert({
    required String id,
    required String sourceRawInputId,
    required String sourceExtractedItemId,
    required String content,
    this.tagsJson = const Value.absent(),
    required DateTime validUntil,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceRawInputId = Value(sourceRawInputId),
       sourceExtractedItemId = Value(sourceExtractedItemId),
       content = Value(content),
       validUntil = Value(validUntil),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ShortTermState> custom({
    Expression<String>? id,
    Expression<String>? sourceRawInputId,
    Expression<String>? sourceExtractedItemId,
    Expression<String>? content,
    Expression<String>? tagsJson,
    Expression<DateTime>? validUntil,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceRawInputId != null) 'source_raw_input_id': sourceRawInputId,
      if (sourceExtractedItemId != null)
        'source_extracted_item_id': sourceExtractedItemId,
      if (content != null) 'content': content,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (validUntil != null) 'valid_until': validUntil,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShortTermStatesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceRawInputId,
    Value<String>? sourceExtractedItemId,
    Value<String>? content,
    Value<String>? tagsJson,
    Value<DateTime>? validUntil,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ShortTermStatesCompanion(
      id: id ?? this.id,
      sourceRawInputId: sourceRawInputId ?? this.sourceRawInputId,
      sourceExtractedItemId:
          sourceExtractedItemId ?? this.sourceExtractedItemId,
      content: content ?? this.content,
      tagsJson: tagsJson ?? this.tagsJson,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceRawInputId.present) {
      map['source_raw_input_id'] = Variable<String>(sourceRawInputId.value);
    }
    if (sourceExtractedItemId.present) {
      map['source_extracted_item_id'] = Variable<String>(
        sourceExtractedItemId.value,
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<DateTime>(validUntil.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShortTermStatesCompanion(')
          ..write('id: $id, ')
          ..write('sourceRawInputId: $sourceRawInputId, ')
          ..write('sourceExtractedItemId: $sourceExtractedItemId, ')
          ..write('content: $content, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('validUntil: $validUntil, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifeEventsTable extends LifeEvents
    with TableInfo<$LifeEventsTable, LifeEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifeEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRawInputIdMeta = const VerificationMeta(
    'sourceRawInputId',
  );
  @override
  late final GeneratedColumn<String> sourceRawInputId = GeneratedColumn<String>(
    'source_raw_input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES raw_inputs (id)',
    ),
  );
  static const VerificationMeta _sourceExtractedItemIdMeta =
      const VerificationMeta('sourceExtractedItemId');
  @override
  late final GeneratedColumn<String> sourceExtractedItemId =
      GeneratedColumn<String>(
        'source_extracted_item_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES extracted_items (id)',
        ),
      );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceRawInputId,
    sourceExtractedItemId,
    content,
    tagsJson,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'life_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LifeEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_raw_input_id')) {
      context.handle(
        _sourceRawInputIdMeta,
        sourceRawInputId.isAcceptableOrUnknown(
          data['source_raw_input_id']!,
          _sourceRawInputIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRawInputIdMeta);
    }
    if (data.containsKey('source_extracted_item_id')) {
      context.handle(
        _sourceExtractedItemIdMeta,
        sourceExtractedItemId.isAcceptableOrUnknown(
          data['source_extracted_item_id']!,
          _sourceExtractedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceExtractedItemIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifeEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifeEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceRawInputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_raw_input_id'],
      )!,
      sourceExtractedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_extracted_item_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LifeEventsTable createAlias(String alias) {
    return $LifeEventsTable(attachedDatabase, alias);
  }
}

class LifeEvent extends DataClass implements Insertable<LifeEvent> {
  final String id;
  final String sourceRawInputId;
  final String sourceExtractedItemId;
  final String content;
  final String tagsJson;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LifeEvent({
    required this.id,
    required this.sourceRawInputId,
    required this.sourceExtractedItemId,
    required this.content,
    required this.tagsJson,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_raw_input_id'] = Variable<String>(sourceRawInputId);
    map['source_extracted_item_id'] = Variable<String>(sourceExtractedItemId);
    map['content'] = Variable<String>(content);
    map['tags_json'] = Variable<String>(tagsJson);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LifeEventsCompanion toCompanion(bool nullToAbsent) {
    return LifeEventsCompanion(
      id: Value(id),
      sourceRawInputId: Value(sourceRawInputId),
      sourceExtractedItemId: Value(sourceExtractedItemId),
      content: Value(content),
      tagsJson: Value(tagsJson),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LifeEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifeEvent(
      id: serializer.fromJson<String>(json['id']),
      sourceRawInputId: serializer.fromJson<String>(json['sourceRawInputId']),
      sourceExtractedItemId: serializer.fromJson<String>(
        json['sourceExtractedItemId'],
      ),
      content: serializer.fromJson<String>(json['content']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceRawInputId': serializer.toJson<String>(sourceRawInputId),
      'sourceExtractedItemId': serializer.toJson<String>(sourceExtractedItemId),
      'content': serializer.toJson<String>(content),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LifeEvent copyWith({
    String? id,
    String? sourceRawInputId,
    String? sourceExtractedItemId,
    String? content,
    String? tagsJson,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LifeEvent(
    id: id ?? this.id,
    sourceRawInputId: sourceRawInputId ?? this.sourceRawInputId,
    sourceExtractedItemId: sourceExtractedItemId ?? this.sourceExtractedItemId,
    content: content ?? this.content,
    tagsJson: tagsJson ?? this.tagsJson,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LifeEvent copyWithCompanion(LifeEventsCompanion data) {
    return LifeEvent(
      id: data.id.present ? data.id.value : this.id,
      sourceRawInputId: data.sourceRawInputId.present
          ? data.sourceRawInputId.value
          : this.sourceRawInputId,
      sourceExtractedItemId: data.sourceExtractedItemId.present
          ? data.sourceExtractedItemId.value
          : this.sourceExtractedItemId,
      content: data.content.present ? data.content.value : this.content,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifeEvent(')
          ..write('id: $id, ')
          ..write('sourceRawInputId: $sourceRawInputId, ')
          ..write('sourceExtractedItemId: $sourceExtractedItemId, ')
          ..write('content: $content, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceRawInputId,
    sourceExtractedItemId,
    content,
    tagsJson,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifeEvent &&
          other.id == this.id &&
          other.sourceRawInputId == this.sourceRawInputId &&
          other.sourceExtractedItemId == this.sourceExtractedItemId &&
          other.content == this.content &&
          other.tagsJson == this.tagsJson &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LifeEventsCompanion extends UpdateCompanion<LifeEvent> {
  final Value<String> id;
  final Value<String> sourceRawInputId;
  final Value<String> sourceExtractedItemId;
  final Value<String> content;
  final Value<String> tagsJson;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LifeEventsCompanion({
    this.id = const Value.absent(),
    this.sourceRawInputId = const Value.absent(),
    this.sourceExtractedItemId = const Value.absent(),
    this.content = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LifeEventsCompanion.insert({
    required String id,
    required String sourceRawInputId,
    required String sourceExtractedItemId,
    required String content,
    this.tagsJson = const Value.absent(),
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceRawInputId = Value(sourceRawInputId),
       sourceExtractedItemId = Value(sourceExtractedItemId),
       content = Value(content),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LifeEvent> custom({
    Expression<String>? id,
    Expression<String>? sourceRawInputId,
    Expression<String>? sourceExtractedItemId,
    Expression<String>? content,
    Expression<String>? tagsJson,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceRawInputId != null) 'source_raw_input_id': sourceRawInputId,
      if (sourceExtractedItemId != null)
        'source_extracted_item_id': sourceExtractedItemId,
      if (content != null) 'content': content,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LifeEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceRawInputId,
    Value<String>? sourceExtractedItemId,
    Value<String>? content,
    Value<String>? tagsJson,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LifeEventsCompanion(
      id: id ?? this.id,
      sourceRawInputId: sourceRawInputId ?? this.sourceRawInputId,
      sourceExtractedItemId:
          sourceExtractedItemId ?? this.sourceExtractedItemId,
      content: content ?? this.content,
      tagsJson: tagsJson ?? this.tagsJson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceRawInputId.present) {
      map['source_raw_input_id'] = Variable<String>(sourceRawInputId.value);
    }
    if (sourceExtractedItemId.present) {
      map['source_extracted_item_id'] = Variable<String>(
        sourceExtractedItemId.value,
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifeEventsCompanion(')
          ..write('id: $id, ')
          ..write('sourceRawInputId: $sourceRawInputId, ')
          ..write('sourceExtractedItemId: $sourceExtractedItemId, ')
          ..write('content: $content, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileItemsTable extends ProfileItems
    with TableInfo<$ProfileItemsTable, ProfileItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRawInputIdMeta = const VerificationMeta(
    'sourceRawInputId',
  );
  @override
  late final GeneratedColumn<String> sourceRawInputId = GeneratedColumn<String>(
    'source_raw_input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES raw_inputs (id)',
    ),
  );
  static const VerificationMeta _sourceExtractedItemIdMeta =
      const VerificationMeta('sourceExtractedItemId');
  @override
  late final GeneratedColumn<String> sourceExtractedItemId =
      GeneratedColumn<String>(
        'source_extracted_item_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES extracted_items (id)',
        ),
      );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceRawInputId,
    sourceExtractedItemId,
    content,
    category,
    tagsJson,
    confidence,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_raw_input_id')) {
      context.handle(
        _sourceRawInputIdMeta,
        sourceRawInputId.isAcceptableOrUnknown(
          data['source_raw_input_id']!,
          _sourceRawInputIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRawInputIdMeta);
    }
    if (data.containsKey('source_extracted_item_id')) {
      context.handle(
        _sourceExtractedItemIdMeta,
        sourceExtractedItemId.isAcceptableOrUnknown(
          data['source_extracted_item_id']!,
          _sourceExtractedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceExtractedItemIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceRawInputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_raw_input_id'],
      )!,
      sourceExtractedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_extracted_item_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfileItemsTable createAlias(String alias) {
    return $ProfileItemsTable(attachedDatabase, alias);
  }
}

class ProfileItem extends DataClass implements Insertable<ProfileItem> {
  final String id;
  final String sourceRawInputId;
  final String sourceExtractedItemId;
  final String content;
  final String? category;
  final String tagsJson;
  final double confidence;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProfileItem({
    required this.id,
    required this.sourceRawInputId,
    required this.sourceExtractedItemId,
    required this.content,
    this.category,
    required this.tagsJson,
    required this.confidence,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_raw_input_id'] = Variable<String>(sourceRawInputId);
    map['source_extracted_item_id'] = Variable<String>(sourceExtractedItemId);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['confidence'] = Variable<double>(confidence);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfileItemsCompanion toCompanion(bool nullToAbsent) {
    return ProfileItemsCompanion(
      id: Value(id),
      sourceRawInputId: Value(sourceRawInputId),
      sourceExtractedItemId: Value(sourceExtractedItemId),
      content: Value(content),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      tagsJson: Value(tagsJson),
      confidence: Value(confidence),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileItem(
      id: serializer.fromJson<String>(json['id']),
      sourceRawInputId: serializer.fromJson<String>(json['sourceRawInputId']),
      sourceExtractedItemId: serializer.fromJson<String>(
        json['sourceExtractedItemId'],
      ),
      content: serializer.fromJson<String>(json['content']),
      category: serializer.fromJson<String?>(json['category']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      confidence: serializer.fromJson<double>(json['confidence']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceRawInputId': serializer.toJson<String>(sourceRawInputId),
      'sourceExtractedItemId': serializer.toJson<String>(sourceExtractedItemId),
      'content': serializer.toJson<String>(content),
      'category': serializer.toJson<String?>(category),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'confidence': serializer.toJson<double>(confidence),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfileItem copyWith({
    String? id,
    String? sourceRawInputId,
    String? sourceExtractedItemId,
    String? content,
    Value<String?> category = const Value.absent(),
    String? tagsJson,
    double? confidence,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProfileItem(
    id: id ?? this.id,
    sourceRawInputId: sourceRawInputId ?? this.sourceRawInputId,
    sourceExtractedItemId: sourceExtractedItemId ?? this.sourceExtractedItemId,
    content: content ?? this.content,
    category: category.present ? category.value : this.category,
    tagsJson: tagsJson ?? this.tagsJson,
    confidence: confidence ?? this.confidence,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileItem copyWithCompanion(ProfileItemsCompanion data) {
    return ProfileItem(
      id: data.id.present ? data.id.value : this.id,
      sourceRawInputId: data.sourceRawInputId.present
          ? data.sourceRawInputId.value
          : this.sourceRawInputId,
      sourceExtractedItemId: data.sourceExtractedItemId.present
          ? data.sourceExtractedItemId.value
          : this.sourceExtractedItemId,
      content: data.content.present ? data.content.value : this.content,
      category: data.category.present ? data.category.value : this.category,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileItem(')
          ..write('id: $id, ')
          ..write('sourceRawInputId: $sourceRawInputId, ')
          ..write('sourceExtractedItemId: $sourceExtractedItemId, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceRawInputId,
    sourceExtractedItemId,
    content,
    category,
    tagsJson,
    confidence,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileItem &&
          other.id == this.id &&
          other.sourceRawInputId == this.sourceRawInputId &&
          other.sourceExtractedItemId == this.sourceExtractedItemId &&
          other.content == this.content &&
          other.category == this.category &&
          other.tagsJson == this.tagsJson &&
          other.confidence == this.confidence &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProfileItemsCompanion extends UpdateCompanion<ProfileItem> {
  final Value<String> id;
  final Value<String> sourceRawInputId;
  final Value<String> sourceExtractedItemId;
  final Value<String> content;
  final Value<String?> category;
  final Value<String> tagsJson;
  final Value<double> confidence;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfileItemsCompanion({
    this.id = const Value.absent(),
    this.sourceRawInputId = const Value.absent(),
    this.sourceExtractedItemId = const Value.absent(),
    this.content = const Value.absent(),
    this.category = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.confidence = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileItemsCompanion.insert({
    required String id,
    required String sourceRawInputId,
    required String sourceExtractedItemId,
    required String content,
    this.category = const Value.absent(),
    this.tagsJson = const Value.absent(),
    required double confidence,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceRawInputId = Value(sourceRawInputId),
       sourceExtractedItemId = Value(sourceExtractedItemId),
       content = Value(content),
       confidence = Value(confidence),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileItem> custom({
    Expression<String>? id,
    Expression<String>? sourceRawInputId,
    Expression<String>? sourceExtractedItemId,
    Expression<String>? content,
    Expression<String>? category,
    Expression<String>? tagsJson,
    Expression<double>? confidence,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceRawInputId != null) 'source_raw_input_id': sourceRawInputId,
      if (sourceExtractedItemId != null)
        'source_extracted_item_id': sourceExtractedItemId,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (confidence != null) 'confidence': confidence,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceRawInputId,
    Value<String>? sourceExtractedItemId,
    Value<String>? content,
    Value<String?>? category,
    Value<String>? tagsJson,
    Value<double>? confidence,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfileItemsCompanion(
      id: id ?? this.id,
      sourceRawInputId: sourceRawInputId ?? this.sourceRawInputId,
      sourceExtractedItemId:
          sourceExtractedItemId ?? this.sourceExtractedItemId,
      content: content ?? this.content,
      category: category ?? this.category,
      tagsJson: tagsJson ?? this.tagsJson,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceRawInputId.present) {
      map['source_raw_input_id'] = Variable<String>(sourceRawInputId.value);
    }
    if (sourceExtractedItemId.present) {
      map['source_extracted_item_id'] = Variable<String>(
        sourceExtractedItemId.value,
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileItemsCompanion(')
          ..write('id: $id, ')
          ..write('sourceRawInputId: $sourceRawInputId, ')
          ..write('sourceExtractedItemId: $sourceExtractedItemId, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RawInputsTable rawInputs = $RawInputsTable(this);
  late final $AiParseResultsTable aiParseResults = $AiParseResultsTable(this);
  late final $ExtractedItemsTable extractedItems = $ExtractedItemsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $ShortTermStatesTable shortTermStates = $ShortTermStatesTable(
    this,
  );
  late final $LifeEventsTable lifeEvents = $LifeEventsTable(this);
  late final $ProfileItemsTable profileItems = $ProfileItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    rawInputs,
    aiParseResults,
    extractedItems,
    tasks,
    shortTermStates,
    lifeEvents,
    profileItems,
  ];
}

typedef $$RawInputsTableCreateCompanionBuilder =
    RawInputsCompanion Function({
      required String id,
      required String inputText,
      Value<String> source,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$RawInputsTableUpdateCompanionBuilder =
    RawInputsCompanion Function({
      Value<String> id,
      Value<String> inputText,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$RawInputsTableReferences
    extends BaseReferences<_$AppDatabase, $RawInputsTable, RawInput> {
  $$RawInputsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AiParseResultsTable, List<AiParseResult>>
  _aiParseResultsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.aiParseResults,
    aliasName: $_aliasNameGenerator(
      db.rawInputs.id,
      db.aiParseResults.rawInputId,
    ),
  );

  $$AiParseResultsTableProcessedTableManager get aiParseResultsRefs {
    final manager = $$AiParseResultsTableTableManager(
      $_db,
      $_db.aiParseResults,
    ).filter((f) => f.rawInputId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_aiParseResultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExtractedItemsTable, List<ExtractedItem>>
  _extractedItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.extractedItems,
    aliasName: $_aliasNameGenerator(
      db.rawInputs.id,
      db.extractedItems.rawInputId,
    ),
  );

  $$ExtractedItemsTableProcessedTableManager get extractedItemsRefs {
    final manager = $$ExtractedItemsTableTableManager(
      $_db,
      $_db.extractedItems,
    ).filter((f) => f.rawInputId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_extractedItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: $_aliasNameGenerator(db.rawInputs.id, db.tasks.sourceRawInputId),
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter(
      (f) => f.sourceRawInputId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShortTermStatesTable, List<ShortTermState>>
  _shortTermStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shortTermStates,
    aliasName: $_aliasNameGenerator(
      db.rawInputs.id,
      db.shortTermStates.sourceRawInputId,
    ),
  );

  $$ShortTermStatesTableProcessedTableManager get shortTermStatesRefs {
    final manager =
        $$ShortTermStatesTableTableManager($_db, $_db.shortTermStates).filter(
          (f) => f.sourceRawInputId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _shortTermStatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LifeEventsTable, List<LifeEvent>>
  _lifeEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lifeEvents,
    aliasName: $_aliasNameGenerator(
      db.rawInputs.id,
      db.lifeEvents.sourceRawInputId,
    ),
  );

  $$LifeEventsTableProcessedTableManager get lifeEventsRefs {
    final manager = $$LifeEventsTableTableManager($_db, $_db.lifeEvents).filter(
      (f) => f.sourceRawInputId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_lifeEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProfileItemsTable, List<ProfileItem>>
  _profileItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.profileItems,
    aliasName: $_aliasNameGenerator(
      db.rawInputs.id,
      db.profileItems.sourceRawInputId,
    ),
  );

  $$ProfileItemsTableProcessedTableManager get profileItemsRefs {
    final manager = $$ProfileItemsTableTableManager($_db, $_db.profileItems)
        .filter(
          (f) => f.sourceRawInputId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_profileItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RawInputsTableFilterComposer
    extends Composer<_$AppDatabase, $RawInputsTable> {
  $$RawInputsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputText => $composableBuilder(
    column: $table.inputText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> aiParseResultsRefs(
    Expression<bool> Function($$AiParseResultsTableFilterComposer f) f,
  ) {
    final $$AiParseResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiParseResults,
      getReferencedColumn: (t) => t.rawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiParseResultsTableFilterComposer(
            $db: $db,
            $table: $db.aiParseResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> extractedItemsRefs(
    Expression<bool> Function($$ExtractedItemsTableFilterComposer f) f,
  ) {
    final $$ExtractedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.rawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableFilterComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.sourceRawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shortTermStatesRefs(
    Expression<bool> Function($$ShortTermStatesTableFilterComposer f) f,
  ) {
    final $$ShortTermStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shortTermStates,
      getReferencedColumn: (t) => t.sourceRawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShortTermStatesTableFilterComposer(
            $db: $db,
            $table: $db.shortTermStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lifeEventsRefs(
    Expression<bool> Function($$LifeEventsTableFilterComposer f) f,
  ) {
    final $$LifeEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifeEvents,
      getReferencedColumn: (t) => t.sourceRawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifeEventsTableFilterComposer(
            $db: $db,
            $table: $db.lifeEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> profileItemsRefs(
    Expression<bool> Function($$ProfileItemsTableFilterComposer f) f,
  ) {
    final $$ProfileItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileItems,
      getReferencedColumn: (t) => t.sourceRawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileItemsTableFilterComposer(
            $db: $db,
            $table: $db.profileItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RawInputsTableOrderingComposer
    extends Composer<_$AppDatabase, $RawInputsTable> {
  $$RawInputsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputText => $composableBuilder(
    column: $table.inputText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RawInputsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawInputsTable> {
  $$RawInputsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inputText =>
      $composableBuilder(column: $table.inputText, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> aiParseResultsRefs<T extends Object>(
    Expression<T> Function($$AiParseResultsTableAnnotationComposer a) f,
  ) {
    final $$AiParseResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiParseResults,
      getReferencedColumn: (t) => t.rawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiParseResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.aiParseResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> extractedItemsRefs<T extends Object>(
    Expression<T> Function($$ExtractedItemsTableAnnotationComposer a) f,
  ) {
    final $$ExtractedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.rawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.sourceRawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shortTermStatesRefs<T extends Object>(
    Expression<T> Function($$ShortTermStatesTableAnnotationComposer a) f,
  ) {
    final $$ShortTermStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shortTermStates,
      getReferencedColumn: (t) => t.sourceRawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShortTermStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.shortTermStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lifeEventsRefs<T extends Object>(
    Expression<T> Function($$LifeEventsTableAnnotationComposer a) f,
  ) {
    final $$LifeEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifeEvents,
      getReferencedColumn: (t) => t.sourceRawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifeEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.lifeEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> profileItemsRefs<T extends Object>(
    Expression<T> Function($$ProfileItemsTableAnnotationComposer a) f,
  ) {
    final $$ProfileItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileItems,
      getReferencedColumn: (t) => t.sourceRawInputId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.profileItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RawInputsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawInputsTable,
          RawInput,
          $$RawInputsTableFilterComposer,
          $$RawInputsTableOrderingComposer,
          $$RawInputsTableAnnotationComposer,
          $$RawInputsTableCreateCompanionBuilder,
          $$RawInputsTableUpdateCompanionBuilder,
          (RawInput, $$RawInputsTableReferences),
          RawInput,
          PrefetchHooks Function({
            bool aiParseResultsRefs,
            bool extractedItemsRefs,
            bool tasksRefs,
            bool shortTermStatesRefs,
            bool lifeEventsRefs,
            bool profileItemsRefs,
          })
        > {
  $$RawInputsTableTableManager(_$AppDatabase db, $RawInputsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawInputsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawInputsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawInputsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inputText = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RawInputsCompanion(
                id: id,
                inputText: inputText,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inputText,
                Value<String> source = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => RawInputsCompanion.insert(
                id: id,
                inputText: inputText,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RawInputsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                aiParseResultsRefs = false,
                extractedItemsRefs = false,
                tasksRefs = false,
                shortTermStatesRefs = false,
                lifeEventsRefs = false,
                profileItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (aiParseResultsRefs) db.aiParseResults,
                    if (extractedItemsRefs) db.extractedItems,
                    if (tasksRefs) db.tasks,
                    if (shortTermStatesRefs) db.shortTermStates,
                    if (lifeEventsRefs) db.lifeEvents,
                    if (profileItemsRefs) db.profileItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (aiParseResultsRefs)
                        await $_getPrefetchedData<
                          RawInput,
                          $RawInputsTable,
                          AiParseResult
                        >(
                          currentTable: table,
                          referencedTable: $$RawInputsTableReferences
                              ._aiParseResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RawInputsTableReferences(
                                db,
                                table,
                                p0,
                              ).aiParseResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.rawInputId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (extractedItemsRefs)
                        await $_getPrefetchedData<
                          RawInput,
                          $RawInputsTable,
                          ExtractedItem
                        >(
                          currentTable: table,
                          referencedTable: $$RawInputsTableReferences
                              ._extractedItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RawInputsTableReferences(
                                db,
                                table,
                                p0,
                              ).extractedItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.rawInputId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tasksRefs)
                        await $_getPrefetchedData<
                          RawInput,
                          $RawInputsTable,
                          Task
                        >(
                          currentTable: table,
                          referencedTable: $$RawInputsTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RawInputsTableReferences(
                                db,
                                table,
                                p0,
                              ).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceRawInputId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shortTermStatesRefs)
                        await $_getPrefetchedData<
                          RawInput,
                          $RawInputsTable,
                          ShortTermState
                        >(
                          currentTable: table,
                          referencedTable: $$RawInputsTableReferences
                              ._shortTermStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RawInputsTableReferences(
                                db,
                                table,
                                p0,
                              ).shortTermStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceRawInputId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lifeEventsRefs)
                        await $_getPrefetchedData<
                          RawInput,
                          $RawInputsTable,
                          LifeEvent
                        >(
                          currentTable: table,
                          referencedTable: $$RawInputsTableReferences
                              ._lifeEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RawInputsTableReferences(
                                db,
                                table,
                                p0,
                              ).lifeEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceRawInputId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (profileItemsRefs)
                        await $_getPrefetchedData<
                          RawInput,
                          $RawInputsTable,
                          ProfileItem
                        >(
                          currentTable: table,
                          referencedTable: $$RawInputsTableReferences
                              ._profileItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RawInputsTableReferences(
                                db,
                                table,
                                p0,
                              ).profileItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceRawInputId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RawInputsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawInputsTable,
      RawInput,
      $$RawInputsTableFilterComposer,
      $$RawInputsTableOrderingComposer,
      $$RawInputsTableAnnotationComposer,
      $$RawInputsTableCreateCompanionBuilder,
      $$RawInputsTableUpdateCompanionBuilder,
      (RawInput, $$RawInputsTableReferences),
      RawInput,
      PrefetchHooks Function({
        bool aiParseResultsRefs,
        bool extractedItemsRefs,
        bool tasksRefs,
        bool shortTermStatesRefs,
        bool lifeEventsRefs,
        bool profileItemsRefs,
      })
    >;
typedef $$AiParseResultsTableCreateCompanionBuilder =
    AiParseResultsCompanion Function({
      required String id,
      required String rawInputId,
      required String rawJson,
      required String validationState,
      Value<String?> errorMessage,
      Value<int> retryCount,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AiParseResultsTableUpdateCompanionBuilder =
    AiParseResultsCompanion Function({
      Value<String> id,
      Value<String> rawInputId,
      Value<String> rawJson,
      Value<String> validationState,
      Value<String?> errorMessage,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AiParseResultsTableReferences
    extends BaseReferences<_$AppDatabase, $AiParseResultsTable, AiParseResult> {
  $$AiParseResultsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RawInputsTable _rawInputIdTable(_$AppDatabase db) =>
      db.rawInputs.createAlias(
        $_aliasNameGenerator(db.aiParseResults.rawInputId, db.rawInputs.id),
      );

  $$RawInputsTableProcessedTableManager get rawInputId {
    final $_column = $_itemColumn<String>('raw_input_id')!;

    final manager = $$RawInputsTableTableManager(
      $_db,
      $_db.rawInputs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rawInputIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExtractedItemsTable, List<ExtractedItem>>
  _extractedItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.extractedItems,
    aliasName: $_aliasNameGenerator(
      db.aiParseResults.id,
      db.extractedItems.aiParseResultId,
    ),
  );

  $$ExtractedItemsTableProcessedTableManager get extractedItemsRefs {
    final manager = $$ExtractedItemsTableTableManager($_db, $_db.extractedItems)
        .filter(
          (f) => f.aiParseResultId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_extractedItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AiParseResultsTableFilterComposer
    extends Composer<_$AppDatabase, $AiParseResultsTable> {
  $$AiParseResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validationState => $composableBuilder(
    column: $table.validationState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RawInputsTableFilterComposer get rawInputId {
    final $$RawInputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableFilterComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> extractedItemsRefs(
    Expression<bool> Function($$ExtractedItemsTableFilterComposer f) f,
  ) {
    final $$ExtractedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.aiParseResultId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableFilterComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AiParseResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiParseResultsTable> {
  $$AiParseResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validationState => $composableBuilder(
    column: $table.validationState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RawInputsTableOrderingComposer get rawInputId {
    final $$RawInputsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableOrderingComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiParseResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiParseResultsTable> {
  $$AiParseResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<String> get validationState => $composableBuilder(
    column: $table.validationState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$RawInputsTableAnnotationComposer get rawInputId {
    final $$RawInputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableAnnotationComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> extractedItemsRefs<T extends Object>(
    Expression<T> Function($$ExtractedItemsTableAnnotationComposer a) f,
  ) {
    final $$ExtractedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.aiParseResultId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AiParseResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiParseResultsTable,
          AiParseResult,
          $$AiParseResultsTableFilterComposer,
          $$AiParseResultsTableOrderingComposer,
          $$AiParseResultsTableAnnotationComposer,
          $$AiParseResultsTableCreateCompanionBuilder,
          $$AiParseResultsTableUpdateCompanionBuilder,
          (AiParseResult, $$AiParseResultsTableReferences),
          AiParseResult,
          PrefetchHooks Function({bool rawInputId, bool extractedItemsRefs})
        > {
  $$AiParseResultsTableTableManager(
    _$AppDatabase db,
    $AiParseResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiParseResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiParseResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiParseResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rawInputId = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<String> validationState = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiParseResultsCompanion(
                id: id,
                rawInputId: rawInputId,
                rawJson: rawJson,
                validationState: validationState,
                errorMessage: errorMessage,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rawInputId,
                required String rawJson,
                required String validationState,
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AiParseResultsCompanion.insert(
                id: id,
                rawInputId: rawInputId,
                rawJson: rawJson,
                validationState: validationState,
                errorMessage: errorMessage,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AiParseResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({rawInputId = false, extractedItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (extractedItemsRefs) db.extractedItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (rawInputId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.rawInputId,
                                    referencedTable:
                                        $$AiParseResultsTableReferences
                                            ._rawInputIdTable(db),
                                    referencedColumn:
                                        $$AiParseResultsTableReferences
                                            ._rawInputIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (extractedItemsRefs)
                        await $_getPrefetchedData<
                          AiParseResult,
                          $AiParseResultsTable,
                          ExtractedItem
                        >(
                          currentTable: table,
                          referencedTable: $$AiParseResultsTableReferences
                              ._extractedItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AiParseResultsTableReferences(
                                db,
                                table,
                                p0,
                              ).extractedItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.aiParseResultId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AiParseResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiParseResultsTable,
      AiParseResult,
      $$AiParseResultsTableFilterComposer,
      $$AiParseResultsTableOrderingComposer,
      $$AiParseResultsTableAnnotationComposer,
      $$AiParseResultsTableCreateCompanionBuilder,
      $$AiParseResultsTableUpdateCompanionBuilder,
      (AiParseResult, $$AiParseResultsTableReferences),
      AiParseResult,
      PrefetchHooks Function({bool rawInputId, bool extractedItemsRefs})
    >;
typedef $$ExtractedItemsTableCreateCompanionBuilder =
    ExtractedItemsCompanion Function({
      required String id,
      required String rawInputId,
      required String aiParseResultId,
      required String type,
      Value<String?> title,
      Value<String?> content,
      required String sourceText,
      Value<String> tagsJson,
      required double confidence,
      required bool needUserConfirm,
      required String status,
      Value<DateTime?> expiresAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ExtractedItemsTableUpdateCompanionBuilder =
    ExtractedItemsCompanion Function({
      Value<String> id,
      Value<String> rawInputId,
      Value<String> aiParseResultId,
      Value<String> type,
      Value<String?> title,
      Value<String?> content,
      Value<String> sourceText,
      Value<String> tagsJson,
      Value<double> confidence,
      Value<bool> needUserConfirm,
      Value<String> status,
      Value<DateTime?> expiresAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ExtractedItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ExtractedItemsTable, ExtractedItem> {
  $$ExtractedItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RawInputsTable _rawInputIdTable(_$AppDatabase db) =>
      db.rawInputs.createAlias(
        $_aliasNameGenerator(db.extractedItems.rawInputId, db.rawInputs.id),
      );

  $$RawInputsTableProcessedTableManager get rawInputId {
    final $_column = $_itemColumn<String>('raw_input_id')!;

    final manager = $$RawInputsTableTableManager(
      $_db,
      $_db.rawInputs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rawInputIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AiParseResultsTable _aiParseResultIdTable(_$AppDatabase db) =>
      db.aiParseResults.createAlias(
        $_aliasNameGenerator(
          db.extractedItems.aiParseResultId,
          db.aiParseResults.id,
        ),
      );

  $$AiParseResultsTableProcessedTableManager get aiParseResultId {
    final $_column = $_itemColumn<String>('ai_parse_result_id')!;

    final manager = $$AiParseResultsTableTableManager(
      $_db,
      $_db.aiParseResults,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_aiParseResultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: $_aliasNameGenerator(
      db.extractedItems.id,
      db.tasks.sourceExtractedItemId,
    ),
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter(
      (f) => f.sourceExtractedItemId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShortTermStatesTable, List<ShortTermState>>
  _shortTermStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shortTermStates,
    aliasName: $_aliasNameGenerator(
      db.extractedItems.id,
      db.shortTermStates.sourceExtractedItemId,
    ),
  );

  $$ShortTermStatesTableProcessedTableManager get shortTermStatesRefs {
    final manager =
        $$ShortTermStatesTableTableManager($_db, $_db.shortTermStates).filter(
          (f) =>
              f.sourceExtractedItemId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _shortTermStatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LifeEventsTable, List<LifeEvent>>
  _lifeEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lifeEvents,
    aliasName: $_aliasNameGenerator(
      db.extractedItems.id,
      db.lifeEvents.sourceExtractedItemId,
    ),
  );

  $$LifeEventsTableProcessedTableManager get lifeEventsRefs {
    final manager = $$LifeEventsTableTableManager($_db, $_db.lifeEvents).filter(
      (f) => f.sourceExtractedItemId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_lifeEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProfileItemsTable, List<ProfileItem>>
  _profileItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.profileItems,
    aliasName: $_aliasNameGenerator(
      db.extractedItems.id,
      db.profileItems.sourceExtractedItemId,
    ),
  );

  $$ProfileItemsTableProcessedTableManager get profileItemsRefs {
    final manager = $$ProfileItemsTableTableManager($_db, $_db.profileItems)
        .filter(
          (f) =>
              f.sourceExtractedItemId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_profileItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExtractedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ExtractedItemsTable> {
  $$ExtractedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needUserConfirm => $composableBuilder(
    column: $table.needUserConfirm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RawInputsTableFilterComposer get rawInputId {
    final $$RawInputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableFilterComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AiParseResultsTableFilterComposer get aiParseResultId {
    final $$AiParseResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aiParseResultId,
      referencedTable: $db.aiParseResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiParseResultsTableFilterComposer(
            $db: $db,
            $table: $db.aiParseResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.sourceExtractedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shortTermStatesRefs(
    Expression<bool> Function($$ShortTermStatesTableFilterComposer f) f,
  ) {
    final $$ShortTermStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shortTermStates,
      getReferencedColumn: (t) => t.sourceExtractedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShortTermStatesTableFilterComposer(
            $db: $db,
            $table: $db.shortTermStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lifeEventsRefs(
    Expression<bool> Function($$LifeEventsTableFilterComposer f) f,
  ) {
    final $$LifeEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifeEvents,
      getReferencedColumn: (t) => t.sourceExtractedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifeEventsTableFilterComposer(
            $db: $db,
            $table: $db.lifeEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> profileItemsRefs(
    Expression<bool> Function($$ProfileItemsTableFilterComposer f) f,
  ) {
    final $$ProfileItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileItems,
      getReferencedColumn: (t) => t.sourceExtractedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileItemsTableFilterComposer(
            $db: $db,
            $table: $db.profileItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExtractedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtractedItemsTable> {
  $$ExtractedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needUserConfirm => $composableBuilder(
    column: $table.needUserConfirm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RawInputsTableOrderingComposer get rawInputId {
    final $$RawInputsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableOrderingComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AiParseResultsTableOrderingComposer get aiParseResultId {
    final $$AiParseResultsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aiParseResultId,
      referencedTable: $db.aiParseResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiParseResultsTableOrderingComposer(
            $db: $db,
            $table: $db.aiParseResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtractedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtractedItemsTable> {
  $$ExtractedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needUserConfirm => $composableBuilder(
    column: $table.needUserConfirm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RawInputsTableAnnotationComposer get rawInputId {
    final $$RawInputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableAnnotationComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AiParseResultsTableAnnotationComposer get aiParseResultId {
    final $$AiParseResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aiParseResultId,
      referencedTable: $db.aiParseResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiParseResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.aiParseResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.sourceExtractedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shortTermStatesRefs<T extends Object>(
    Expression<T> Function($$ShortTermStatesTableAnnotationComposer a) f,
  ) {
    final $$ShortTermStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shortTermStates,
      getReferencedColumn: (t) => t.sourceExtractedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShortTermStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.shortTermStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lifeEventsRefs<T extends Object>(
    Expression<T> Function($$LifeEventsTableAnnotationComposer a) f,
  ) {
    final $$LifeEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifeEvents,
      getReferencedColumn: (t) => t.sourceExtractedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifeEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.lifeEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> profileItemsRefs<T extends Object>(
    Expression<T> Function($$ProfileItemsTableAnnotationComposer a) f,
  ) {
    final $$ProfileItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileItems,
      getReferencedColumn: (t) => t.sourceExtractedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.profileItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExtractedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtractedItemsTable,
          ExtractedItem,
          $$ExtractedItemsTableFilterComposer,
          $$ExtractedItemsTableOrderingComposer,
          $$ExtractedItemsTableAnnotationComposer,
          $$ExtractedItemsTableCreateCompanionBuilder,
          $$ExtractedItemsTableUpdateCompanionBuilder,
          (ExtractedItem, $$ExtractedItemsTableReferences),
          ExtractedItem,
          PrefetchHooks Function({
            bool rawInputId,
            bool aiParseResultId,
            bool tasksRefs,
            bool shortTermStatesRefs,
            bool lifeEventsRefs,
            bool profileItemsRefs,
          })
        > {
  $$ExtractedItemsTableTableManager(
    _$AppDatabase db,
    $ExtractedItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtractedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtractedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtractedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rawInputId = const Value.absent(),
                Value<String> aiParseResultId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> sourceText = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<bool> needUserConfirm = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtractedItemsCompanion(
                id: id,
                rawInputId: rawInputId,
                aiParseResultId: aiParseResultId,
                type: type,
                title: title,
                content: content,
                sourceText: sourceText,
                tagsJson: tagsJson,
                confidence: confidence,
                needUserConfirm: needUserConfirm,
                status: status,
                expiresAt: expiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rawInputId,
                required String aiParseResultId,
                required String type,
                Value<String?> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                required String sourceText,
                Value<String> tagsJson = const Value.absent(),
                required double confidence,
                required bool needUserConfirm,
                required String status,
                Value<DateTime?> expiresAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExtractedItemsCompanion.insert(
                id: id,
                rawInputId: rawInputId,
                aiParseResultId: aiParseResultId,
                type: type,
                title: title,
                content: content,
                sourceText: sourceText,
                tagsJson: tagsJson,
                confidence: confidence,
                needUserConfirm: needUserConfirm,
                status: status,
                expiresAt: expiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExtractedItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                rawInputId = false,
                aiParseResultId = false,
                tasksRefs = false,
                shortTermStatesRefs = false,
                lifeEventsRefs = false,
                profileItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tasksRefs) db.tasks,
                    if (shortTermStatesRefs) db.shortTermStates,
                    if (lifeEventsRefs) db.lifeEvents,
                    if (profileItemsRefs) db.profileItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (rawInputId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.rawInputId,
                                    referencedTable:
                                        $$ExtractedItemsTableReferences
                                            ._rawInputIdTable(db),
                                    referencedColumn:
                                        $$ExtractedItemsTableReferences
                                            ._rawInputIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (aiParseResultId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.aiParseResultId,
                                    referencedTable:
                                        $$ExtractedItemsTableReferences
                                            ._aiParseResultIdTable(db),
                                    referencedColumn:
                                        $$ExtractedItemsTableReferences
                                            ._aiParseResultIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tasksRefs)
                        await $_getPrefetchedData<
                          ExtractedItem,
                          $ExtractedItemsTable,
                          Task
                        >(
                          currentTable: table,
                          referencedTable: $$ExtractedItemsTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExtractedItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceExtractedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shortTermStatesRefs)
                        await $_getPrefetchedData<
                          ExtractedItem,
                          $ExtractedItemsTable,
                          ShortTermState
                        >(
                          currentTable: table,
                          referencedTable: $$ExtractedItemsTableReferences
                              ._shortTermStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExtractedItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).shortTermStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceExtractedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lifeEventsRefs)
                        await $_getPrefetchedData<
                          ExtractedItem,
                          $ExtractedItemsTable,
                          LifeEvent
                        >(
                          currentTable: table,
                          referencedTable: $$ExtractedItemsTableReferences
                              ._lifeEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExtractedItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).lifeEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceExtractedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (profileItemsRefs)
                        await $_getPrefetchedData<
                          ExtractedItem,
                          $ExtractedItemsTable,
                          ProfileItem
                        >(
                          currentTable: table,
                          referencedTable: $$ExtractedItemsTableReferences
                              ._profileItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExtractedItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).profileItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceExtractedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExtractedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtractedItemsTable,
      ExtractedItem,
      $$ExtractedItemsTableFilterComposer,
      $$ExtractedItemsTableOrderingComposer,
      $$ExtractedItemsTableAnnotationComposer,
      $$ExtractedItemsTableCreateCompanionBuilder,
      $$ExtractedItemsTableUpdateCompanionBuilder,
      (ExtractedItem, $$ExtractedItemsTableReferences),
      ExtractedItem,
      PrefetchHooks Function({
        bool rawInputId,
        bool aiParseResultId,
        bool tasksRefs,
        bool shortTermStatesRefs,
        bool lifeEventsRefs,
        bool profileItemsRefs,
      })
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String sourceRawInputId,
      required String sourceExtractedItemId,
      required String title,
      Value<String?> description,
      Value<String?> dueTimeText,
      Value<DateTime?> dueTime,
      Value<String> priority,
      required String status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> sourceRawInputId,
      Value<String> sourceExtractedItemId,
      Value<String> title,
      Value<String?> description,
      Value<String?> dueTimeText,
      Value<DateTime?> dueTime,
      Value<String> priority,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RawInputsTable _sourceRawInputIdTable(_$AppDatabase db) =>
      db.rawInputs.createAlias(
        $_aliasNameGenerator(db.tasks.sourceRawInputId, db.rawInputs.id),
      );

  $$RawInputsTableProcessedTableManager get sourceRawInputId {
    final $_column = $_itemColumn<String>('source_raw_input_id')!;

    final manager = $$RawInputsTableTableManager(
      $_db,
      $_db.rawInputs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceRawInputIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExtractedItemsTable _sourceExtractedItemIdTable(_$AppDatabase db) =>
      db.extractedItems.createAlias(
        $_aliasNameGenerator(
          db.tasks.sourceExtractedItemId,
          db.extractedItems.id,
        ),
      );

  $$ExtractedItemsTableProcessedTableManager get sourceExtractedItemId {
    final $_column = $_itemColumn<String>('source_extracted_item_id')!;

    final manager = $$ExtractedItemsTableTableManager(
      $_db,
      $_db.extractedItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _sourceExtractedItemIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueTimeText => $composableBuilder(
    column: $table.dueTimeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RawInputsTableFilterComposer get sourceRawInputId {
    final $$RawInputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableFilterComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableFilterComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableFilterComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueTimeText => $composableBuilder(
    column: $table.dueTimeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RawInputsTableOrderingComposer get sourceRawInputId {
    final $$RawInputsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableOrderingComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableOrderingComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableOrderingComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueTimeText => $composableBuilder(
    column: $table.dueTimeText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueTime =>
      $composableBuilder(column: $table.dueTime, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RawInputsTableAnnotationComposer get sourceRawInputId {
    final $$RawInputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableAnnotationComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableAnnotationComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool sourceRawInputId,
            bool sourceExtractedItemId,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceRawInputId = const Value.absent(),
                Value<String> sourceExtractedItemId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> dueTimeText = const Value.absent(),
                Value<DateTime?> dueTime = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                sourceRawInputId: sourceRawInputId,
                sourceExtractedItemId: sourceExtractedItemId,
                title: title,
                description: description,
                dueTimeText: dueTimeText,
                dueTime: dueTime,
                priority: priority,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceRawInputId,
                required String sourceExtractedItemId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> dueTimeText = const Value.absent(),
                Value<DateTime?> dueTime = const Value.absent(),
                Value<String> priority = const Value.absent(),
                required String status,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                sourceRawInputId: sourceRawInputId,
                sourceExtractedItemId: sourceExtractedItemId,
                title: title,
                description: description,
                dueTimeText: dueTimeText,
                dueTime: dueTime,
                priority: priority,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceRawInputId = false, sourceExtractedItemId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceRawInputId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceRawInputId,
                                    referencedTable: $$TasksTableReferences
                                        ._sourceRawInputIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._sourceRawInputIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (sourceExtractedItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceExtractedItemId,
                                    referencedTable: $$TasksTableReferences
                                        ._sourceExtractedItemIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._sourceExtractedItemIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool sourceRawInputId,
        bool sourceExtractedItemId,
      })
    >;
typedef $$ShortTermStatesTableCreateCompanionBuilder =
    ShortTermStatesCompanion Function({
      required String id,
      required String sourceRawInputId,
      required String sourceExtractedItemId,
      required String content,
      Value<String> tagsJson,
      required DateTime validUntil,
      required String status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ShortTermStatesTableUpdateCompanionBuilder =
    ShortTermStatesCompanion Function({
      Value<String> id,
      Value<String> sourceRawInputId,
      Value<String> sourceExtractedItemId,
      Value<String> content,
      Value<String> tagsJson,
      Value<DateTime> validUntil,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ShortTermStatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ShortTermStatesTable, ShortTermState> {
  $$ShortTermStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RawInputsTable _sourceRawInputIdTable(_$AppDatabase db) =>
      db.rawInputs.createAlias(
        $_aliasNameGenerator(
          db.shortTermStates.sourceRawInputId,
          db.rawInputs.id,
        ),
      );

  $$RawInputsTableProcessedTableManager get sourceRawInputId {
    final $_column = $_itemColumn<String>('source_raw_input_id')!;

    final manager = $$RawInputsTableTableManager(
      $_db,
      $_db.rawInputs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceRawInputIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExtractedItemsTable _sourceExtractedItemIdTable(_$AppDatabase db) =>
      db.extractedItems.createAlias(
        $_aliasNameGenerator(
          db.shortTermStates.sourceExtractedItemId,
          db.extractedItems.id,
        ),
      );

  $$ExtractedItemsTableProcessedTableManager get sourceExtractedItemId {
    final $_column = $_itemColumn<String>('source_extracted_item_id')!;

    final manager = $$ExtractedItemsTableTableManager(
      $_db,
      $_db.extractedItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _sourceExtractedItemIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShortTermStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ShortTermStatesTable> {
  $$ShortTermStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RawInputsTableFilterComposer get sourceRawInputId {
    final $$RawInputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableFilterComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableFilterComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableFilterComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShortTermStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShortTermStatesTable> {
  $$ShortTermStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RawInputsTableOrderingComposer get sourceRawInputId {
    final $$RawInputsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableOrderingComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableOrderingComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableOrderingComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShortTermStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShortTermStatesTable> {
  $$ShortTermStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RawInputsTableAnnotationComposer get sourceRawInputId {
    final $$RawInputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableAnnotationComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableAnnotationComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShortTermStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShortTermStatesTable,
          ShortTermState,
          $$ShortTermStatesTableFilterComposer,
          $$ShortTermStatesTableOrderingComposer,
          $$ShortTermStatesTableAnnotationComposer,
          $$ShortTermStatesTableCreateCompanionBuilder,
          $$ShortTermStatesTableUpdateCompanionBuilder,
          (ShortTermState, $$ShortTermStatesTableReferences),
          ShortTermState,
          PrefetchHooks Function({
            bool sourceRawInputId,
            bool sourceExtractedItemId,
          })
        > {
  $$ShortTermStatesTableTableManager(
    _$AppDatabase db,
    $ShortTermStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShortTermStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShortTermStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShortTermStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceRawInputId = const Value.absent(),
                Value<String> sourceExtractedItemId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<DateTime> validUntil = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShortTermStatesCompanion(
                id: id,
                sourceRawInputId: sourceRawInputId,
                sourceExtractedItemId: sourceExtractedItemId,
                content: content,
                tagsJson: tagsJson,
                validUntil: validUntil,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceRawInputId,
                required String sourceExtractedItemId,
                required String content,
                Value<String> tagsJson = const Value.absent(),
                required DateTime validUntil,
                required String status,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ShortTermStatesCompanion.insert(
                id: id,
                sourceRawInputId: sourceRawInputId,
                sourceExtractedItemId: sourceExtractedItemId,
                content: content,
                tagsJson: tagsJson,
                validUntil: validUntil,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShortTermStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceRawInputId = false, sourceExtractedItemId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceRawInputId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceRawInputId,
                                    referencedTable:
                                        $$ShortTermStatesTableReferences
                                            ._sourceRawInputIdTable(db),
                                    referencedColumn:
                                        $$ShortTermStatesTableReferences
                                            ._sourceRawInputIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sourceExtractedItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceExtractedItemId,
                                    referencedTable:
                                        $$ShortTermStatesTableReferences
                                            ._sourceExtractedItemIdTable(db),
                                    referencedColumn:
                                        $$ShortTermStatesTableReferences
                                            ._sourceExtractedItemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ShortTermStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShortTermStatesTable,
      ShortTermState,
      $$ShortTermStatesTableFilterComposer,
      $$ShortTermStatesTableOrderingComposer,
      $$ShortTermStatesTableAnnotationComposer,
      $$ShortTermStatesTableCreateCompanionBuilder,
      $$ShortTermStatesTableUpdateCompanionBuilder,
      (ShortTermState, $$ShortTermStatesTableReferences),
      ShortTermState,
      PrefetchHooks Function({
        bool sourceRawInputId,
        bool sourceExtractedItemId,
      })
    >;
typedef $$LifeEventsTableCreateCompanionBuilder =
    LifeEventsCompanion Function({
      required String id,
      required String sourceRawInputId,
      required String sourceExtractedItemId,
      required String content,
      Value<String> tagsJson,
      required String status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LifeEventsTableUpdateCompanionBuilder =
    LifeEventsCompanion Function({
      Value<String> id,
      Value<String> sourceRawInputId,
      Value<String> sourceExtractedItemId,
      Value<String> content,
      Value<String> tagsJson,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LifeEventsTableReferences
    extends BaseReferences<_$AppDatabase, $LifeEventsTable, LifeEvent> {
  $$LifeEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RawInputsTable _sourceRawInputIdTable(_$AppDatabase db) =>
      db.rawInputs.createAlias(
        $_aliasNameGenerator(db.lifeEvents.sourceRawInputId, db.rawInputs.id),
      );

  $$RawInputsTableProcessedTableManager get sourceRawInputId {
    final $_column = $_itemColumn<String>('source_raw_input_id')!;

    final manager = $$RawInputsTableTableManager(
      $_db,
      $_db.rawInputs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceRawInputIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExtractedItemsTable _sourceExtractedItemIdTable(_$AppDatabase db) =>
      db.extractedItems.createAlias(
        $_aliasNameGenerator(
          db.lifeEvents.sourceExtractedItemId,
          db.extractedItems.id,
        ),
      );

  $$ExtractedItemsTableProcessedTableManager get sourceExtractedItemId {
    final $_column = $_itemColumn<String>('source_extracted_item_id')!;

    final manager = $$ExtractedItemsTableTableManager(
      $_db,
      $_db.extractedItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _sourceExtractedItemIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LifeEventsTableFilterComposer
    extends Composer<_$AppDatabase, $LifeEventsTable> {
  $$LifeEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RawInputsTableFilterComposer get sourceRawInputId {
    final $$RawInputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableFilterComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableFilterComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableFilterComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifeEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $LifeEventsTable> {
  $$LifeEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RawInputsTableOrderingComposer get sourceRawInputId {
    final $$RawInputsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableOrderingComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableOrderingComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableOrderingComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifeEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifeEventsTable> {
  $$LifeEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RawInputsTableAnnotationComposer get sourceRawInputId {
    final $$RawInputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableAnnotationComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableAnnotationComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifeEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LifeEventsTable,
          LifeEvent,
          $$LifeEventsTableFilterComposer,
          $$LifeEventsTableOrderingComposer,
          $$LifeEventsTableAnnotationComposer,
          $$LifeEventsTableCreateCompanionBuilder,
          $$LifeEventsTableUpdateCompanionBuilder,
          (LifeEvent, $$LifeEventsTableReferences),
          LifeEvent,
          PrefetchHooks Function({
            bool sourceRawInputId,
            bool sourceExtractedItemId,
          })
        > {
  $$LifeEventsTableTableManager(_$AppDatabase db, $LifeEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifeEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LifeEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifeEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceRawInputId = const Value.absent(),
                Value<String> sourceExtractedItemId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LifeEventsCompanion(
                id: id,
                sourceRawInputId: sourceRawInputId,
                sourceExtractedItemId: sourceExtractedItemId,
                content: content,
                tagsJson: tagsJson,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceRawInputId,
                required String sourceExtractedItemId,
                required String content,
                Value<String> tagsJson = const Value.absent(),
                required String status,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LifeEventsCompanion.insert(
                id: id,
                sourceRawInputId: sourceRawInputId,
                sourceExtractedItemId: sourceExtractedItemId,
                content: content,
                tagsJson: tagsJson,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LifeEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceRawInputId = false, sourceExtractedItemId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceRawInputId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceRawInputId,
                                    referencedTable: $$LifeEventsTableReferences
                                        ._sourceRawInputIdTable(db),
                                    referencedColumn:
                                        $$LifeEventsTableReferences
                                            ._sourceRawInputIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sourceExtractedItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceExtractedItemId,
                                    referencedTable: $$LifeEventsTableReferences
                                        ._sourceExtractedItemIdTable(db),
                                    referencedColumn:
                                        $$LifeEventsTableReferences
                                            ._sourceExtractedItemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$LifeEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LifeEventsTable,
      LifeEvent,
      $$LifeEventsTableFilterComposer,
      $$LifeEventsTableOrderingComposer,
      $$LifeEventsTableAnnotationComposer,
      $$LifeEventsTableCreateCompanionBuilder,
      $$LifeEventsTableUpdateCompanionBuilder,
      (LifeEvent, $$LifeEventsTableReferences),
      LifeEvent,
      PrefetchHooks Function({
        bool sourceRawInputId,
        bool sourceExtractedItemId,
      })
    >;
typedef $$ProfileItemsTableCreateCompanionBuilder =
    ProfileItemsCompanion Function({
      required String id,
      required String sourceRawInputId,
      required String sourceExtractedItemId,
      required String content,
      Value<String?> category,
      Value<String> tagsJson,
      required double confidence,
      required String status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProfileItemsTableUpdateCompanionBuilder =
    ProfileItemsCompanion Function({
      Value<String> id,
      Value<String> sourceRawInputId,
      Value<String> sourceExtractedItemId,
      Value<String> content,
      Value<String?> category,
      Value<String> tagsJson,
      Value<double> confidence,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ProfileItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ProfileItemsTable, ProfileItem> {
  $$ProfileItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RawInputsTable _sourceRawInputIdTable(_$AppDatabase db) =>
      db.rawInputs.createAlias(
        $_aliasNameGenerator(db.profileItems.sourceRawInputId, db.rawInputs.id),
      );

  $$RawInputsTableProcessedTableManager get sourceRawInputId {
    final $_column = $_itemColumn<String>('source_raw_input_id')!;

    final manager = $$RawInputsTableTableManager(
      $_db,
      $_db.rawInputs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceRawInputIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExtractedItemsTable _sourceExtractedItemIdTable(_$AppDatabase db) =>
      db.extractedItems.createAlias(
        $_aliasNameGenerator(
          db.profileItems.sourceExtractedItemId,
          db.extractedItems.id,
        ),
      );

  $$ExtractedItemsTableProcessedTableManager get sourceExtractedItemId {
    final $_column = $_itemColumn<String>('source_extracted_item_id')!;

    final manager = $$ExtractedItemsTableTableManager(
      $_db,
      $_db.extractedItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _sourceExtractedItemIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProfileItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileItemsTable> {
  $$ProfileItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RawInputsTableFilterComposer get sourceRawInputId {
    final $$RawInputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableFilterComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableFilterComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableFilterComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileItemsTable> {
  $$ProfileItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RawInputsTableOrderingComposer get sourceRawInputId {
    final $$RawInputsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableOrderingComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableOrderingComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableOrderingComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileItemsTable> {
  $$ProfileItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RawInputsTableAnnotationComposer get sourceRawInputId {
    final $$RawInputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceRawInputId,
      referencedTable: $db.rawInputs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawInputsTableAnnotationComposer(
            $db: $db,
            $table: $db.rawInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedItemsTableAnnotationComposer get sourceExtractedItemId {
    final $$ExtractedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceExtractedItemId,
      referencedTable: $db.extractedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.extractedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileItemsTable,
          ProfileItem,
          $$ProfileItemsTableFilterComposer,
          $$ProfileItemsTableOrderingComposer,
          $$ProfileItemsTableAnnotationComposer,
          $$ProfileItemsTableCreateCompanionBuilder,
          $$ProfileItemsTableUpdateCompanionBuilder,
          (ProfileItem, $$ProfileItemsTableReferences),
          ProfileItem,
          PrefetchHooks Function({
            bool sourceRawInputId,
            bool sourceExtractedItemId,
          })
        > {
  $$ProfileItemsTableTableManager(_$AppDatabase db, $ProfileItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceRawInputId = const Value.absent(),
                Value<String> sourceExtractedItemId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileItemsCompanion(
                id: id,
                sourceRawInputId: sourceRawInputId,
                sourceExtractedItemId: sourceExtractedItemId,
                content: content,
                category: category,
                tagsJson: tagsJson,
                confidence: confidence,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceRawInputId,
                required String sourceExtractedItemId,
                required String content,
                Value<String?> category = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                required double confidence,
                required String status,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfileItemsCompanion.insert(
                id: id,
                sourceRawInputId: sourceRawInputId,
                sourceExtractedItemId: sourceExtractedItemId,
                content: content,
                category: category,
                tagsJson: tagsJson,
                confidence: confidence,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfileItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceRawInputId = false, sourceExtractedItemId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceRawInputId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceRawInputId,
                                    referencedTable:
                                        $$ProfileItemsTableReferences
                                            ._sourceRawInputIdTable(db),
                                    referencedColumn:
                                        $$ProfileItemsTableReferences
                                            ._sourceRawInputIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sourceExtractedItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceExtractedItemId,
                                    referencedTable:
                                        $$ProfileItemsTableReferences
                                            ._sourceExtractedItemIdTable(db),
                                    referencedColumn:
                                        $$ProfileItemsTableReferences
                                            ._sourceExtractedItemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ProfileItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileItemsTable,
      ProfileItem,
      $$ProfileItemsTableFilterComposer,
      $$ProfileItemsTableOrderingComposer,
      $$ProfileItemsTableAnnotationComposer,
      $$ProfileItemsTableCreateCompanionBuilder,
      $$ProfileItemsTableUpdateCompanionBuilder,
      (ProfileItem, $$ProfileItemsTableReferences),
      ProfileItem,
      PrefetchHooks Function({
        bool sourceRawInputId,
        bool sourceExtractedItemId,
      })
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RawInputsTableTableManager get rawInputs =>
      $$RawInputsTableTableManager(_db, _db.rawInputs);
  $$AiParseResultsTableTableManager get aiParseResults =>
      $$AiParseResultsTableTableManager(_db, _db.aiParseResults);
  $$ExtractedItemsTableTableManager get extractedItems =>
      $$ExtractedItemsTableTableManager(_db, _db.extractedItems);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$ShortTermStatesTableTableManager get shortTermStates =>
      $$ShortTermStatesTableTableManager(_db, _db.shortTermStates);
  $$LifeEventsTableTableManager get lifeEvents =>
      $$LifeEventsTableTableManager(_db, _db.lifeEvents);
  $$ProfileItemsTableTableManager get profileItems =>
      $$ProfileItemsTableTableManager(_db, _db.profileItems);
}
