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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settingsEntries,
    progressDocuments,
    latestAnimeSearch,
  ];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
  $$ProgressDocumentsTableTableManager get progressDocuments =>
      $$ProgressDocumentsTableTableManager(_db, _db.progressDocuments);
  $$LatestAnimeSearchTableTableManager get latestAnimeSearch =>
      $$LatestAnimeSearchTableTableManager(_db, _db.latestAnimeSearch);
}
