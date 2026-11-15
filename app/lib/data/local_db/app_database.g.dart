// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  @override
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  List<GeneratedColumn> get $columns => [settingKey, valueJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
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
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String settingKey;
  final String valueJson;
  final DateTime updatedAt;
  const SettingsEntry({
    required this.settingKey,
    required this.valueJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      settingKey: Value(settingKey),
      valueJson: Value(valueJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      settingKey: serializer.fromJson<String>(json['settingKey']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingKey': serializer.toJson<String>(settingKey),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SettingsEntry copyWith({
    String? settingKey,
    String? valueJson,
    DateTime? updatedAt,
  }) => SettingsEntry(
    settingKey: settingKey ?? this.settingKey,
    valueJson: valueJson ?? this.valueJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('settingKey: $settingKey, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, valueJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.settingKey == this.settingKey &&
          other.valueJson == this.valueJson &&
          other.updatedAt == this.updatedAt);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> settingKey;
  final Value<String> valueJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.settingKey = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String settingKey,
    required String valueJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       valueJson = Value(valueJson),
       updatedAt = Value(updatedAt);
  static Insertable<SettingsEntry> custom({
    Expression<String>? settingKey,
    Expression<String>? valueJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? valueJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsEntriesCompanion(
      settingKey: settingKey ?? this.settingKey,
      valueJson: valueJson ?? this.valueJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
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
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressDocumentsTable extends ProgressDocuments
    with TableInfo<$ProgressDocumentsTable, ProgressDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentKeyMeta = const VerificationMeta(
    'documentKey',
  );
  @override
  late final GeneratedColumn<String> documentKey = GeneratedColumn<String>(
    'document_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  List<GeneratedColumn> get $columns => [documentKey, payloadJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_key')) {
      context.handle(
        _documentKeyMeta,
        documentKey.isAcceptableOrUnknown(
          data['document_key']!,
          _documentKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
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
  Set<GeneratedColumn> get $primaryKey => {documentKey};
  @override
  ProgressDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressDocument(
      documentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProgressDocumentsTable createAlias(String alias) {
    return $ProgressDocumentsTable(attachedDatabase, alias);
  }
}

class ProgressDocument extends DataClass
    implements Insertable<ProgressDocument> {
  final String documentKey;
  final String payloadJson;
  final DateTime updatedAt;
  const ProgressDocument({
    required this.documentKey,
    required this.payloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_key'] = Variable<String>(documentKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProgressDocumentsCompanion toCompanion(bool nullToAbsent) {
    return ProgressDocumentsCompanion(
      documentKey: Value(documentKey),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProgressDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressDocument(
      documentKey: serializer.fromJson<String>(json['documentKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentKey': serializer.toJson<String>(documentKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProgressDocument copyWith({
    String? documentKey,
    String? payloadJson,
    DateTime? updatedAt,
  }) => ProgressDocument(
    documentKey: documentKey ?? this.documentKey,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProgressDocument copyWithCompanion(ProgressDocumentsCompanion data) {
    return ProgressDocument(
      documentKey: data.documentKey.present
          ? data.documentKey.value
          : this.documentKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressDocument(')
          ..write('documentKey: $documentKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentKey, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressDocument &&
          other.documentKey == this.documentKey &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class ProgressDocumentsCompanion extends UpdateCompanion<ProgressDocument> {
  final Value<String> documentKey;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProgressDocumentsCompanion({
    this.documentKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressDocumentsCompanion.insert({
    required String documentKey,
    required String payloadJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : documentKey = Value(documentKey),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<ProgressDocument> custom({
    Expression<String>? documentKey,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentKey != null) 'document_key': documentKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressDocumentsCompanion copyWith({
    Value<String>? documentKey,
    Value<String>? payloadJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProgressDocumentsCompanion(
      documentKey: documentKey ?? this.documentKey,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentKey.present) {
      map['document_key'] = Variable<String>(documentKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
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
    return (StringBuffer('ProgressDocumentsCompanion(')
          ..write('documentKey: $documentKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LatestAnimeSearchTable extends LatestAnimeSearch
    with TableInfo<$LatestAnimeSearchTable, LatestAnimeSearchData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LatestAnimeSearchTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchQueryMeta = const VerificationMeta(
    'searchQuery',
  );
  @override
  late final GeneratedColumn<String> searchQuery = GeneratedColumn<String>(
    'search_query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perPageMeta = const VerificationMeta(
    'perPage',
  );
  @override
  late final GeneratedColumn<int> perPage = GeneratedColumn<int>(
    'per_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    slot,
    searchQuery,
    page,
    perPage,
    resultJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'latest_anime_search';
  @override
  VerificationContext validateIntegrity(
    Insertable<LatestAnimeSearchData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('search_query')) {
      context.handle(
        _searchQueryMeta,
        searchQuery.isAcceptableOrUnknown(
          data['search_query']!,
          _searchQueryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_searchQueryMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('per_page')) {
      context.handle(
        _perPageMeta,
        perPage.isAcceptableOrUnknown(data['per_page']!, _perPageMeta),
      );
    } else if (isInserting) {
      context.missing(_perPageMeta);
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_resultJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slot};
  @override
  LatestAnimeSearchData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LatestAnimeSearchData(
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      searchQuery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_query'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      perPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}per_page'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $LatestAnimeSearchTable createAlias(String alias) {
    return $LatestAnimeSearchTable(attachedDatabase, alias);
  }
}

class LatestAnimeSearchData extends DataClass
    implements Insertable<LatestAnimeSearchData> {
  final String slot;
  final String searchQuery;
  final int page;
  final int perPage;
  final String resultJson;
  final DateTime cachedAt;
  const LatestAnimeSearchData({
    required this.slot,
    required this.searchQuery,
    required this.page,
    required this.perPage,
    required this.resultJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slot'] = Variable<String>(slot);
    map['search_query'] = Variable<String>(searchQuery);
    map['page'] = Variable<int>(page);
    map['per_page'] = Variable<int>(perPage);
    map['result_json'] = Variable<String>(resultJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LatestAnimeSearchCompanion toCompanion(bool nullToAbsent) {
    return LatestAnimeSearchCompanion(
      slot: Value(slot),
      searchQuery: Value(searchQuery),
      page: Value(page),
      perPage: Value(perPage),
      resultJson: Value(resultJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory LatestAnimeSearchData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LatestAnimeSearchData(
      slot: serializer.fromJson<String>(json['slot']),
      searchQuery: serializer.fromJson<String>(json['searchQuery']),
      page: serializer.fromJson<int>(json['page']),
      perPage: serializer.fromJson<int>(json['perPage']),
      resultJson: serializer.fromJson<String>(json['resultJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slot': serializer.toJson<String>(slot),
      'searchQuery': serializer.toJson<String>(searchQuery),
      'page': serializer.toJson<int>(page),
      'perPage': serializer.toJson<int>(perPage),
      'resultJson': serializer.toJson<String>(resultJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LatestAnimeSearchData copyWith({
    String? slot,
    String? searchQuery,
    int? page,
    int? perPage,
    String? resultJson,
    DateTime? cachedAt,
  }) => LatestAnimeSearchData(
    slot: slot ?? this.slot,
    searchQuery: searchQuery ?? this.searchQuery,
    page: page ?? this.page,
    perPage: perPage ?? this.perPage,
    resultJson: resultJson ?? this.resultJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  LatestAnimeSearchData copyWithCompanion(LatestAnimeSearchCompanion data) {
    return LatestAnimeSearchData(
      slot: data.slot.present ? data.slot.value : this.slot,
      searchQuery: data.searchQuery.present
          ? data.searchQuery.value
          : this.searchQuery,
      page: data.page.present ? data.page.value : this.page,
      perPage: data.perPage.present ? data.perPage.value : this.perPage,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LatestAnimeSearchData(')
          ..write('slot: $slot, ')
          ..write('searchQuery: $searchQuery, ')
          ..write('page: $page, ')
          ..write('perPage: $perPage, ')
          ..write('resultJson: $resultJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(slot, searchQuery, page, perPage, resultJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LatestAnimeSearchData &&
          other.slot == this.slot &&
          other.searchQuery == this.searchQuery &&
          other.page == this.page &&
          other.perPage == this.perPage &&
          other.resultJson == this.resultJson &&
          other.cachedAt == this.cachedAt);
}

class LatestAnimeSearchCompanion
    extends UpdateCompanion<LatestAnimeSearchData> {
  final Value<String> slot;
  final Value<String> searchQuery;
  final Value<int> page;
  final Value<int> perPage;
  final Value<String> resultJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const LatestAnimeSearchCompanion({
    this.slot = const Value.absent(),
    this.searchQuery = const Value.absent(),
    this.page = const Value.absent(),
    this.perPage = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LatestAnimeSearchCompanion.insert({
    required String slot,
    required String searchQuery,
    required int page,
    required int perPage,
    required String resultJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : slot = Value(slot),
       searchQuery = Value(searchQuery),
       page = Value(page),
       perPage = Value(perPage),
       resultJson = Value(resultJson),
       cachedAt = Value(cachedAt);
  static Insertable<LatestAnimeSearchData> custom({
    Expression<String>? slot,
    Expression<String>? searchQuery,
    Expression<int>? page,
    Expression<int>? perPage,
    Expression<String>? resultJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slot != null) 'slot': slot,
      if (searchQuery != null) 'search_query': searchQuery,
      if (page != null) 'page': page,
      if (perPage != null) 'per_page': perPage,
      if (resultJson != null) 'result_json': resultJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LatestAnimeSearchCompanion copyWith({
    Value<String>? slot,
    Value<String>? searchQuery,
    Value<int>? page,
    Value<int>? perPage,
    Value<String>? resultJson,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return LatestAnimeSearchCompanion(
      slot: slot ?? this.slot,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      resultJson: resultJson ?? this.resultJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (searchQuery.present) {
      map['search_query'] = Variable<String>(searchQuery.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (perPage.present) {
      map['per_page'] = Variable<int>(perPage.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LatestAnimeSearchCompanion(')
          ..write('slot: $slot, ')
          ..write('searchQuery: $searchQuery, ')
          ..write('page: $page, ')
          ..write('perPage: $perPage, ')
          ..write('resultJson: $resultJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackProgressEntriesTable extends PlaybackProgressEntries
    with TableInfo<$PlaybackProgressEntriesTable, PlaybackProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
    'episode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionMeta = const VerificationMeta(
    'completion',
  );
  @override
  late final GeneratedColumn<String> completion = GeneratedColumn<String>(
    'completion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    contentId,
    episodeId,
    positionMs,
    durationMs,
    updatedAtUtc,
    completion,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_progress_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackProgressEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMsMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('completion')) {
      context.handle(
        _completionMeta,
        completion.isAcceptableOrUnknown(data['completion']!, _completionMeta),
      );
    } else if (isInserting) {
      context.missing(_completionMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contentId, episodeId};
  @override
  PlaybackProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackProgressEntry(
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      completion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $PlaybackProgressEntriesTable createAlias(String alias) {
    return $PlaybackProgressEntriesTable(attachedDatabase, alias);
  }
}

class PlaybackProgressEntry extends DataClass
    implements Insertable<PlaybackProgressEntry> {
  final String contentId;
  final String episodeId;
  final int positionMs;
  final int? durationMs;
  final DateTime updatedAtUtc;
  final String completion;
  final int revision;
  const PlaybackProgressEntry({
    required this.contentId,
    required this.episodeId,
    required this.positionMs,
    this.durationMs,
    required this.updatedAtUtc,
    required this.completion,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_id'] = Variable<String>(contentId);
    map['episode_id'] = Variable<String>(episodeId);
    map['position_ms'] = Variable<int>(positionMs);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    map['completion'] = Variable<String>(completion);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  PlaybackProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlaybackProgressEntriesCompanion(
      contentId: Value(contentId),
      episodeId: Value(episodeId),
      positionMs: Value(positionMs),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      updatedAtUtc: Value(updatedAtUtc),
      completion: Value(completion),
      revision: Value(revision),
    );
  }

  factory PlaybackProgressEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackProgressEntry(
      contentId: serializer.fromJson<String>(json['contentId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      completion: serializer.fromJson<String>(json['completion']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentId': serializer.toJson<String>(contentId),
      'episodeId': serializer.toJson<String>(episodeId),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int?>(durationMs),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'completion': serializer.toJson<String>(completion),
      'revision': serializer.toJson<int>(revision),
    };
  }

  PlaybackProgressEntry copyWith({
    String? contentId,
    String? episodeId,
    int? positionMs,
    Value<int?> durationMs = const Value.absent(),
    DateTime? updatedAtUtc,
    String? completion,
    int? revision,
  }) => PlaybackProgressEntry(
    contentId: contentId ?? this.contentId,
    episodeId: episodeId ?? this.episodeId,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    completion: completion ?? this.completion,
    revision: revision ?? this.revision,
  );
  PlaybackProgressEntry copyWithCompanion(
    PlaybackProgressEntriesCompanion data,
  ) {
    return PlaybackProgressEntry(
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      completion: data.completion.present
          ? data.completion.value
          : this.completion,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackProgressEntry(')
          ..write('contentId: $contentId, ')
          ..write('episodeId: $episodeId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('completion: $completion, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentId,
    episodeId,
    positionMs,
    durationMs,
    updatedAtUtc,
    completion,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackProgressEntry &&
          other.contentId == this.contentId &&
          other.episodeId == this.episodeId &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.completion == this.completion &&
          other.revision == this.revision);
}

class PlaybackProgressEntriesCompanion
    extends UpdateCompanion<PlaybackProgressEntry> {
  final Value<String> contentId;
  final Value<String> episodeId;
  final Value<int> positionMs;
  final Value<int?> durationMs;
  final Value<DateTime> updatedAtUtc;
  final Value<String> completion;
  final Value<int> revision;
  final Value<int> rowid;
  const PlaybackProgressEntriesCompanion({
    this.contentId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.completion = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackProgressEntriesCompanion.insert({
    required String contentId,
    required String episodeId,
    required int positionMs,
    this.durationMs = const Value.absent(),
    required DateTime updatedAtUtc,
    required String completion,
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : contentId = Value(contentId),
       episodeId = Value(episodeId),
       positionMs = Value(positionMs),
       updatedAtUtc = Value(updatedAtUtc),
       completion = Value(completion);
  static Insertable<PlaybackProgressEntry> custom({
    Expression<String>? contentId,
    Expression<String>? episodeId,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<DateTime>? updatedAtUtc,
    Expression<String>? completion,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentId != null) 'content_id': contentId,
      if (episodeId != null) 'episode_id': episodeId,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (completion != null) 'completion': completion,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackProgressEntriesCompanion copyWith({
    Value<String>? contentId,
    Value<String>? episodeId,
    Value<int>? positionMs,
    Value<int?>? durationMs,
    Value<DateTime>? updatedAtUtc,
    Value<String>? completion,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return PlaybackProgressEntriesCompanion(
      contentId: contentId ?? this.contentId,
      episodeId: episodeId ?? this.episodeId,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      completion: completion ?? this.completion,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (completion.present) {
      map['completion'] = Variable<String>(completion.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackProgressEntriesCompanion(')
          ..write('contentId: $contentId, ')
          ..write('episodeId: $episodeId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('completion: $completion, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnimeIdentityEntriesTable extends AnimeIdentityEntries
    with TableInfo<$AnimeIdentityEntriesTable, AnimeIdentityEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimeIdentityEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _animeIdMeta = const VerificationMeta(
    'animeId',
  );
  @override
  late final GeneratedColumn<String> animeId = GeneratedColumn<String>(
    'anime_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [animeId, createdAtUtc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anime_identity_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnimeIdentityEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anime_id')) {
      context.handle(
        _animeIdMeta,
        animeId.isAcceptableOrUnknown(data['anime_id']!, _animeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_animeIdMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {animeId};
  @override
  AnimeIdentityEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimeIdentityEntry(
      animeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_id'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $AnimeIdentityEntriesTable createAlias(String alias) {
    return $AnimeIdentityEntriesTable(attachedDatabase, alias);
  }
}

class AnimeIdentityEntry extends DataClass
    implements Insertable<AnimeIdentityEntry> {
  final String animeId;
  final DateTime createdAtUtc;
  const AnimeIdentityEntry({required this.animeId, required this.createdAtUtc});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anime_id'] = Variable<String>(animeId);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  AnimeIdentityEntriesCompanion toCompanion(bool nullToAbsent) {
    return AnimeIdentityEntriesCompanion(
      animeId: Value(animeId),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory AnimeIdentityEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimeIdentityEntry(
      animeId: serializer.fromJson<String>(json['animeId']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'animeId': serializer.toJson<String>(animeId),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  AnimeIdentityEntry copyWith({String? animeId, DateTime? createdAtUtc}) =>
      AnimeIdentityEntry(
        animeId: animeId ?? this.animeId,
        createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      );
  AnimeIdentityEntry copyWithCompanion(AnimeIdentityEntriesCompanion data) {
    return AnimeIdentityEntry(
      animeId: data.animeId.present ? data.animeId.value : this.animeId,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimeIdentityEntry(')
          ..write('animeId: $animeId, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(animeId, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimeIdentityEntry &&
          other.animeId == this.animeId &&
          other.createdAtUtc == this.createdAtUtc);
}

class AnimeIdentityEntriesCompanion
    extends UpdateCompanion<AnimeIdentityEntry> {
  final Value<String> animeId;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const AnimeIdentityEntriesCompanion({
    this.animeId = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnimeIdentityEntriesCompanion.insert({
    required String animeId,
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  }) : animeId = Value(animeId),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<AnimeIdentityEntry> custom({
    Expression<String>? animeId,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (animeId != null) 'anime_id': animeId,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnimeIdentityEntriesCompanion copyWith({
    Value<String>? animeId,
    Value<DateTime>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return AnimeIdentityEntriesCompanion(
      animeId: animeId ?? this.animeId,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (animeId.present) {
      map['anime_id'] = Variable<String>(animeId.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimeIdentityEntriesCompanion(')
          ..write('animeId: $animeId, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExternalAnimeIdentifiersTable extends ExternalAnimeIdentifiers
    with TableInfo<$ExternalAnimeIdentifiersTable, ExternalAnimeIdentifier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExternalAnimeIdentifiersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _animeIdMeta = const VerificationMeta(
    'animeId',
  );
  @override
  late final GeneratedColumn<String> animeId = GeneratedColumn<String>(
    'anime_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _evidenceMeta = const VerificationMeta(
    'evidence',
  );
  @override
  late final GeneratedColumn<String> evidence = GeneratedColumn<String>(
    'evidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkedAtUtcMeta = const VerificationMeta(
    'linkedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> linkedAtUtc = GeneratedColumn<DateTime>(
    'linked_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    externalId,
    animeId,
    evidence,
    linkedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'external_anime_identifiers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExternalAnimeIdentifier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('anime_id')) {
      context.handle(
        _animeIdMeta,
        animeId.isAcceptableOrUnknown(data['anime_id']!, _animeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_animeIdMeta);
    }
    if (data.containsKey('evidence')) {
      context.handle(
        _evidenceMeta,
        evidence.isAcceptableOrUnknown(data['evidence']!, _evidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_evidenceMeta);
    }
    if (data.containsKey('linked_at_utc')) {
      context.handle(
        _linkedAtUtcMeta,
        linkedAtUtc.isAcceptableOrUnknown(
          data['linked_at_utc']!,
          _linkedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_linkedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, externalId};
  @override
  ExternalAnimeIdentifier map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExternalAnimeIdentifier(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      animeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_id'],
      )!,
      evidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence'],
      )!,
      linkedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}linked_at_utc'],
      )!,
    );
  }

  @override
  $ExternalAnimeIdentifiersTable createAlias(String alias) {
    return $ExternalAnimeIdentifiersTable(attachedDatabase, alias);
  }
}

class ExternalAnimeIdentifier extends DataClass
    implements Insertable<ExternalAnimeIdentifier> {
  final String providerId;
  final String externalId;
  final String animeId;
  final String evidence;
  final DateTime linkedAtUtc;
  const ExternalAnimeIdentifier({
    required this.providerId,
    required this.externalId,
    required this.animeId,
    required this.evidence,
    required this.linkedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['external_id'] = Variable<String>(externalId);
    map['anime_id'] = Variable<String>(animeId);
    map['evidence'] = Variable<String>(evidence);
    map['linked_at_utc'] = Variable<DateTime>(linkedAtUtc);
    return map;
  }

  ExternalAnimeIdentifiersCompanion toCompanion(bool nullToAbsent) {
    return ExternalAnimeIdentifiersCompanion(
      providerId: Value(providerId),
      externalId: Value(externalId),
      animeId: Value(animeId),
      evidence: Value(evidence),
      linkedAtUtc: Value(linkedAtUtc),
    );
  }

  factory ExternalAnimeIdentifier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExternalAnimeIdentifier(
      providerId: serializer.fromJson<String>(json['providerId']),
      externalId: serializer.fromJson<String>(json['externalId']),
      animeId: serializer.fromJson<String>(json['animeId']),
      evidence: serializer.fromJson<String>(json['evidence']),
      linkedAtUtc: serializer.fromJson<DateTime>(json['linkedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'externalId': serializer.toJson<String>(externalId),
      'animeId': serializer.toJson<String>(animeId),
      'evidence': serializer.toJson<String>(evidence),
      'linkedAtUtc': serializer.toJson<DateTime>(linkedAtUtc),
    };
  }

  ExternalAnimeIdentifier copyWith({
    String? providerId,
    String? externalId,
    String? animeId,
    String? evidence,
    DateTime? linkedAtUtc,
  }) => ExternalAnimeIdentifier(
    providerId: providerId ?? this.providerId,
    externalId: externalId ?? this.externalId,
    animeId: animeId ?? this.animeId,
    evidence: evidence ?? this.evidence,
    linkedAtUtc: linkedAtUtc ?? this.linkedAtUtc,
  );
  ExternalAnimeIdentifier copyWithCompanion(
    ExternalAnimeIdentifiersCompanion data,
  ) {
    return ExternalAnimeIdentifier(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      animeId: data.animeId.present ? data.animeId.value : this.animeId,
      evidence: data.evidence.present ? data.evidence.value : this.evidence,
      linkedAtUtc: data.linkedAtUtc.present
          ? data.linkedAtUtc.value
          : this.linkedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExternalAnimeIdentifier(')
          ..write('providerId: $providerId, ')
          ..write('externalId: $externalId, ')
          ..write('animeId: $animeId, ')
          ..write('evidence: $evidence, ')
          ..write('linkedAtUtc: $linkedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(providerId, externalId, animeId, evidence, linkedAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExternalAnimeIdentifier &&
          other.providerId == this.providerId &&
          other.externalId == this.externalId &&
          other.animeId == this.animeId &&
          other.evidence == this.evidence &&
          other.linkedAtUtc == this.linkedAtUtc);
}

class ExternalAnimeIdentifiersCompanion
    extends UpdateCompanion<ExternalAnimeIdentifier> {
  final Value<String> providerId;
  final Value<String> externalId;
  final Value<String> animeId;
  final Value<String> evidence;
  final Value<DateTime> linkedAtUtc;
  final Value<int> rowid;
  const ExternalAnimeIdentifiersCompanion({
    this.providerId = const Value.absent(),
    this.externalId = const Value.absent(),
    this.animeId = const Value.absent(),
    this.evidence = const Value.absent(),
    this.linkedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExternalAnimeIdentifiersCompanion.insert({
    required String providerId,
    required String externalId,
    required String animeId,
    required String evidence,
    required DateTime linkedAtUtc,
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       externalId = Value(externalId),
       animeId = Value(animeId),
       evidence = Value(evidence),
       linkedAtUtc = Value(linkedAtUtc);
  static Insertable<ExternalAnimeIdentifier> custom({
    Expression<String>? providerId,
    Expression<String>? externalId,
    Expression<String>? animeId,
    Expression<String>? evidence,
    Expression<DateTime>? linkedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (externalId != null) 'external_id': externalId,
      if (animeId != null) 'anime_id': animeId,
      if (evidence != null) 'evidence': evidence,
      if (linkedAtUtc != null) 'linked_at_utc': linkedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExternalAnimeIdentifiersCompanion copyWith({
    Value<String>? providerId,
    Value<String>? externalId,
    Value<String>? animeId,
    Value<String>? evidence,
    Value<DateTime>? linkedAtUtc,
    Value<int>? rowid,
  }) {
    return ExternalAnimeIdentifiersCompanion(
      providerId: providerId ?? this.providerId,
      externalId: externalId ?? this.externalId,
      animeId: animeId ?? this.animeId,
      evidence: evidence ?? this.evidence,
      linkedAtUtc: linkedAtUtc ?? this.linkedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (animeId.present) {
      map['anime_id'] = Variable<String>(animeId.value);
    }
    if (evidence.present) {
      map['evidence'] = Variable<String>(evidence.value);
    }
    if (linkedAtUtc.present) {
      map['linked_at_utc'] = Variable<DateTime>(linkedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExternalAnimeIdentifiersCompanion(')
          ..write('providerId: $providerId, ')
          ..write('externalId: $externalId, ')
          ..write('animeId: $animeId, ')
          ..write('evidence: $evidence, ')
          ..write('linkedAtUtc: $linkedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnimeIdentityRelationshipsTable extends AnimeIdentityRelationships
    with
        TableInfo<$AnimeIdentityRelationshipsTable, AnimeIdentityRelationship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimeIdentityRelationshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceAnimeIdMeta = const VerificationMeta(
    'sourceAnimeId',
  );
  @override
  late final GeneratedColumn<String> sourceAnimeId = GeneratedColumn<String>(
    'source_anime_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetAnimeIdMeta = const VerificationMeta(
    'targetAnimeId',
  );
  @override
  late final GeneratedColumn<String> targetAnimeId = GeneratedColumn<String>(
    'target_anime_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _relationshipKindMeta = const VerificationMeta(
    'relationshipKind',
  );
  @override
  late final GeneratedColumn<String> relationshipKind = GeneratedColumn<String>(
    'relationship_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceMeta = const VerificationMeta(
    'evidence',
  );
  @override
  late final GeneratedColumn<String> evidence = GeneratedColumn<String>(
    'evidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkedAtUtcMeta = const VerificationMeta(
    'linkedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> linkedAtUtc = GeneratedColumn<DateTime>(
    'linked_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceAnimeId,
    targetAnimeId,
    relationshipKind,
    evidence,
    linkedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anime_identity_relationships';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnimeIdentityRelationship> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_anime_id')) {
      context.handle(
        _sourceAnimeIdMeta,
        sourceAnimeId.isAcceptableOrUnknown(
          data['source_anime_id']!,
          _sourceAnimeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceAnimeIdMeta);
    }
    if (data.containsKey('target_anime_id')) {
      context.handle(
        _targetAnimeIdMeta,
        targetAnimeId.isAcceptableOrUnknown(
          data['target_anime_id']!,
          _targetAnimeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAnimeIdMeta);
    }
    if (data.containsKey('relationship_kind')) {
      context.handle(
        _relationshipKindMeta,
        relationshipKind.isAcceptableOrUnknown(
          data['relationship_kind']!,
          _relationshipKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationshipKindMeta);
    }
    if (data.containsKey('evidence')) {
      context.handle(
        _evidenceMeta,
        evidence.isAcceptableOrUnknown(data['evidence']!, _evidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_evidenceMeta);
    }
    if (data.containsKey('linked_at_utc')) {
      context.handle(
        _linkedAtUtcMeta,
        linkedAtUtc.isAcceptableOrUnknown(
          data['linked_at_utc']!,
          _linkedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_linkedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    sourceAnimeId,
    targetAnimeId,
    relationshipKind,
  };
  @override
  AnimeIdentityRelationship map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimeIdentityRelationship(
      sourceAnimeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_anime_id'],
      )!,
      targetAnimeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_anime_id'],
      )!,
      relationshipKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship_kind'],
      )!,
      evidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence'],
      )!,
      linkedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}linked_at_utc'],
      )!,
    );
  }

  @override
  $AnimeIdentityRelationshipsTable createAlias(String alias) {
    return $AnimeIdentityRelationshipsTable(attachedDatabase, alias);
  }
}

class AnimeIdentityRelationship extends DataClass
    implements Insertable<AnimeIdentityRelationship> {
  final String sourceAnimeId;
  final String targetAnimeId;
  final String relationshipKind;
  final String evidence;
  final DateTime linkedAtUtc;
  const AnimeIdentityRelationship({
    required this.sourceAnimeId,
    required this.targetAnimeId,
    required this.relationshipKind,
    required this.evidence,
    required this.linkedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_anime_id'] = Variable<String>(sourceAnimeId);
    map['target_anime_id'] = Variable<String>(targetAnimeId);
    map['relationship_kind'] = Variable<String>(relationshipKind);
    map['evidence'] = Variable<String>(evidence);
    map['linked_at_utc'] = Variable<DateTime>(linkedAtUtc);
    return map;
  }

  AnimeIdentityRelationshipsCompanion toCompanion(bool nullToAbsent) {
    return AnimeIdentityRelationshipsCompanion(
      sourceAnimeId: Value(sourceAnimeId),
      targetAnimeId: Value(targetAnimeId),
      relationshipKind: Value(relationshipKind),
      evidence: Value(evidence),
      linkedAtUtc: Value(linkedAtUtc),
    );
  }

  factory AnimeIdentityRelationship.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimeIdentityRelationship(
      sourceAnimeId: serializer.fromJson<String>(json['sourceAnimeId']),
      targetAnimeId: serializer.fromJson<String>(json['targetAnimeId']),
      relationshipKind: serializer.fromJson<String>(json['relationshipKind']),
      evidence: serializer.fromJson<String>(json['evidence']),
      linkedAtUtc: serializer.fromJson<DateTime>(json['linkedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceAnimeId': serializer.toJson<String>(sourceAnimeId),
      'targetAnimeId': serializer.toJson<String>(targetAnimeId),
      'relationshipKind': serializer.toJson<String>(relationshipKind),
      'evidence': serializer.toJson<String>(evidence),
      'linkedAtUtc': serializer.toJson<DateTime>(linkedAtUtc),
    };
  }

  AnimeIdentityRelationship copyWith({
    String? sourceAnimeId,
    String? targetAnimeId,
    String? relationshipKind,
    String? evidence,
    DateTime? linkedAtUtc,
  }) => AnimeIdentityRelationship(
    sourceAnimeId: sourceAnimeId ?? this.sourceAnimeId,
    targetAnimeId: targetAnimeId ?? this.targetAnimeId,
    relationshipKind: relationshipKind ?? this.relationshipKind,
    evidence: evidence ?? this.evidence,
    linkedAtUtc: linkedAtUtc ?? this.linkedAtUtc,
  );
  AnimeIdentityRelationship copyWithCompanion(
    AnimeIdentityRelationshipsCompanion data,
  ) {
    return AnimeIdentityRelationship(
      sourceAnimeId: data.sourceAnimeId.present
          ? data.sourceAnimeId.value
          : this.sourceAnimeId,
      targetAnimeId: data.targetAnimeId.present
          ? data.targetAnimeId.value
          : this.targetAnimeId,
      relationshipKind: data.relationshipKind.present
          ? data.relationshipKind.value
          : this.relationshipKind,
      evidence: data.evidence.present ? data.evidence.value : this.evidence,
      linkedAtUtc: data.linkedAtUtc.present
          ? data.linkedAtUtc.value
          : this.linkedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimeIdentityRelationship(')
          ..write('sourceAnimeId: $sourceAnimeId, ')
          ..write('targetAnimeId: $targetAnimeId, ')
          ..write('relationshipKind: $relationshipKind, ')
          ..write('evidence: $evidence, ')
          ..write('linkedAtUtc: $linkedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceAnimeId,
    targetAnimeId,
    relationshipKind,
    evidence,
    linkedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimeIdentityRelationship &&
          other.sourceAnimeId == this.sourceAnimeId &&
          other.targetAnimeId == this.targetAnimeId &&
          other.relationshipKind == this.relationshipKind &&
          other.evidence == this.evidence &&
          other.linkedAtUtc == this.linkedAtUtc);
}

class AnimeIdentityRelationshipsCompanion
    extends UpdateCompanion<AnimeIdentityRelationship> {
  final Value<String> sourceAnimeId;
  final Value<String> targetAnimeId;
  final Value<String> relationshipKind;
  final Value<String> evidence;
  final Value<DateTime> linkedAtUtc;
  final Value<int> rowid;
  const AnimeIdentityRelationshipsCompanion({
    this.sourceAnimeId = const Value.absent(),
    this.targetAnimeId = const Value.absent(),
    this.relationshipKind = const Value.absent(),
    this.evidence = const Value.absent(),
    this.linkedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnimeIdentityRelationshipsCompanion.insert({
    required String sourceAnimeId,
    required String targetAnimeId,
    required String relationshipKind,
    required String evidence,
    required DateTime linkedAtUtc,
    this.rowid = const Value.absent(),
  }) : sourceAnimeId = Value(sourceAnimeId),
       targetAnimeId = Value(targetAnimeId),
       relationshipKind = Value(relationshipKind),
       evidence = Value(evidence),
       linkedAtUtc = Value(linkedAtUtc);
  static Insertable<AnimeIdentityRelationship> custom({
    Expression<String>? sourceAnimeId,
    Expression<String>? targetAnimeId,
    Expression<String>? relationshipKind,
    Expression<String>? evidence,
    Expression<DateTime>? linkedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceAnimeId != null) 'source_anime_id': sourceAnimeId,
      if (targetAnimeId != null) 'target_anime_id': targetAnimeId,
      if (relationshipKind != null) 'relationship_kind': relationshipKind,
      if (evidence != null) 'evidence': evidence,
      if (linkedAtUtc != null) 'linked_at_utc': linkedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnimeIdentityRelationshipsCompanion copyWith({
    Value<String>? sourceAnimeId,
    Value<String>? targetAnimeId,
    Value<String>? relationshipKind,
    Value<String>? evidence,
    Value<DateTime>? linkedAtUtc,
    Value<int>? rowid,
  }) {
    return AnimeIdentityRelationshipsCompanion(
      sourceAnimeId: sourceAnimeId ?? this.sourceAnimeId,
      targetAnimeId: targetAnimeId ?? this.targetAnimeId,
      relationshipKind: relationshipKind ?? this.relationshipKind,
      evidence: evidence ?? this.evidence,
      linkedAtUtc: linkedAtUtc ?? this.linkedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceAnimeId.present) {
      map['source_anime_id'] = Variable<String>(sourceAnimeId.value);
    }
    if (targetAnimeId.present) {
      map['target_anime_id'] = Variable<String>(targetAnimeId.value);
    }
    if (relationshipKind.present) {
      map['relationship_kind'] = Variable<String>(relationshipKind.value);
    }
    if (evidence.present) {
      map['evidence'] = Variable<String>(evidence.value);
    }
    if (linkedAtUtc.present) {
      map['linked_at_utc'] = Variable<DateTime>(linkedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimeIdentityRelationshipsCompanion(')
          ..write('sourceAnimeId: $sourceAnimeId, ')
          ..write('targetAnimeId: $targetAnimeId, ')
          ..write('relationshipKind: $relationshipKind, ')
          ..write('evidence: $evidence, ')
          ..write('linkedAtUtc: $linkedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalLibraryEntriesTable extends LocalLibraryEntries
    with TableInfo<$LocalLibraryEntriesTable, LocalLibraryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLibraryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _animeIdMeta = const VerificationMeta(
    'animeId',
  );
  @override
  late final GeneratedColumn<String> animeId = GeneratedColumn<String>(
    'anime_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addedAtUtcMeta = const VerificationMeta(
    'addedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> addedAtUtc = GeneratedColumn<DateTime>(
    'added_at_utc',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('planned'),
  );
  @override
  List<GeneratedColumn> get $columns => [animeId, addedAtUtc, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalLibraryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anime_id')) {
      context.handle(
        _animeIdMeta,
        animeId.isAcceptableOrUnknown(data['anime_id']!, _animeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_animeIdMeta);
    }
    if (data.containsKey('added_at_utc')) {
      context.handle(
        _addedAtUtcMeta,
        addedAtUtc.isAcceptableOrUnknown(
          data['added_at_utc']!,
          _addedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addedAtUtcMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {animeId};
  @override
  LocalLibraryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLibraryEntry(
      animeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_id'],
      )!,
      addedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at_utc'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $LocalLibraryEntriesTable createAlias(String alias) {
    return $LocalLibraryEntriesTable(attachedDatabase, alias);
  }
}

class LocalLibraryEntry extends DataClass
    implements Insertable<LocalLibraryEntry> {
  final String animeId;
  final DateTime addedAtUtc;
  final String status;
  const LocalLibraryEntry({
    required this.animeId,
    required this.addedAtUtc,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anime_id'] = Variable<String>(animeId);
    map['added_at_utc'] = Variable<DateTime>(addedAtUtc);
    map['status'] = Variable<String>(status);
    return map;
  }

  LocalLibraryEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalLibraryEntriesCompanion(
      animeId: Value(animeId),
      addedAtUtc: Value(addedAtUtc),
      status: Value(status),
    );
  }

  factory LocalLibraryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLibraryEntry(
      animeId: serializer.fromJson<String>(json['animeId']),
      addedAtUtc: serializer.fromJson<DateTime>(json['addedAtUtc']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'animeId': serializer.toJson<String>(animeId),
      'addedAtUtc': serializer.toJson<DateTime>(addedAtUtc),
      'status': serializer.toJson<String>(status),
    };
  }

  LocalLibraryEntry copyWith({
    String? animeId,
    DateTime? addedAtUtc,
    String? status,
  }) => LocalLibraryEntry(
    animeId: animeId ?? this.animeId,
    addedAtUtc: addedAtUtc ?? this.addedAtUtc,
    status: status ?? this.status,
  );
  LocalLibraryEntry copyWithCompanion(LocalLibraryEntriesCompanion data) {
    return LocalLibraryEntry(
      animeId: data.animeId.present ? data.animeId.value : this.animeId,
      addedAtUtc: data.addedAtUtc.present
          ? data.addedAtUtc.value
          : this.addedAtUtc,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLibraryEntry(')
          ..write('animeId: $animeId, ')
          ..write('addedAtUtc: $addedAtUtc, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(animeId, addedAtUtc, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLibraryEntry &&
          other.animeId == this.animeId &&
          other.addedAtUtc == this.addedAtUtc &&
          other.status == this.status);
}

class LocalLibraryEntriesCompanion extends UpdateCompanion<LocalLibraryEntry> {
  final Value<String> animeId;
  final Value<DateTime> addedAtUtc;
  final Value<String> status;
  final Value<int> rowid;
  const LocalLibraryEntriesCompanion({
    this.animeId = const Value.absent(),
    this.addedAtUtc = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalLibraryEntriesCompanion.insert({
    required String animeId,
    required DateTime addedAtUtc,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : animeId = Value(animeId),
       addedAtUtc = Value(addedAtUtc);
  static Insertable<LocalLibraryEntry> custom({
    Expression<String>? animeId,
    Expression<DateTime>? addedAtUtc,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (animeId != null) 'anime_id': animeId,
      if (addedAtUtc != null) 'added_at_utc': addedAtUtc,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalLibraryEntriesCompanion copyWith({
    Value<String>? animeId,
    Value<DateTime>? addedAtUtc,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return LocalLibraryEntriesCompanion(
      animeId: animeId ?? this.animeId,
      addedAtUtc: addedAtUtc ?? this.addedAtUtc,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (animeId.present) {
      map['anime_id'] = Variable<String>(animeId.value);
    }
    if (addedAtUtc.present) {
      map['added_at_utc'] = Variable<DateTime>(addedAtUtc.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLibraryEntriesCompanion(')
          ..write('animeId: $animeId, ')
          ..write('addedAtUtc: $addedAtUtc, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsEntriesTable settingsEntries = $SettingsEntriesTable(
    this,
  );
  late final $ProgressDocumentsTable progressDocuments =
      $ProgressDocumentsTable(this);
  late final $LatestAnimeSearchTable latestAnimeSearch =
      $LatestAnimeSearchTable(this);
  late final $PlaybackProgressEntriesTable playbackProgressEntries =
      $PlaybackProgressEntriesTable(this);
  late final $AnimeIdentityEntriesTable animeIdentityEntries =
      $AnimeIdentityEntriesTable(this);
  late final $ExternalAnimeIdentifiersTable externalAnimeIdentifiers =
      $ExternalAnimeIdentifiersTable(this);
  late final $AnimeIdentityRelationshipsTable animeIdentityRelationships =
      $AnimeIdentityRelationshipsTable(this);
  late final $LocalLibraryEntriesTable localLibraryEntries =
      $LocalLibraryEntriesTable(this);
  late final Index externalAnimeIdentifiersByAnime = Index(
    'external_anime_identifiers_by_anime',
    'CREATE INDEX external_anime_identifiers_by_anime ON external_anime_identifiers (anime_id)',
  );
  late final Index libraryEntriesByAddedAt = Index(
    'library_entries_by_added_at',
    'CREATE INDEX library_entries_by_added_at ON library_entries (added_at_utc)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settingsEntries,
    progressDocuments,
    latestAnimeSearch,
    playbackProgressEntries,
    animeIdentityEntries,
    externalAnimeIdentifiers,
    animeIdentityRelationships,
    localLibraryEntries,
    externalAnimeIdentifiersByAnime,
    libraryEntriesByAddedAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime_identity_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('external_anime_identifiers', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime_identity_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('anime_identity_relationships', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime_identity_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('anime_identity_relationships', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime_identity_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('library_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SettingsEntriesTableCreateCompanionBuilder =
    SettingsEntriesCompanion Function({
      required String settingKey,
      required String valueJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsEntriesTableUpdateCompanionBuilder =
    SettingsEntriesCompanion Function({
      Value<String> settingKey,
      Value<String> valueJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsEntriesTable,
          SettingsEntry,
          $$SettingsEntriesTableFilterComposer,
          $$SettingsEntriesTableOrderingComposer,
          $$SettingsEntriesTableAnnotationComposer,
          $$SettingsEntriesTableCreateCompanionBuilder,
          $$SettingsEntriesTableUpdateCompanionBuilder,
          (
            SettingsEntry,
            BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
          ),
          SettingsEntry,
          PrefetchHooks Function()
        > {
  $$SettingsEntriesTableTableManager(
    _$AppDatabase db,
    $SettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion(
                settingKey: settingKey,
                valueJson: valueJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                required String valueJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion.insert(
                settingKey: settingKey,
                valueJson: valueJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsEntriesTable, SettingsEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsEntriesTable,
                    SettingsEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsEntriesTable,
      SettingsEntry,
      $$SettingsEntriesTableFilterComposer,
      $$SettingsEntriesTableOrderingComposer,
      $$SettingsEntriesTableAnnotationComposer,
      $$SettingsEntriesTableCreateCompanionBuilder,
      $$SettingsEntriesTableUpdateCompanionBuilder,
      (
        SettingsEntry,
        BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
      ),
      SettingsEntry,
      PrefetchHooks Function()
    >;
typedef $$ProgressDocumentsTableCreateCompanionBuilder =
    ProgressDocumentsCompanion Function({
      required String documentKey,
      required String payloadJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProgressDocumentsTableUpdateCompanionBuilder =
    ProgressDocumentsCompanion Function({
      Value<String> documentKey,
      Value<String> payloadJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProgressDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressDocumentsTable> {
  $$ProgressDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentKey => $composableBuilder(
    column: $table.documentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressDocumentsTable> {
  $$ProgressDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentKey => $composableBuilder(
    column: $table.documentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressDocumentsTable> {
  $$ProgressDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentKey => $composableBuilder(
    column: $table.documentKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProgressDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressDocumentsTable,
          ProgressDocument,
          $$ProgressDocumentsTableFilterComposer,
          $$ProgressDocumentsTableOrderingComposer,
          $$ProgressDocumentsTableAnnotationComposer,
          $$ProgressDocumentsTableCreateCompanionBuilder,
          $$ProgressDocumentsTableUpdateCompanionBuilder,
          (
            ProgressDocument,
            BaseReferences<
              _$AppDatabase,
              $ProgressDocumentsTable,
              ProgressDocument
            >,
          ),
          ProgressDocument,
          PrefetchHooks Function()
        > {
  $$ProgressDocumentsTableTableManager(
    _$AppDatabase db,
    $ProgressDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressDocumentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> documentKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressDocumentsCompanion(
                documentKey: documentKey,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentKey,
                required String payloadJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProgressDocumentsCompanion.insert(
                documentKey: documentKey,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgressDocumentsTable, ProgressDocument>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProgressDocumentsTable,
                    ProgressDocument
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressDocumentsTable,
      ProgressDocument,
      $$ProgressDocumentsTableFilterComposer,
      $$ProgressDocumentsTableOrderingComposer,
      $$ProgressDocumentsTableAnnotationComposer,
      $$ProgressDocumentsTableCreateCompanionBuilder,
      $$ProgressDocumentsTableUpdateCompanionBuilder,
      (
        ProgressDocument,
        BaseReferences<
          _$AppDatabase,
          $ProgressDocumentsTable,
          ProgressDocument
        >,
      ),
      ProgressDocument,
      PrefetchHooks Function()
    >;
typedef $$LatestAnimeSearchTableCreateCompanionBuilder =
    LatestAnimeSearchCompanion Function({
      required String slot,
      required String searchQuery,
      required int page,
      required int perPage,
      required String resultJson,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$LatestAnimeSearchTableUpdateCompanionBuilder =
    LatestAnimeSearchCompanion Function({
      Value<String> slot,
      Value<String> searchQuery,
      Value<int> page,
      Value<int> perPage,
      Value<String> resultJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$LatestAnimeSearchTableFilterComposer
    extends Composer<_$AppDatabase, $LatestAnimeSearchTable> {
  $$LatestAnimeSearchTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchQuery => $composableBuilder(
    column: $table.searchQuery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get perPage => $composableBuilder(
    column: $table.perPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LatestAnimeSearchTableOrderingComposer
    extends Composer<_$AppDatabase, $LatestAnimeSearchTable> {
  $$LatestAnimeSearchTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchQuery => $composableBuilder(
    column: $table.searchQuery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get perPage => $composableBuilder(
    column: $table.perPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LatestAnimeSearchTableAnnotationComposer
    extends Composer<_$AppDatabase, $LatestAnimeSearchTable> {
  $$LatestAnimeSearchTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get searchQuery => $composableBuilder(
    column: $table.searchQuery,
    builder: (column) => column,
  );

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get perPage =>
      $composableBuilder(column: $table.perPage, builder: (column) => column);

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LatestAnimeSearchTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LatestAnimeSearchTable,
          LatestAnimeSearchData,
          $$LatestAnimeSearchTableFilterComposer,
          $$LatestAnimeSearchTableOrderingComposer,
          $$LatestAnimeSearchTableAnnotationComposer,
          $$LatestAnimeSearchTableCreateCompanionBuilder,
          $$LatestAnimeSearchTableUpdateCompanionBuilder,
          (
            LatestAnimeSearchData,
            BaseReferences<
              _$AppDatabase,
              $LatestAnimeSearchTable,
              LatestAnimeSearchData
            >,
          ),
          LatestAnimeSearchData,
          PrefetchHooks Function()
        > {
  $$LatestAnimeSearchTableTableManager(
    _$AppDatabase db,
    $LatestAnimeSearchTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LatestAnimeSearchTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LatestAnimeSearchTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LatestAnimeSearchTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> slot = const Value.absent(),
                Value<String> searchQuery = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> perPage = const Value.absent(),
                Value<String> resultJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LatestAnimeSearchCompanion(
                slot: slot,
                searchQuery: searchQuery,
                page: page,
                perPage: perPage,
                resultJson: resultJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slot,
                required String searchQuery,
                required int page,
                required int perPage,
                required String resultJson,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => LatestAnimeSearchCompanion.insert(
                slot: slot,
                searchQuery: searchQuery,
                page: page,
                perPage: perPage,
                resultJson: resultJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LatestAnimeSearchTable, LatestAnimeSearchData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LatestAnimeSearchTable,
                    LatestAnimeSearchData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LatestAnimeSearchTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LatestAnimeSearchTable,
      LatestAnimeSearchData,
      $$LatestAnimeSearchTableFilterComposer,
      $$LatestAnimeSearchTableOrderingComposer,
      $$LatestAnimeSearchTableAnnotationComposer,
      $$LatestAnimeSearchTableCreateCompanionBuilder,
      $$LatestAnimeSearchTableUpdateCompanionBuilder,
      (
        LatestAnimeSearchData,
        BaseReferences<
          _$AppDatabase,
          $LatestAnimeSearchTable,
          LatestAnimeSearchData
        >,
      ),
      LatestAnimeSearchData,
      PrefetchHooks Function()
    >;
typedef $$PlaybackProgressEntriesTableCreateCompanionBuilder =
    PlaybackProgressEntriesCompanion Function({
      required String contentId,
      required String episodeId,
      required int positionMs,
      Value<int?> durationMs,
      required DateTime updatedAtUtc,
      required String completion,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$PlaybackProgressEntriesTableUpdateCompanionBuilder =
    PlaybackProgressEntriesCompanion Function({
      Value<String> contentId,
      Value<String> episodeId,
      Value<int> positionMs,
      Value<int?> durationMs,
      Value<DateTime> updatedAtUtc,
      Value<String> completion,
      Value<int> revision,
      Value<int> rowid,
    });

class $$PlaybackProgressEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackProgressEntriesTable> {
  $$PlaybackProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completion => $composableBuilder(
    column: $table.completion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaybackProgressEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackProgressEntriesTable> {
  $$PlaybackProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completion => $composableBuilder(
    column: $table.completion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaybackProgressEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackProgressEntriesTable> {
  $$PlaybackProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completion => $composableBuilder(
    column: $table.completion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $$PlaybackProgressEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackProgressEntriesTable,
          PlaybackProgressEntry,
          $$PlaybackProgressEntriesTableFilterComposer,
          $$PlaybackProgressEntriesTableOrderingComposer,
          $$PlaybackProgressEntriesTableAnnotationComposer,
          $$PlaybackProgressEntriesTableCreateCompanionBuilder,
          $$PlaybackProgressEntriesTableUpdateCompanionBuilder,
          (
            PlaybackProgressEntry,
            BaseReferences<
              _$AppDatabase,
              $PlaybackProgressEntriesTable,
              PlaybackProgressEntry
            >,
          ),
          PlaybackProgressEntry,
          PrefetchHooks Function()
        > {
  $$PlaybackProgressEntriesTableTableManager(
    _$AppDatabase db,
    $PlaybackProgressEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackProgressEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PlaybackProgressEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaybackProgressEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> contentId = const Value.absent(),
                Value<String> episodeId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<String> completion = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackProgressEntriesCompanion(
                contentId: contentId,
                episodeId: episodeId,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAtUtc: updatedAtUtc,
                completion: completion,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentId,
                required String episodeId,
                required int positionMs,
                Value<int?> durationMs = const Value.absent(),
                required DateTime updatedAtUtc,
                required String completion,
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackProgressEntriesCompanion.insert(
                contentId: contentId,
                episodeId: episodeId,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAtUtc: updatedAtUtc,
                completion: completion,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PlaybackProgressEntriesTable,
                    PlaybackProgressEntry
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlaybackProgressEntriesTable,
                    PlaybackProgressEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaybackProgressEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackProgressEntriesTable,
      PlaybackProgressEntry,
      $$PlaybackProgressEntriesTableFilterComposer,
      $$PlaybackProgressEntriesTableOrderingComposer,
      $$PlaybackProgressEntriesTableAnnotationComposer,
      $$PlaybackProgressEntriesTableCreateCompanionBuilder,
      $$PlaybackProgressEntriesTableUpdateCompanionBuilder,
      (
        PlaybackProgressEntry,
        BaseReferences<
          _$AppDatabase,
          $PlaybackProgressEntriesTable,
          PlaybackProgressEntry
        >,
      ),
      PlaybackProgressEntry,
      PrefetchHooks Function()
    >;
typedef $$AnimeIdentityEntriesTableCreateCompanionBuilder =
    AnimeIdentityEntriesCompanion Function({
      required String animeId,
      required DateTime createdAtUtc,
      Value<int> rowid,
    });
typedef $$AnimeIdentityEntriesTableUpdateCompanionBuilder =
    AnimeIdentityEntriesCompanion Function({
      Value<String> animeId,
      Value<DateTime> createdAtUtc,
      Value<int> rowid,
    });

final class $$AnimeIdentityEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AnimeIdentityEntriesTable,
          AnimeIdentityEntry
        > {
  $$AnimeIdentityEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ExternalAnimeIdentifiersTable,
    List<ExternalAnimeIdentifier>
  >
  _externalAnimeIdentifiersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.externalAnimeIdentifiers,
        aliasName: 'anime_identity_entries__anime_id__external_anime_identifiers__anime_id',
      );

  $$ExternalAnimeIdentifiersTableProcessedTableManager
  get externalAnimeIdentifiersRefs {
    final manager =
        $$ExternalAnimeIdentifiersTableTableManager(
          $_db,
          $_db.externalAnimeIdentifiers,
        ).filter(
          (f) => f.animeId.animeId.sqlEquals($_itemColumn<String>('anime_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _externalAnimeIdentifiersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AnimeIdentityRelationshipsTable,
    List<AnimeIdentityRelationship>
  >
  _outgoingRelationshipsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.animeIdentityRelationships,
        aliasName: 'anime_identity_entries__anime_id__anime_identity_relationships__source_anime_id',
      );

  $$AnimeIdentityRelationshipsTableProcessedTableManager
  get outgoingRelationships {
    final manager =
        $$AnimeIdentityRelationshipsTableTableManager(
          $_db,
          $_db.animeIdentityRelationships,
        ).filter(
          (f) => f.sourceAnimeId.animeId.sqlEquals(
            $_itemColumn<String>('anime_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _outgoingRelationshipsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AnimeIdentityRelationshipsTable,
    List<AnimeIdentityRelationship>
  >
  _incomingRelationshipsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.animeIdentityRelationships,
        aliasName: 'anime_identity_entries__anime_id__anime_identity_relationships__target_anime_id',
      );

  $$AnimeIdentityRelationshipsTableProcessedTableManager
  get incomingRelationships {
    final manager =
        $$AnimeIdentityRelationshipsTableTableManager(
          $_db,
          $_db.animeIdentityRelationships,
        ).filter(
          (f) => f.targetAnimeId.animeId.sqlEquals(
            $_itemColumn<String>('anime_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _incomingRelationshipsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalLibraryEntriesTable, List<LocalLibraryEntry>>
  _localLibraryEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localLibraryEntries,
        aliasName:
            'anime_identity_entries__anime_id__library_entries__anime_id',
      );

  $$LocalLibraryEntriesTableProcessedTableManager get localLibraryEntriesRefs {
    final manager =
        $$LocalLibraryEntriesTableTableManager(
          $_db,
          $_db.localLibraryEntries,
        ).filter(
          (f) => f.animeId.animeId.sqlEquals($_itemColumn<String>('anime_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _localLibraryEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AnimeIdentityEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AnimeIdentityEntriesTable> {
  $$AnimeIdentityEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get animeId => $composableBuilder(
    column: $table.animeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> externalAnimeIdentifiersRefs(
    Expression<bool> Function($$ExternalAnimeIdentifiersTableFilterComposer f)
    f,
  ) {
    final $$ExternalAnimeIdentifiersTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.externalAnimeIdentifiers,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExternalAnimeIdentifiersTableFilterComposer(
                $db: $db,
                $table: $db.externalAnimeIdentifiers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> outgoingRelationships(
    Expression<bool> Function($$AnimeIdentityRelationshipsTableFilterComposer f)
    f,
  ) {
    final $$AnimeIdentityRelationshipsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.animeIdentityRelationships,
          getReferencedColumn: (t) => t.sourceAnimeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityRelationshipsTableFilterComposer(
                $db: $db,
                $table: $db.animeIdentityRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> incomingRelationships(
    Expression<bool> Function($$AnimeIdentityRelationshipsTableFilterComposer f)
    f,
  ) {
    final $$AnimeIdentityRelationshipsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.animeIdentityRelationships,
          getReferencedColumn: (t) => t.targetAnimeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityRelationshipsTableFilterComposer(
                $db: $db,
                $table: $db.animeIdentityRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> localLibraryEntriesRefs(
    Expression<bool> Function($$LocalLibraryEntriesTableFilterComposer f) f,
  ) {
    final $$LocalLibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.localLibraryEntries,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalLibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.localLibraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnimeIdentityEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AnimeIdentityEntriesTable> {
  $$AnimeIdentityEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get animeId => $composableBuilder(
    column: $table.animeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnimeIdentityEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnimeIdentityEntriesTable> {
  $$AnimeIdentityEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get animeId =>
      $composableBuilder(column: $table.animeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  Expression<T> externalAnimeIdentifiersRefs<T extends Object>(
    Expression<T> Function($$ExternalAnimeIdentifiersTableAnnotationComposer a)
    f,
  ) {
    final $$ExternalAnimeIdentifiersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.externalAnimeIdentifiers,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExternalAnimeIdentifiersTableAnnotationComposer(
                $db: $db,
                $table: $db.externalAnimeIdentifiers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> outgoingRelationships<T extends Object>(
    Expression<T> Function(
      $$AnimeIdentityRelationshipsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$AnimeIdentityRelationshipsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.animeIdentityRelationships,
          getReferencedColumn: (t) => t.sourceAnimeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityRelationshipsTableAnnotationComposer(
                $db: $db,
                $table: $db.animeIdentityRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> incomingRelationships<T extends Object>(
    Expression<T> Function(
      $$AnimeIdentityRelationshipsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$AnimeIdentityRelationshipsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.animeIdentityRelationships,
          getReferencedColumn: (t) => t.targetAnimeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityRelationshipsTableAnnotationComposer(
                $db: $db,
                $table: $db.animeIdentityRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> localLibraryEntriesRefs<T extends Object>(
    Expression<T> Function($$LocalLibraryEntriesTableAnnotationComposer a) f,
  ) {
    final $$LocalLibraryEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.localLibraryEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalLibraryEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.localLibraryEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AnimeIdentityEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnimeIdentityEntriesTable,
          AnimeIdentityEntry,
          $$AnimeIdentityEntriesTableFilterComposer,
          $$AnimeIdentityEntriesTableOrderingComposer,
          $$AnimeIdentityEntriesTableAnnotationComposer,
          $$AnimeIdentityEntriesTableCreateCompanionBuilder,
          $$AnimeIdentityEntriesTableUpdateCompanionBuilder,
          (AnimeIdentityEntry, $$AnimeIdentityEntriesTableReferences),
          AnimeIdentityEntry,
          PrefetchHooks Function({
            bool externalAnimeIdentifiersRefs,
            bool outgoingRelationships,
            bool incomingRelationships,
            bool localLibraryEntriesRefs,
          })
        > {
  $$AnimeIdentityEntriesTableTableManager(
    _$AppDatabase db,
    $AnimeIdentityEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnimeIdentityEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnimeIdentityEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AnimeIdentityEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> animeId = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnimeIdentityEntriesCompanion(
                animeId: animeId,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String animeId,
                required DateTime createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => AnimeIdentityEntriesCompanion.insert(
                animeId: animeId,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnimeIdentityEntriesTable, AnimeIdentityEntry>(
                    table,
                  ),
                  $$AnimeIdentityEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                externalAnimeIdentifiersRefs = false,
                outgoingRelationships = false,
                incomingRelationships = false,
                localLibraryEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (externalAnimeIdentifiersRefs)
                      db.externalAnimeIdentifiers,
                    if (outgoingRelationships) db.animeIdentityRelationships,
                    if (incomingRelationships) db.animeIdentityRelationships,
                    if (localLibraryEntriesRefs) db.localLibraryEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (externalAnimeIdentifiersRefs)
                        await $_getPrefetchedDataByColumns<
                          AnimeIdentityEntry,
                          $AnimeIdentityEntriesTable,
                          ExternalAnimeIdentifier,
                          $ExternalAnimeIdentifiersTable
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeIdentityEntriesTableReferences
                              ._externalAnimeIdentifiersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeIdentityEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).externalAnimeIdentifiersRefs,
                          currentColumn: 'anime_id',
                          referencedColumn: 'anime_id',
                          typedResults: items,
                        ),
                      if (outgoingRelationships)
                        await $_getPrefetchedDataByColumns<
                          AnimeIdentityEntry,
                          $AnimeIdentityEntriesTable,
                          AnimeIdentityRelationship,
                          $AnimeIdentityRelationshipsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeIdentityEntriesTableReferences
                              ._outgoingRelationshipsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeIdentityEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).outgoingRelationships,
                          currentColumn: 'anime_id',
                          referencedColumn: 'source_anime_id',
                          typedResults: items,
                        ),
                      if (incomingRelationships)
                        await $_getPrefetchedDataByColumns<
                          AnimeIdentityEntry,
                          $AnimeIdentityEntriesTable,
                          AnimeIdentityRelationship,
                          $AnimeIdentityRelationshipsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeIdentityEntriesTableReferences
                              ._incomingRelationshipsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeIdentityEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingRelationships,
                          currentColumn: 'anime_id',
                          referencedColumn: 'target_anime_id',
                          typedResults: items,
                        ),
                      if (localLibraryEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          AnimeIdentityEntry,
                          $AnimeIdentityEntriesTable,
                          LocalLibraryEntry,
                          $LocalLibraryEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeIdentityEntriesTableReferences
                              ._localLibraryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeIdentityEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).localLibraryEntriesRefs,
                          currentColumn: 'anime_id',
                          referencedColumn: 'anime_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AnimeIdentityEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnimeIdentityEntriesTable,
      AnimeIdentityEntry,
      $$AnimeIdentityEntriesTableFilterComposer,
      $$AnimeIdentityEntriesTableOrderingComposer,
      $$AnimeIdentityEntriesTableAnnotationComposer,
      $$AnimeIdentityEntriesTableCreateCompanionBuilder,
      $$AnimeIdentityEntriesTableUpdateCompanionBuilder,
      (AnimeIdentityEntry, $$AnimeIdentityEntriesTableReferences),
      AnimeIdentityEntry,
      PrefetchHooks Function({
        bool externalAnimeIdentifiersRefs,
        bool outgoingRelationships,
        bool incomingRelationships,
        bool localLibraryEntriesRefs,
      })
    >;
typedef $$ExternalAnimeIdentifiersTableCreateCompanionBuilder =
    ExternalAnimeIdentifiersCompanion Function({
      required String providerId,
      required String externalId,
      required String animeId,
      required String evidence,
      required DateTime linkedAtUtc,
      Value<int> rowid,
    });
typedef $$ExternalAnimeIdentifiersTableUpdateCompanionBuilder =
    ExternalAnimeIdentifiersCompanion Function({
      Value<String> providerId,
      Value<String> externalId,
      Value<String> animeId,
      Value<String> evidence,
      Value<DateTime> linkedAtUtc,
      Value<int> rowid,
    });

final class $$ExternalAnimeIdentifiersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExternalAnimeIdentifiersTable,
          ExternalAnimeIdentifier
        > {
  $$ExternalAnimeIdentifiersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnimeIdentityEntriesTable _animeIdTable(
    _$AppDatabase db,
  ) => db.animeIdentityEntries.createAlias(
    'external_anime_identifiers__anime_id__anime_identity_entries__anime_id',
  );

  $$AnimeIdentityEntriesTableProcessedTableManager get animeId {
    final $_column = $_itemColumn<String>('anime_id')!;

    final manager = $$AnimeIdentityEntriesTableTableManager(
      $_db,
      $_db.animeIdentityEntries,
    ).filter((f) => f.animeId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExternalAnimeIdentifiersTableFilterComposer
    extends Composer<_$AppDatabase, $ExternalAnimeIdentifiersTable> {
  $$ExternalAnimeIdentifiersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidence => $composableBuilder(
    column: $table.evidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get linkedAtUtc => $composableBuilder(
    column: $table.linkedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeIdentityEntriesTableFilterComposer get animeId {
    final $$AnimeIdentityEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeIdentityEntries,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentityEntriesTableFilterComposer(
            $db: $db,
            $table: $db.animeIdentityEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExternalAnimeIdentifiersTableOrderingComposer
    extends Composer<_$AppDatabase, $ExternalAnimeIdentifiersTable> {
  $$ExternalAnimeIdentifiersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidence => $composableBuilder(
    column: $table.evidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get linkedAtUtc => $composableBuilder(
    column: $table.linkedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeIdentityEntriesTableOrderingComposer get animeId {
    final $$AnimeIdentityEntriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.animeIdentityEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityEntriesTableOrderingComposer(
                $db: $db,
                $table: $db.animeIdentityEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExternalAnimeIdentifiersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExternalAnimeIdentifiersTable> {
  $$ExternalAnimeIdentifiersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidence =>
      $composableBuilder(column: $table.evidence, builder: (column) => column);

  GeneratedColumn<DateTime> get linkedAtUtc => $composableBuilder(
    column: $table.linkedAtUtc,
    builder: (column) => column,
  );

  $$AnimeIdentityEntriesTableAnnotationComposer get animeId {
    final $$AnimeIdentityEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.animeIdentityEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.animeIdentityEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExternalAnimeIdentifiersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExternalAnimeIdentifiersTable,
          ExternalAnimeIdentifier,
          $$ExternalAnimeIdentifiersTableFilterComposer,
          $$ExternalAnimeIdentifiersTableOrderingComposer,
          $$ExternalAnimeIdentifiersTableAnnotationComposer,
          $$ExternalAnimeIdentifiersTableCreateCompanionBuilder,
          $$ExternalAnimeIdentifiersTableUpdateCompanionBuilder,
          (ExternalAnimeIdentifier, $$ExternalAnimeIdentifiersTableReferences),
          ExternalAnimeIdentifier,
          PrefetchHooks Function({bool animeId})
        > {
  $$ExternalAnimeIdentifiersTableTableManager(
    _$AppDatabase db,
    $ExternalAnimeIdentifiersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExternalAnimeIdentifiersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExternalAnimeIdentifiersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExternalAnimeIdentifiersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> animeId = const Value.absent(),
                Value<String> evidence = const Value.absent(),
                Value<DateTime> linkedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExternalAnimeIdentifiersCompanion(
                providerId: providerId,
                externalId: externalId,
                animeId: animeId,
                evidence: evidence,
                linkedAtUtc: linkedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String externalId,
                required String animeId,
                required String evidence,
                required DateTime linkedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => ExternalAnimeIdentifiersCompanion.insert(
                providerId: providerId,
                externalId: externalId,
                animeId: animeId,
                evidence: evidence,
                linkedAtUtc: linkedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ExternalAnimeIdentifiersTable,
                    ExternalAnimeIdentifier
                  >(table),
                  $$ExternalAnimeIdentifiersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({animeId = false}) {
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
                    if (animeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeId,
                        referencedTable:
                            $$ExternalAnimeIdentifiersTableReferences
                                ._animeIdTable(db),
                        referencedColumn:
                            $$ExternalAnimeIdentifiersTableReferences
                                ._animeIdTable(db)
                                .animeId,
                      ) as T;
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

typedef $$ExternalAnimeIdentifiersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExternalAnimeIdentifiersTable,
      ExternalAnimeIdentifier,
      $$ExternalAnimeIdentifiersTableFilterComposer,
      $$ExternalAnimeIdentifiersTableOrderingComposer,
      $$ExternalAnimeIdentifiersTableAnnotationComposer,
      $$ExternalAnimeIdentifiersTableCreateCompanionBuilder,
      $$ExternalAnimeIdentifiersTableUpdateCompanionBuilder,
      (ExternalAnimeIdentifier, $$ExternalAnimeIdentifiersTableReferences),
      ExternalAnimeIdentifier,
      PrefetchHooks Function({bool animeId})
    >;
typedef $$AnimeIdentityRelationshipsTableCreateCompanionBuilder =
    AnimeIdentityRelationshipsCompanion Function({
      required String sourceAnimeId,
      required String targetAnimeId,
      required String relationshipKind,
      required String evidence,
      required DateTime linkedAtUtc,
      Value<int> rowid,
    });
typedef $$AnimeIdentityRelationshipsTableUpdateCompanionBuilder =
    AnimeIdentityRelationshipsCompanion Function({
      Value<String> sourceAnimeId,
      Value<String> targetAnimeId,
      Value<String> relationshipKind,
      Value<String> evidence,
      Value<DateTime> linkedAtUtc,
      Value<int> rowid,
    });

final class $$AnimeIdentityRelationshipsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AnimeIdentityRelationshipsTable,
          AnimeIdentityRelationship
        > {
  $$AnimeIdentityRelationshipsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnimeIdentityEntriesTable _sourceAnimeIdTable(_$AppDatabase db) =>
      db.animeIdentityEntries.createAlias(
        'anime_identity_relationships__source_anime_id__anime_identity_entries__anime_id',
      );

  $$AnimeIdentityEntriesTableProcessedTableManager get sourceAnimeId {
    final $_column = $_itemColumn<String>('source_anime_id')!;

    final manager = $$AnimeIdentityEntriesTableTableManager(
      $_db,
      $_db.animeIdentityEntries,
    ).filter((f) => f.animeId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceAnimeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AnimeIdentityEntriesTable _targetAnimeIdTable(_$AppDatabase db) =>
      db.animeIdentityEntries.createAlias(
        'anime_identity_relationships__target_anime_id__anime_identity_entries__anime_id',
      );

  $$AnimeIdentityEntriesTableProcessedTableManager get targetAnimeId {
    final $_column = $_itemColumn<String>('target_anime_id')!;

    final manager = $$AnimeIdentityEntriesTableTableManager(
      $_db,
      $_db.animeIdentityEntries,
    ).filter((f) => f.animeId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetAnimeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnimeIdentityRelationshipsTableFilterComposer
    extends Composer<_$AppDatabase, $AnimeIdentityRelationshipsTable> {
  $$AnimeIdentityRelationshipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get relationshipKind => $composableBuilder(
    column: $table.relationshipKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidence => $composableBuilder(
    column: $table.evidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get linkedAtUtc => $composableBuilder(
    column: $table.linkedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeIdentityEntriesTableFilterComposer get sourceAnimeId {
    final $$AnimeIdentityEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAnimeId,
      referencedTable: $db.animeIdentityEntries,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentityEntriesTableFilterComposer(
            $db: $db,
            $table: $db.animeIdentityEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnimeIdentityEntriesTableFilterComposer get targetAnimeId {
    final $$AnimeIdentityEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetAnimeId,
      referencedTable: $db.animeIdentityEntries,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentityEntriesTableFilterComposer(
            $db: $db,
            $table: $db.animeIdentityEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnimeIdentityRelationshipsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnimeIdentityRelationshipsTable> {
  $$AnimeIdentityRelationshipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get relationshipKind => $composableBuilder(
    column: $table.relationshipKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidence => $composableBuilder(
    column: $table.evidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get linkedAtUtc => $composableBuilder(
    column: $table.linkedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeIdentityEntriesTableOrderingComposer get sourceAnimeId {
    final $$AnimeIdentityEntriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourceAnimeId,
          referencedTable: $db.animeIdentityEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityEntriesTableOrderingComposer(
                $db: $db,
                $table: $db.animeIdentityEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$AnimeIdentityEntriesTableOrderingComposer get targetAnimeId {
    final $$AnimeIdentityEntriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.targetAnimeId,
          referencedTable: $db.animeIdentityEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityEntriesTableOrderingComposer(
                $db: $db,
                $table: $db.animeIdentityEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AnimeIdentityRelationshipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnimeIdentityRelationshipsTable> {
  $$AnimeIdentityRelationshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get relationshipKind => $composableBuilder(
    column: $table.relationshipKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidence =>
      $composableBuilder(column: $table.evidence, builder: (column) => column);

  GeneratedColumn<DateTime> get linkedAtUtc => $composableBuilder(
    column: $table.linkedAtUtc,
    builder: (column) => column,
  );

  $$AnimeIdentityEntriesTableAnnotationComposer get sourceAnimeId {
    final $$AnimeIdentityEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourceAnimeId,
          referencedTable: $db.animeIdentityEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.animeIdentityEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$AnimeIdentityEntriesTableAnnotationComposer get targetAnimeId {
    final $$AnimeIdentityEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.targetAnimeId,
          referencedTable: $db.animeIdentityEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.animeIdentityEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AnimeIdentityRelationshipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnimeIdentityRelationshipsTable,
          AnimeIdentityRelationship,
          $$AnimeIdentityRelationshipsTableFilterComposer,
          $$AnimeIdentityRelationshipsTableOrderingComposer,
          $$AnimeIdentityRelationshipsTableAnnotationComposer,
          $$AnimeIdentityRelationshipsTableCreateCompanionBuilder,
          $$AnimeIdentityRelationshipsTableUpdateCompanionBuilder,
          (
            AnimeIdentityRelationship,
            $$AnimeIdentityRelationshipsTableReferences,
          ),
          AnimeIdentityRelationship,
          PrefetchHooks Function({bool sourceAnimeId, bool targetAnimeId})
        > {
  $$AnimeIdentityRelationshipsTableTableManager(
    _$AppDatabase db,
    $AnimeIdentityRelationshipsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnimeIdentityRelationshipsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AnimeIdentityRelationshipsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AnimeIdentityRelationshipsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sourceAnimeId = const Value.absent(),
                Value<String> targetAnimeId = const Value.absent(),
                Value<String> relationshipKind = const Value.absent(),
                Value<String> evidence = const Value.absent(),
                Value<DateTime> linkedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnimeIdentityRelationshipsCompanion(
                sourceAnimeId: sourceAnimeId,
                targetAnimeId: targetAnimeId,
                relationshipKind: relationshipKind,
                evidence: evidence,
                linkedAtUtc: linkedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceAnimeId,
                required String targetAnimeId,
                required String relationshipKind,
                required String evidence,
                required DateTime linkedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => AnimeIdentityRelationshipsCompanion.insert(
                sourceAnimeId: sourceAnimeId,
                targetAnimeId: targetAnimeId,
                relationshipKind: relationshipKind,
                evidence: evidence,
                linkedAtUtc: linkedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AnimeIdentityRelationshipsTable,
                    AnimeIdentityRelationship
                  >(table),
                  $$AnimeIdentityRelationshipsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceAnimeId = false, targetAnimeId = false}) {
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
                        if (sourceAnimeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceAnimeId,
                            referencedTable:
                                $$AnimeIdentityRelationshipsTableReferences
                                    ._sourceAnimeIdTable(db),
                            referencedColumn:
                                $$AnimeIdentityRelationshipsTableReferences
                                    ._sourceAnimeIdTable(db)
                                    .animeId,
                          ) as T;
                        }
                        if (targetAnimeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.targetAnimeId,
                            referencedTable:
                                $$AnimeIdentityRelationshipsTableReferences
                                    ._targetAnimeIdTable(db),
                            referencedColumn:
                                $$AnimeIdentityRelationshipsTableReferences
                                    ._targetAnimeIdTable(db)
                                    .animeId,
                          ) as T;
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

typedef $$AnimeIdentityRelationshipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnimeIdentityRelationshipsTable,
      AnimeIdentityRelationship,
      $$AnimeIdentityRelationshipsTableFilterComposer,
      $$AnimeIdentityRelationshipsTableOrderingComposer,
      $$AnimeIdentityRelationshipsTableAnnotationComposer,
      $$AnimeIdentityRelationshipsTableCreateCompanionBuilder,
      $$AnimeIdentityRelationshipsTableUpdateCompanionBuilder,
      (AnimeIdentityRelationship, $$AnimeIdentityRelationshipsTableReferences),
      AnimeIdentityRelationship,
      PrefetchHooks Function({bool sourceAnimeId, bool targetAnimeId})
    >;
typedef $$LocalLibraryEntriesTableCreateCompanionBuilder =
    LocalLibraryEntriesCompanion Function({
      required String animeId,
      required DateTime addedAtUtc,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$LocalLibraryEntriesTableUpdateCompanionBuilder =
    LocalLibraryEntriesCompanion Function({
      Value<String> animeId,
      Value<DateTime> addedAtUtc,
      Value<String> status,
      Value<int> rowid,
    });

final class $$LocalLibraryEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalLibraryEntriesTable,
          LocalLibraryEntry
        > {
  $$LocalLibraryEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnimeIdentityEntriesTable _animeIdTable(_$AppDatabase db) =>
      db.animeIdentityEntries.createAlias(
        'library_entries__anime_id__anime_identity_entries__anime_id',
      );

  $$AnimeIdentityEntriesTableProcessedTableManager get animeId {
    final $_column = $_itemColumn<String>('anime_id')!;

    final manager = $$AnimeIdentityEntriesTableTableManager(
      $_db,
      $_db.animeIdentityEntries,
    ).filter((f) => f.animeId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalLibraryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalLibraryEntriesTable> {
  $$LocalLibraryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get addedAtUtc => $composableBuilder(
    column: $table.addedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeIdentityEntriesTableFilterComposer get animeId {
    final $$AnimeIdentityEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeIdentityEntries,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentityEntriesTableFilterComposer(
            $db: $db,
            $table: $db.animeIdentityEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalLibraryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalLibraryEntriesTable> {
  $$LocalLibraryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get addedAtUtc => $composableBuilder(
    column: $table.addedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeIdentityEntriesTableOrderingComposer get animeId {
    final $$AnimeIdentityEntriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.animeIdentityEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityEntriesTableOrderingComposer(
                $db: $db,
                $table: $db.animeIdentityEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalLibraryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalLibraryEntriesTable> {
  $$LocalLibraryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get addedAtUtc => $composableBuilder(
    column: $table.addedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$AnimeIdentityEntriesTableAnnotationComposer get animeId {
    final $$AnimeIdentityEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.animeId,
          referencedTable: $db.animeIdentityEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnimeIdentityEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.animeIdentityEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalLibraryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalLibraryEntriesTable,
          LocalLibraryEntry,
          $$LocalLibraryEntriesTableFilterComposer,
          $$LocalLibraryEntriesTableOrderingComposer,
          $$LocalLibraryEntriesTableAnnotationComposer,
          $$LocalLibraryEntriesTableCreateCompanionBuilder,
          $$LocalLibraryEntriesTableUpdateCompanionBuilder,
          (LocalLibraryEntry, $$LocalLibraryEntriesTableReferences),
          LocalLibraryEntry,
          PrefetchHooks Function({bool animeId})
        > {
  $$LocalLibraryEntriesTableTableManager(
    _$AppDatabase db,
    $LocalLibraryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalLibraryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalLibraryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalLibraryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> animeId = const Value.absent(),
                Value<DateTime> addedAtUtc = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalLibraryEntriesCompanion(
                animeId: animeId,
                addedAtUtc: addedAtUtc,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String animeId,
                required DateTime addedAtUtc,
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalLibraryEntriesCompanion.insert(
                animeId: animeId,
                addedAtUtc: addedAtUtc,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalLibraryEntriesTable, LocalLibraryEntry>(
                    table,
                  ),
                  $$LocalLibraryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({animeId = false}) {
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
                    if (animeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeId,
                        referencedTable: $$LocalLibraryEntriesTableReferences
                            ._animeIdTable(db),
                        referencedColumn: $$LocalLibraryEntriesTableReferences
                            ._animeIdTable(db)
                            .animeId,
                      ) as T;
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

typedef $$LocalLibraryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalLibraryEntriesTable,
      LocalLibraryEntry,
      $$LocalLibraryEntriesTableFilterComposer,
      $$LocalLibraryEntriesTableOrderingComposer,
      $$LocalLibraryEntriesTableAnnotationComposer,
      $$LocalLibraryEntriesTableCreateCompanionBuilder,
      $$LocalLibraryEntriesTableUpdateCompanionBuilder,
      (LocalLibraryEntry, $$LocalLibraryEntriesTableReferences),
      LocalLibraryEntry,
      PrefetchHooks Function({bool animeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
  $$ProgressDocumentsTableTableManager get progressDocuments =>
      $$ProgressDocumentsTableTableManager(_db, _db.progressDocuments);
  $$LatestAnimeSearchTableTableManager get latestAnimeSearch =>
      $$LatestAnimeSearchTableTableManager(_db, _db.latestAnimeSearch);
  $$PlaybackProgressEntriesTableTableManager get playbackProgressEntries =>
      $$PlaybackProgressEntriesTableTableManager(
        _db,
        _db.playbackProgressEntries,
      );
  $$AnimeIdentityEntriesTableTableManager get animeIdentityEntries =>
      $$AnimeIdentityEntriesTableTableManager(_db, _db.animeIdentityEntries);
  $$ExternalAnimeIdentifiersTableTableManager get externalAnimeIdentifiers =>
      $$ExternalAnimeIdentifiersTableTableManager(
        _db,
        _db.externalAnimeIdentifiers,
      );
  $$AnimeIdentityRelationshipsTableTableManager
  get animeIdentityRelationships =>
      $$AnimeIdentityRelationshipsTableTableManager(
        _db,
        _db.animeIdentityRelationships,
      );
  $$LocalLibraryEntriesTableTableManager get localLibraryEntries =>
      $$LocalLibraryEntriesTableTableManager(_db, _db.localLibraryEntries);
}
