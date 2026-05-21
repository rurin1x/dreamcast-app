// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
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
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    updatedAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  const Profile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isActive: Value(isActive),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Profile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isActive: isActive ?? this.isActive,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isActive == this.isActive);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsRowsTable extends SettingsRows
    with TableInfo<$SettingsRowsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
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
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const SettingsRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SettingsRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      SettingsRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SettingsRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
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
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheEntriesTable extends CacheEntries
    with TableInfo<$CacheEntriesTable, CacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
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
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    valueJson,
    updatedAt,
    expiresAt,
    etag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
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
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
    );
  }

  @override
  $CacheEntriesTable createAlias(String alias) {
    return $CacheEntriesTable(attachedDatabase, alias);
  }
}

class CacheEntry extends DataClass implements Insertable<CacheEntry> {
  final String key;
  final String valueJson;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final String? etag;
  const CacheEntry({
    required this.key,
    required this.valueJson,
    required this.updatedAt,
    this.expiresAt,
    this.etag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  CacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
      updatedAt: Value(updatedAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEntry(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  CacheEntry copyWith({
    String? key,
    String? valueJson,
    DateTime? updatedAt,
    Value<DateTime?> expiresAt = const Value.absent(),
    Value<String?> etag = const Value.absent(),
  }) => CacheEntry(
    key: key ?? this.key,
    valueJson: valueJson ?? this.valueJson,
    updatedAt: updatedAt ?? this.updatedAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    etag: etag.present ? etag.value : this.etag,
  );
  CacheEntry copyWithCompanion(CacheEntriesCompanion data) {
    return CacheEntry(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntry(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson, updatedAt, expiresAt, etag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntry &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.updatedAt == this.updatedAt &&
          other.expiresAt == this.expiresAt &&
          other.etag == this.etag);
}

class CacheEntriesCompanion extends UpdateCompanion<CacheEntry> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> expiresAt;
  final Value<String?> etag;
  final Value<int> rowid;
  const CacheEntriesCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheEntriesCompanion.insert({
    required String key,
    required String valueJson,
    required DateTime updatedAt,
    this.expiresAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson),
       updatedAt = Value(updatedAt);
  static Insertable<CacheEntry> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? expiresAt,
    Expression<String>? etag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (etag != null) 'etag': etag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? expiresAt,
    Value<String?>? etag,
    Value<int>? rowid,
  }) {
    return CacheEntriesCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      etag: etag ?? this.etag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntriesCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('etag: $etag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackPositionsTable extends PlaybackPositions
    with TableInfo<$PlaybackPositionsTable, PlaybackPosition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _releaseIdMeta = const VerificationMeta(
    'releaseId',
  );
  @override
  late final GeneratedColumn<String> releaseId = GeneratedColumn<String>(
    'release_id',
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    releaseId,
    episodeId,
    positionMs,
    durationMs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackPosition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('release_id')) {
      context.handle(
        _releaseIdMeta,
        releaseId.isAcceptableOrUnknown(data['release_id']!, _releaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_releaseIdMeta);
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
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {releaseId, episodeId};
  @override
  PlaybackPosition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackPosition(
      releaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_id'],
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaybackPositionsTable createAlias(String alias) {
    return $PlaybackPositionsTable(attachedDatabase, alias);
  }
}

class PlaybackPosition extends DataClass
    implements Insertable<PlaybackPosition> {
  final String releaseId;
  final String episodeId;
  final int positionMs;
  final int? durationMs;
  final DateTime updatedAt;
  const PlaybackPosition({
    required this.releaseId,
    required this.episodeId,
    required this.positionMs,
    this.durationMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['release_id'] = Variable<String>(releaseId);
    map['episode_id'] = Variable<String>(episodeId);
    map['position_ms'] = Variable<int>(positionMs);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaybackPositionsCompanion toCompanion(bool nullToAbsent) {
    return PlaybackPositionsCompanion(
      releaseId: Value(releaseId),
      episodeId: Value(episodeId),
      positionMs: Value(positionMs),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaybackPosition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackPosition(
      releaseId: serializer.fromJson<String>(json['releaseId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'releaseId': serializer.toJson<String>(releaseId),
      'episodeId': serializer.toJson<String>(episodeId),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int?>(durationMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaybackPosition copyWith({
    String? releaseId,
    String? episodeId,
    int? positionMs,
    Value<int?> durationMs = const Value.absent(),
    DateTime? updatedAt,
  }) => PlaybackPosition(
    releaseId: releaseId ?? this.releaseId,
    episodeId: episodeId ?? this.episodeId,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaybackPosition copyWithCompanion(PlaybackPositionsCompanion data) {
    return PlaybackPosition(
      releaseId: data.releaseId.present ? data.releaseId.value : this.releaseId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackPosition(')
          ..write('releaseId: $releaseId, ')
          ..write('episodeId: $episodeId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(releaseId, episodeId, positionMs, durationMs, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackPosition &&
          other.releaseId == this.releaseId &&
          other.episodeId == this.episodeId &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.updatedAt == this.updatedAt);
}

class PlaybackPositionsCompanion extends UpdateCompanion<PlaybackPosition> {
  final Value<String> releaseId;
  final Value<String> episodeId;
  final Value<int> positionMs;
  final Value<int?> durationMs;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaybackPositionsCompanion({
    this.releaseId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackPositionsCompanion.insert({
    required String releaseId,
    required String episodeId,
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : releaseId = Value(releaseId),
       episodeId = Value(episodeId),
       updatedAt = Value(updatedAt);
  static Insertable<PlaybackPosition> custom({
    Expression<String>? releaseId,
    Expression<String>? episodeId,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (releaseId != null) 'release_id': releaseId,
      if (episodeId != null) 'episode_id': episodeId,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackPositionsCompanion copyWith({
    Value<String>? releaseId,
    Value<String>? episodeId,
    Value<int>? positionMs,
    Value<int?>? durationMs,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaybackPositionsCompanion(
      releaseId: releaseId ?? this.releaseId,
      episodeId: episodeId ?? this.episodeId,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (releaseId.present) {
      map['release_id'] = Variable<String>(releaseId.value);
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
    return (StringBuffer('PlaybackPositionsCompanion(')
          ..write('releaseId: $releaseId, ')
          ..write('episodeId: $episodeId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreamSessionsTable extends StreamSessions
    with TableInfo<$StreamSessionsTable, StreamSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreamSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releaseIdMeta = const VerificationMeta(
    'releaseId',
  );
  @override
  late final GeneratedColumn<String> releaseId = GeneratedColumn<String>(
    'release_id',
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
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headersJsonMeta = const VerificationMeta(
    'headersJson',
  );
  @override
  late final GeneratedColumn<String> headersJson = GeneratedColumn<String>(
    'headers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    releaseId,
    episodeId,
    url,
    type,
    quality,
    headersJson,
    createdAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stream_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreamSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('release_id')) {
      context.handle(
        _releaseIdMeta,
        releaseId.isAcceptableOrUnknown(data['release_id']!, _releaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_releaseIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('headers_json')) {
      context.handle(
        _headersJsonMeta,
        headersJson.isAcceptableOrUnknown(
          data['headers_json']!,
          _headersJsonMeta,
        ),
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
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreamSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreamSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      releaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quality'],
      )!,
      headersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
    );
  }

  @override
  $StreamSessionsTable createAlias(String alias) {
    return $StreamSessionsTable(attachedDatabase, alias);
  }
}

class StreamSession extends DataClass implements Insertable<StreamSession> {
  final String id;
  final String releaseId;
  final String episodeId;
  final String url;
  final String type;
  final int quality;
  final String headersJson;
  final DateTime createdAt;
  final DateTime? expiresAt;
  const StreamSession({
    required this.id,
    required this.releaseId,
    required this.episodeId,
    required this.url,
    required this.type,
    required this.quality,
    required this.headersJson,
    required this.createdAt,
    this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['release_id'] = Variable<String>(releaseId);
    map['episode_id'] = Variable<String>(episodeId);
    map['url'] = Variable<String>(url);
    map['type'] = Variable<String>(type);
    map['quality'] = Variable<int>(quality);
    map['headers_json'] = Variable<String>(headersJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  StreamSessionsCompanion toCompanion(bool nullToAbsent) {
    return StreamSessionsCompanion(
      id: Value(id),
      releaseId: Value(releaseId),
      episodeId: Value(episodeId),
      url: Value(url),
      type: Value(type),
      quality: Value(quality),
      headersJson: Value(headersJson),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory StreamSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreamSession(
      id: serializer.fromJson<String>(json['id']),
      releaseId: serializer.fromJson<String>(json['releaseId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      url: serializer.fromJson<String>(json['url']),
      type: serializer.fromJson<String>(json['type']),
      quality: serializer.fromJson<int>(json['quality']),
      headersJson: serializer.fromJson<String>(json['headersJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'releaseId': serializer.toJson<String>(releaseId),
      'episodeId': serializer.toJson<String>(episodeId),
      'url': serializer.toJson<String>(url),
      'type': serializer.toJson<String>(type),
      'quality': serializer.toJson<int>(quality),
      'headersJson': serializer.toJson<String>(headersJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  StreamSession copyWith({
    String? id,
    String? releaseId,
    String? episodeId,
    String? url,
    String? type,
    int? quality,
    String? headersJson,
    DateTime? createdAt,
    Value<DateTime?> expiresAt = const Value.absent(),
  }) => StreamSession(
    id: id ?? this.id,
    releaseId: releaseId ?? this.releaseId,
    episodeId: episodeId ?? this.episodeId,
    url: url ?? this.url,
    type: type ?? this.type,
    quality: quality ?? this.quality,
    headersJson: headersJson ?? this.headersJson,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
  );
  StreamSession copyWithCompanion(StreamSessionsCompanion data) {
    return StreamSession(
      id: data.id.present ? data.id.value : this.id,
      releaseId: data.releaseId.present ? data.releaseId.value : this.releaseId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      url: data.url.present ? data.url.value : this.url,
      type: data.type.present ? data.type.value : this.type,
      quality: data.quality.present ? data.quality.value : this.quality,
      headersJson: data.headersJson.present
          ? data.headersJson.value
          : this.headersJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreamSession(')
          ..write('id: $id, ')
          ..write('releaseId: $releaseId, ')
          ..write('episodeId: $episodeId, ')
          ..write('url: $url, ')
          ..write('type: $type, ')
          ..write('quality: $quality, ')
          ..write('headersJson: $headersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    releaseId,
    episodeId,
    url,
    type,
    quality,
    headersJson,
    createdAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreamSession &&
          other.id == this.id &&
          other.releaseId == this.releaseId &&
          other.episodeId == this.episodeId &&
          other.url == this.url &&
          other.type == this.type &&
          other.quality == this.quality &&
          other.headersJson == this.headersJson &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class StreamSessionsCompanion extends UpdateCompanion<StreamSession> {
  final Value<String> id;
  final Value<String> releaseId;
  final Value<String> episodeId;
  final Value<String> url;
  final Value<String> type;
  final Value<int> quality;
  final Value<String> headersJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> expiresAt;
  final Value<int> rowid;
  const StreamSessionsCompanion({
    this.id = const Value.absent(),
    this.releaseId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.url = const Value.absent(),
    this.type = const Value.absent(),
    this.quality = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreamSessionsCompanion.insert({
    required String id,
    required String releaseId,
    required String episodeId,
    required String url,
    required String type,
    required int quality,
    this.headersJson = const Value.absent(),
    required DateTime createdAt,
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       releaseId = Value(releaseId),
       episodeId = Value(episodeId),
       url = Value(url),
       type = Value(type),
       quality = Value(quality),
       createdAt = Value(createdAt);
  static Insertable<StreamSession> custom({
    Expression<String>? id,
    Expression<String>? releaseId,
    Expression<String>? episodeId,
    Expression<String>? url,
    Expression<String>? type,
    Expression<int>? quality,
    Expression<String>? headersJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (releaseId != null) 'release_id': releaseId,
      if (episodeId != null) 'episode_id': episodeId,
      if (url != null) 'url': url,
      if (type != null) 'type': type,
      if (quality != null) 'quality': quality,
      if (headersJson != null) 'headers_json': headersJson,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreamSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? releaseId,
    Value<String>? episodeId,
    Value<String>? url,
    Value<String>? type,
    Value<int>? quality,
    Value<String>? headersJson,
    Value<DateTime>? createdAt,
    Value<DateTime?>? expiresAt,
    Value<int>? rowid,
  }) {
    return StreamSessionsCompanion(
      id: id ?? this.id,
      releaseId: releaseId ?? this.releaseId,
      episodeId: episodeId ?? this.episodeId,
      url: url ?? this.url,
      type: type ?? this.type,
      quality: quality ?? this.quality,
      headersJson: headersJson ?? this.headersJson,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (releaseId.present) {
      map['release_id'] = Variable<String>(releaseId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (headersJson.present) {
      map['headers_json'] = Variable<String>(headersJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreamSessionsCompanion(')
          ..write('id: $id, ')
          ..write('releaseId: $releaseId, ')
          ..write('episodeId: $episodeId, ')
          ..write('url: $url, ')
          ..write('type: $type, ')
          ..write('quality: $quality, ')
          ..write('headersJson: $headersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchEntriesTable extends WatchEntries
    with TableInfo<$WatchEntriesTable, WatchEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _releaseIdMeta = const VerificationMeta(
    'releaseId',
  );
  @override
  late final GeneratedColumn<String> releaseId = GeneratedColumn<String>(
    'release_id',
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
  static const VerificationMeta _releaseTitleMeta = const VerificationMeta(
    'releaseTitle',
  );
  @override
  late final GeneratedColumn<String> releaseTitle = GeneratedColumn<String>(
    'release_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeTitleMeta = const VerificationMeta(
    'episodeTitle',
  );
  @override
  late final GeneratedColumn<String> episodeTitle = GeneratedColumn<String>(
    'episode_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta(
    'posterUrl',
  );
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeOrdinalMeta = const VerificationMeta(
    'episodeOrdinal',
  );
  @override
  late final GeneratedColumn<int> episodeOrdinal = GeneratedColumn<int>(
    'episode_ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _isWatchedMeta = const VerificationMeta(
    'isWatched',
  );
  @override
  late final GeneratedColumn<bool> isWatched = GeneratedColumn<bool>(
    'is_watched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_watched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    releaseId,
    episodeId,
    releaseTitle,
    episodeTitle,
    posterUrl,
    episodeOrdinal,
    positionMs,
    durationMs,
    isWatched,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('release_id')) {
      context.handle(
        _releaseIdMeta,
        releaseId.isAcceptableOrUnknown(data['release_id']!, _releaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_releaseIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('release_title')) {
      context.handle(
        _releaseTitleMeta,
        releaseTitle.isAcceptableOrUnknown(
          data['release_title']!,
          _releaseTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_releaseTitleMeta);
    }
    if (data.containsKey('episode_title')) {
      context.handle(
        _episodeTitleMeta,
        episodeTitle.isAcceptableOrUnknown(
          data['episode_title']!,
          _episodeTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeTitleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(
        _posterUrlMeta,
        posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta),
      );
    }
    if (data.containsKey('episode_ordinal')) {
      context.handle(
        _episodeOrdinalMeta,
        episodeOrdinal.isAcceptableOrUnknown(
          data['episode_ordinal']!,
          _episodeOrdinalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeOrdinalMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('is_watched')) {
      context.handle(
        _isWatchedMeta,
        isWatched.isAcceptableOrUnknown(data['is_watched']!, _isWatchedMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {releaseId, episodeId};
  @override
  WatchEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchEntry(
      releaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      )!,
      releaseTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_title'],
      )!,
      episodeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_title'],
      )!,
      posterUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_url'],
      ),
      episodeOrdinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_ordinal'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      isWatched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_watched'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WatchEntriesTable createAlias(String alias) {
    return $WatchEntriesTable(attachedDatabase, alias);
  }
}

class WatchEntry extends DataClass implements Insertable<WatchEntry> {
  final String releaseId;
  final String episodeId;
  final String releaseTitle;
  final String episodeTitle;
  final String? posterUrl;
  final int episodeOrdinal;
  final int positionMs;
  final int? durationMs;
  final bool isWatched;
  final DateTime updatedAt;
  const WatchEntry({
    required this.releaseId,
    required this.episodeId,
    required this.releaseTitle,
    required this.episodeTitle,
    this.posterUrl,
    required this.episodeOrdinal,
    required this.positionMs,
    this.durationMs,
    required this.isWatched,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['release_id'] = Variable<String>(releaseId);
    map['episode_id'] = Variable<String>(episodeId);
    map['release_title'] = Variable<String>(releaseTitle);
    map['episode_title'] = Variable<String>(episodeTitle);
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    map['episode_ordinal'] = Variable<int>(episodeOrdinal);
    map['position_ms'] = Variable<int>(positionMs);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['is_watched'] = Variable<bool>(isWatched);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WatchEntriesCompanion toCompanion(bool nullToAbsent) {
    return WatchEntriesCompanion(
      releaseId: Value(releaseId),
      episodeId: Value(episodeId),
      releaseTitle: Value(releaseTitle),
      episodeTitle: Value(episodeTitle),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      episodeOrdinal: Value(episodeOrdinal),
      positionMs: Value(positionMs),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      isWatched: Value(isWatched),
      updatedAt: Value(updatedAt),
    );
  }

  factory WatchEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchEntry(
      releaseId: serializer.fromJson<String>(json['releaseId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      releaseTitle: serializer.fromJson<String>(json['releaseTitle']),
      episodeTitle: serializer.fromJson<String>(json['episodeTitle']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      episodeOrdinal: serializer.fromJson<int>(json['episodeOrdinal']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      isWatched: serializer.fromJson<bool>(json['isWatched']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'releaseId': serializer.toJson<String>(releaseId),
      'episodeId': serializer.toJson<String>(episodeId),
      'releaseTitle': serializer.toJson<String>(releaseTitle),
      'episodeTitle': serializer.toJson<String>(episodeTitle),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'episodeOrdinal': serializer.toJson<int>(episodeOrdinal),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int?>(durationMs),
      'isWatched': serializer.toJson<bool>(isWatched),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WatchEntry copyWith({
    String? releaseId,
    String? episodeId,
    String? releaseTitle,
    String? episodeTitle,
    Value<String?> posterUrl = const Value.absent(),
    int? episodeOrdinal,
    int? positionMs,
    Value<int?> durationMs = const Value.absent(),
    bool? isWatched,
    DateTime? updatedAt,
  }) => WatchEntry(
    releaseId: releaseId ?? this.releaseId,
    episodeId: episodeId ?? this.episodeId,
    releaseTitle: releaseTitle ?? this.releaseTitle,
    episodeTitle: episodeTitle ?? this.episodeTitle,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    episodeOrdinal: episodeOrdinal ?? this.episodeOrdinal,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    isWatched: isWatched ?? this.isWatched,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WatchEntry copyWithCompanion(WatchEntriesCompanion data) {
    return WatchEntry(
      releaseId: data.releaseId.present ? data.releaseId.value : this.releaseId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      releaseTitle: data.releaseTitle.present
          ? data.releaseTitle.value
          : this.releaseTitle,
      episodeTitle: data.episodeTitle.present
          ? data.episodeTitle.value
          : this.episodeTitle,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      episodeOrdinal: data.episodeOrdinal.present
          ? data.episodeOrdinal.value
          : this.episodeOrdinal,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      isWatched: data.isWatched.present ? data.isWatched.value : this.isWatched,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchEntry(')
          ..write('releaseId: $releaseId, ')
          ..write('episodeId: $episodeId, ')
          ..write('releaseTitle: $releaseTitle, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('episodeOrdinal: $episodeOrdinal, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('isWatched: $isWatched, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    releaseId,
    episodeId,
    releaseTitle,
    episodeTitle,
    posterUrl,
    episodeOrdinal,
    positionMs,
    durationMs,
    isWatched,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchEntry &&
          other.releaseId == this.releaseId &&
          other.episodeId == this.episodeId &&
          other.releaseTitle == this.releaseTitle &&
          other.episodeTitle == this.episodeTitle &&
          other.posterUrl == this.posterUrl &&
          other.episodeOrdinal == this.episodeOrdinal &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.isWatched == this.isWatched &&
          other.updatedAt == this.updatedAt);
}

class WatchEntriesCompanion extends UpdateCompanion<WatchEntry> {
  final Value<String> releaseId;
  final Value<String> episodeId;
  final Value<String> releaseTitle;
  final Value<String> episodeTitle;
  final Value<String?> posterUrl;
  final Value<int> episodeOrdinal;
  final Value<int> positionMs;
  final Value<int?> durationMs;
  final Value<bool> isWatched;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WatchEntriesCompanion({
    this.releaseId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.releaseTitle = const Value.absent(),
    this.episodeTitle = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.episodeOrdinal = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.isWatched = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchEntriesCompanion.insert({
    required String releaseId,
    required String episodeId,
    required String releaseTitle,
    required String episodeTitle,
    this.posterUrl = const Value.absent(),
    required int episodeOrdinal,
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.isWatched = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : releaseId = Value(releaseId),
       episodeId = Value(episodeId),
       releaseTitle = Value(releaseTitle),
       episodeTitle = Value(episodeTitle),
       episodeOrdinal = Value(episodeOrdinal),
       updatedAt = Value(updatedAt);
  static Insertable<WatchEntry> custom({
    Expression<String>? releaseId,
    Expression<String>? episodeId,
    Expression<String>? releaseTitle,
    Expression<String>? episodeTitle,
    Expression<String>? posterUrl,
    Expression<int>? episodeOrdinal,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<bool>? isWatched,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (releaseId != null) 'release_id': releaseId,
      if (episodeId != null) 'episode_id': episodeId,
      if (releaseTitle != null) 'release_title': releaseTitle,
      if (episodeTitle != null) 'episode_title': episodeTitle,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (episodeOrdinal != null) 'episode_ordinal': episodeOrdinal,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (isWatched != null) 'is_watched': isWatched,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchEntriesCompanion copyWith({
    Value<String>? releaseId,
    Value<String>? episodeId,
    Value<String>? releaseTitle,
    Value<String>? episodeTitle,
    Value<String?>? posterUrl,
    Value<int>? episodeOrdinal,
    Value<int>? positionMs,
    Value<int?>? durationMs,
    Value<bool>? isWatched,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WatchEntriesCompanion(
      releaseId: releaseId ?? this.releaseId,
      episodeId: episodeId ?? this.episodeId,
      releaseTitle: releaseTitle ?? this.releaseTitle,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      episodeOrdinal: episodeOrdinal ?? this.episodeOrdinal,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      isWatched: isWatched ?? this.isWatched,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (releaseId.present) {
      map['release_id'] = Variable<String>(releaseId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (releaseTitle.present) {
      map['release_title'] = Variable<String>(releaseTitle.value);
    }
    if (episodeTitle.present) {
      map['episode_title'] = Variable<String>(episodeTitle.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (episodeOrdinal.present) {
      map['episode_ordinal'] = Variable<int>(episodeOrdinal.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (isWatched.present) {
      map['is_watched'] = Variable<bool>(isWatched.value);
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
    return (StringBuffer('WatchEntriesCompanion(')
          ..write('releaseId: $releaseId, ')
          ..write('episodeId: $episodeId, ')
          ..write('releaseTitle: $releaseTitle, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('episodeOrdinal: $episodeOrdinal, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('isWatched: $isWatched, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadedEpisodesTable extends DownloadedEpisodes
    with TableInfo<$DownloadedEpisodesTable, DownloadedEpisode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedEpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _releaseIdMeta = const VerificationMeta(
    'releaseId',
  );
  @override
  late final GeneratedColumn<int> releaseId = GeneratedColumn<int>(
    'release_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _releaseTitleMeta = const VerificationMeta(
    'releaseTitle',
  );
  @override
  late final GeneratedColumn<String> releaseTitle = GeneratedColumn<String>(
    'release_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeTitleMeta = const VerificationMeta(
    'episodeTitle',
  );
  @override
  late final GeneratedColumn<String> episodeTitle = GeneratedColumn<String>(
    'episode_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta(
    'posterUrl',
  );
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeOrdinalMeta = const VerificationMeta(
    'episodeOrdinal',
  );
  @override
  late final GeneratedColumn<int> episodeOrdinal = GeneratedColumn<int>(
    'episode_ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta(
    'downloadedBytes',
  );
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _streamQualityMeta = const VerificationMeta(
    'streamQuality',
  );
  @override
  late final GeneratedColumn<int> streamQuality = GeneratedColumn<int>(
    'stream_quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    releaseId,
    episodeId,
    releaseTitle,
    episodeTitle,
    posterUrl,
    episodeOrdinal,
    localFilePath,
    fileSize,
    downloadedBytes,
    status,
    streamQuality,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedEpisode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('release_id')) {
      context.handle(
        _releaseIdMeta,
        releaseId.isAcceptableOrUnknown(data['release_id']!, _releaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_releaseIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('release_title')) {
      context.handle(
        _releaseTitleMeta,
        releaseTitle.isAcceptableOrUnknown(
          data['release_title']!,
          _releaseTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_releaseTitleMeta);
    }
    if (data.containsKey('episode_title')) {
      context.handle(
        _episodeTitleMeta,
        episodeTitle.isAcceptableOrUnknown(
          data['episode_title']!,
          _episodeTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeTitleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(
        _posterUrlMeta,
        posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta),
      );
    }
    if (data.containsKey('episode_ordinal')) {
      context.handle(
        _episodeOrdinalMeta,
        episodeOrdinal.isAcceptableOrUnknown(
          data['episode_ordinal']!,
          _episodeOrdinalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeOrdinalMeta);
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localFilePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(
          data['downloaded_bytes']!,
          _downloadedBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedBytesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('stream_quality')) {
      context.handle(
        _streamQualityMeta,
        streamQuality.isAcceptableOrUnknown(
          data['stream_quality']!,
          _streamQualityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_streamQualityMeta);
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
  Set<GeneratedColumn> get $primaryKey => {releaseId, episodeId};
  @override
  DownloadedEpisode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedEpisode(
      releaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      )!,
      releaseTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_title'],
      )!,
      episodeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_title'],
      )!,
      posterUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_url'],
      ),
      episodeOrdinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_ordinal'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      downloadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_bytes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      streamQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_quality'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DownloadedEpisodesTable createAlias(String alias) {
    return $DownloadedEpisodesTable(attachedDatabase, alias);
  }
}

class DownloadedEpisode extends DataClass
    implements Insertable<DownloadedEpisode> {
  final int releaseId;
  final String episodeId;
  final String releaseTitle;
  final String episodeTitle;
  final String? posterUrl;
  final int episodeOrdinal;
  final String localFilePath;
  final int fileSize;
  final int downloadedBytes;
  final String status;
  final int streamQuality;
  final DateTime createdAt;
  const DownloadedEpisode({
    required this.releaseId,
    required this.episodeId,
    required this.releaseTitle,
    required this.episodeTitle,
    this.posterUrl,
    required this.episodeOrdinal,
    required this.localFilePath,
    required this.fileSize,
    required this.downloadedBytes,
    required this.status,
    required this.streamQuality,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['release_id'] = Variable<int>(releaseId);
    map['episode_id'] = Variable<String>(episodeId);
    map['release_title'] = Variable<String>(releaseTitle);
    map['episode_title'] = Variable<String>(episodeTitle);
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    map['episode_ordinal'] = Variable<int>(episodeOrdinal);
    map['local_file_path'] = Variable<String>(localFilePath);
    map['file_size'] = Variable<int>(fileSize);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['status'] = Variable<String>(status);
    map['stream_quality'] = Variable<int>(streamQuality);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DownloadedEpisodesCompanion toCompanion(bool nullToAbsent) {
    return DownloadedEpisodesCompanion(
      releaseId: Value(releaseId),
      episodeId: Value(episodeId),
      releaseTitle: Value(releaseTitle),
      episodeTitle: Value(episodeTitle),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      episodeOrdinal: Value(episodeOrdinal),
      localFilePath: Value(localFilePath),
      fileSize: Value(fileSize),
      downloadedBytes: Value(downloadedBytes),
      status: Value(status),
      streamQuality: Value(streamQuality),
      createdAt: Value(createdAt),
    );
  }

  factory DownloadedEpisode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedEpisode(
      releaseId: serializer.fromJson<int>(json['releaseId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      releaseTitle: serializer.fromJson<String>(json['releaseTitle']),
      episodeTitle: serializer.fromJson<String>(json['episodeTitle']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      episodeOrdinal: serializer.fromJson<int>(json['episodeOrdinal']),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      status: serializer.fromJson<String>(json['status']),
      streamQuality: serializer.fromJson<int>(json['streamQuality']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'releaseId': serializer.toJson<int>(releaseId),
      'episodeId': serializer.toJson<String>(episodeId),
      'releaseTitle': serializer.toJson<String>(releaseTitle),
      'episodeTitle': serializer.toJson<String>(episodeTitle),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'episodeOrdinal': serializer.toJson<int>(episodeOrdinal),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'status': serializer.toJson<String>(status),
      'streamQuality': serializer.toJson<int>(streamQuality),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DownloadedEpisode copyWith({
    int? releaseId,
    String? episodeId,
    String? releaseTitle,
    String? episodeTitle,
    Value<String?> posterUrl = const Value.absent(),
    int? episodeOrdinal,
    String? localFilePath,
    int? fileSize,
    int? downloadedBytes,
    String? status,
    int? streamQuality,
    DateTime? createdAt,
  }) => DownloadedEpisode(
    releaseId: releaseId ?? this.releaseId,
    episodeId: episodeId ?? this.episodeId,
    releaseTitle: releaseTitle ?? this.releaseTitle,
    episodeTitle: episodeTitle ?? this.episodeTitle,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    episodeOrdinal: episodeOrdinal ?? this.episodeOrdinal,
    localFilePath: localFilePath ?? this.localFilePath,
    fileSize: fileSize ?? this.fileSize,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    status: status ?? this.status,
    streamQuality: streamQuality ?? this.streamQuality,
    createdAt: createdAt ?? this.createdAt,
  );
  DownloadedEpisode copyWithCompanion(DownloadedEpisodesCompanion data) {
    return DownloadedEpisode(
      releaseId: data.releaseId.present ? data.releaseId.value : this.releaseId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      releaseTitle: data.releaseTitle.present
          ? data.releaseTitle.value
          : this.releaseTitle,
      episodeTitle: data.episodeTitle.present
          ? data.episodeTitle.value
          : this.episodeTitle,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      episodeOrdinal: data.episodeOrdinal.present
          ? data.episodeOrdinal.value
          : this.episodeOrdinal,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      status: data.status.present ? data.status.value : this.status,
      streamQuality: data.streamQuality.present
          ? data.streamQuality.value
          : this.streamQuality,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedEpisode(')
          ..write('releaseId: $releaseId, ')
          ..write('episodeId: $episodeId, ')
          ..write('releaseTitle: $releaseTitle, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('episodeOrdinal: $episodeOrdinal, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('status: $status, ')
          ..write('streamQuality: $streamQuality, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    releaseId,
    episodeId,
    releaseTitle,
    episodeTitle,
    posterUrl,
    episodeOrdinal,
    localFilePath,
    fileSize,
    downloadedBytes,
    status,
    streamQuality,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedEpisode &&
          other.releaseId == this.releaseId &&
          other.episodeId == this.episodeId &&
          other.releaseTitle == this.releaseTitle &&
          other.episodeTitle == this.episodeTitle &&
          other.posterUrl == this.posterUrl &&
          other.episodeOrdinal == this.episodeOrdinal &&
          other.localFilePath == this.localFilePath &&
          other.fileSize == this.fileSize &&
          other.downloadedBytes == this.downloadedBytes &&
          other.status == this.status &&
          other.streamQuality == this.streamQuality &&
          other.createdAt == this.createdAt);
}

class DownloadedEpisodesCompanion extends UpdateCompanion<DownloadedEpisode> {
  final Value<int> releaseId;
  final Value<String> episodeId;
  final Value<String> releaseTitle;
  final Value<String> episodeTitle;
  final Value<String?> posterUrl;
  final Value<int> episodeOrdinal;
  final Value<String> localFilePath;
  final Value<int> fileSize;
  final Value<int> downloadedBytes;
  final Value<String> status;
  final Value<int> streamQuality;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DownloadedEpisodesCompanion({
    this.releaseId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.releaseTitle = const Value.absent(),
    this.episodeTitle = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.episodeOrdinal = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.streamQuality = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedEpisodesCompanion.insert({
    required int releaseId,
    required String episodeId,
    required String releaseTitle,
    required String episodeTitle,
    this.posterUrl = const Value.absent(),
    required int episodeOrdinal,
    required String localFilePath,
    required int fileSize,
    required int downloadedBytes,
    required String status,
    required int streamQuality,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : releaseId = Value(releaseId),
       episodeId = Value(episodeId),
       releaseTitle = Value(releaseTitle),
       episodeTitle = Value(episodeTitle),
       episodeOrdinal = Value(episodeOrdinal),
       localFilePath = Value(localFilePath),
       fileSize = Value(fileSize),
       downloadedBytes = Value(downloadedBytes),
       status = Value(status),
       streamQuality = Value(streamQuality),
       createdAt = Value(createdAt);
  static Insertable<DownloadedEpisode> custom({
    Expression<int>? releaseId,
    Expression<String>? episodeId,
    Expression<String>? releaseTitle,
    Expression<String>? episodeTitle,
    Expression<String>? posterUrl,
    Expression<int>? episodeOrdinal,
    Expression<String>? localFilePath,
    Expression<int>? fileSize,
    Expression<int>? downloadedBytes,
    Expression<String>? status,
    Expression<int>? streamQuality,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (releaseId != null) 'release_id': releaseId,
      if (episodeId != null) 'episode_id': episodeId,
      if (releaseTitle != null) 'release_title': releaseTitle,
      if (episodeTitle != null) 'episode_title': episodeTitle,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (episodeOrdinal != null) 'episode_ordinal': episodeOrdinal,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (fileSize != null) 'file_size': fileSize,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (status != null) 'status': status,
      if (streamQuality != null) 'stream_quality': streamQuality,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedEpisodesCompanion copyWith({
    Value<int>? releaseId,
    Value<String>? episodeId,
    Value<String>? releaseTitle,
    Value<String>? episodeTitle,
    Value<String?>? posterUrl,
    Value<int>? episodeOrdinal,
    Value<String>? localFilePath,
    Value<int>? fileSize,
    Value<int>? downloadedBytes,
    Value<String>? status,
    Value<int>? streamQuality,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DownloadedEpisodesCompanion(
      releaseId: releaseId ?? this.releaseId,
      episodeId: episodeId ?? this.episodeId,
      releaseTitle: releaseTitle ?? this.releaseTitle,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      episodeOrdinal: episodeOrdinal ?? this.episodeOrdinal,
      localFilePath: localFilePath ?? this.localFilePath,
      fileSize: fileSize ?? this.fileSize,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      streamQuality: streamQuality ?? this.streamQuality,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (releaseId.present) {
      map['release_id'] = Variable<int>(releaseId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (releaseTitle.present) {
      map['release_title'] = Variable<String>(releaseTitle.value);
    }
    if (episodeTitle.present) {
      map['episode_title'] = Variable<String>(episodeTitle.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (episodeOrdinal.present) {
      map['episode_ordinal'] = Variable<int>(episodeOrdinal.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (streamQuality.present) {
      map['stream_quality'] = Variable<int>(streamQuality.value);
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
    return (StringBuffer('DownloadedEpisodesCompanion(')
          ..write('releaseId: $releaseId, ')
          ..write('episodeId: $episodeId, ')
          ..write('releaseTitle: $releaseTitle, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('episodeOrdinal: $episodeOrdinal, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('status: $status, ')
          ..write('streamQuality: $streamQuality, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  late final $CacheEntriesTable cacheEntries = $CacheEntriesTable(this);
  late final $PlaybackPositionsTable playbackPositions =
      $PlaybackPositionsTable(this);
  late final $StreamSessionsTable streamSessions = $StreamSessionsTable(this);
  late final $WatchEntriesTable watchEntries = $WatchEntriesTable(this);
  late final $DownloadedEpisodesTable downloadedEpisodes =
      $DownloadedEpisodesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    settingsRows,
    cacheEntries,
    playbackPositions,
    streamSessions,
    watchEntries,
    downloadedEpisodes,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
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

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
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

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsRowsTable,
          SettingsRow,
          $$SettingsRowsTableFilterComposer,
          $$SettingsRowsTableOrderingComposer,
          $$SettingsRowsTableAnnotationComposer,
          $$SettingsRowsTableCreateCompanionBuilder,
          $$SettingsRowsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsRowsTableTableManager(_$AppDatabase db, $SettingsRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsRowsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsRowsTable,
      SettingsRow,
      $$SettingsRowsTableFilterComposer,
      $$SettingsRowsTableOrderingComposer,
      $$SettingsRowsTableAnnotationComposer,
      $$SettingsRowsTableCreateCompanionBuilder,
      $$SettingsRowsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$CacheEntriesTableCreateCompanionBuilder =
    CacheEntriesCompanion Function({
      required String key,
      required String valueJson,
      required DateTime updatedAt,
      Value<DateTime?> expiresAt,
      Value<String?> etag,
      Value<int> rowid,
    });
typedef $$CacheEntriesTableUpdateCompanionBuilder =
    CacheEntriesCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<DateTime> updatedAt,
      Value<DateTime?> expiresAt,
      Value<String?> etag,
      Value<int> rowid,
    });

class $$CacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
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

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
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

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$CacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheEntriesTable,
          CacheEntry,
          $$CacheEntriesTableFilterComposer,
          $$CacheEntriesTableOrderingComposer,
          $$CacheEntriesTableAnnotationComposer,
          $$CacheEntriesTableCreateCompanionBuilder,
          $$CacheEntriesTableUpdateCompanionBuilder,
          (
            CacheEntry,
            BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>,
          ),
          CacheEntry,
          PrefetchHooks Function()
        > {
  $$CacheEntriesTableTableManager(_$AppDatabase db, $CacheEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion(
                key: key,
                valueJson: valueJson,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                etag: etag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                required DateTime updatedAt,
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion.insert(
                key: key,
                valueJson: valueJson,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                etag: etag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheEntriesTable,
      CacheEntry,
      $$CacheEntriesTableFilterComposer,
      $$CacheEntriesTableOrderingComposer,
      $$CacheEntriesTableAnnotationComposer,
      $$CacheEntriesTableCreateCompanionBuilder,
      $$CacheEntriesTableUpdateCompanionBuilder,
      (
        CacheEntry,
        BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>,
      ),
      CacheEntry,
      PrefetchHooks Function()
    >;
typedef $$PlaybackPositionsTableCreateCompanionBuilder =
    PlaybackPositionsCompanion Function({
      required String releaseId,
      required String episodeId,
      Value<int> positionMs,
      Value<int?> durationMs,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlaybackPositionsTableUpdateCompanionBuilder =
    PlaybackPositionsCompanion Function({
      Value<String> releaseId,
      Value<String> episodeId,
      Value<int> positionMs,
      Value<int?> durationMs,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlaybackPositionsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get releaseId => $composableBuilder(
    column: $table.releaseId,
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaybackPositionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get releaseId => $composableBuilder(
    column: $table.releaseId,
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaybackPositionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get releaseId =>
      $composableBuilder(column: $table.releaseId, builder: (column) => column);

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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlaybackPositionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackPositionsTable,
          PlaybackPosition,
          $$PlaybackPositionsTableFilterComposer,
          $$PlaybackPositionsTableOrderingComposer,
          $$PlaybackPositionsTableAnnotationComposer,
          $$PlaybackPositionsTableCreateCompanionBuilder,
          $$PlaybackPositionsTableUpdateCompanionBuilder,
          (
            PlaybackPosition,
            BaseReferences<
              _$AppDatabase,
              $PlaybackPositionsTable,
              PlaybackPosition
            >,
          ),
          PlaybackPosition,
          PrefetchHooks Function()
        > {
  $$PlaybackPositionsTableTableManager(
    _$AppDatabase db,
    $PlaybackPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackPositionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> releaseId = const Value.absent(),
                Value<String> episodeId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackPositionsCompanion(
                releaseId: releaseId,
                episodeId: episodeId,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String releaseId,
                required String episodeId,
                Value<int> positionMs = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackPositionsCompanion.insert(
                releaseId: releaseId,
                episodeId: episodeId,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaybackPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackPositionsTable,
      PlaybackPosition,
      $$PlaybackPositionsTableFilterComposer,
      $$PlaybackPositionsTableOrderingComposer,
      $$PlaybackPositionsTableAnnotationComposer,
      $$PlaybackPositionsTableCreateCompanionBuilder,
      $$PlaybackPositionsTableUpdateCompanionBuilder,
      (
        PlaybackPosition,
        BaseReferences<
          _$AppDatabase,
          $PlaybackPositionsTable,
          PlaybackPosition
        >,
      ),
      PlaybackPosition,
      PrefetchHooks Function()
    >;
typedef $$StreamSessionsTableCreateCompanionBuilder =
    StreamSessionsCompanion Function({
      required String id,
      required String releaseId,
      required String episodeId,
      required String url,
      required String type,
      required int quality,
      Value<String> headersJson,
      required DateTime createdAt,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });
typedef $$StreamSessionsTableUpdateCompanionBuilder =
    StreamSessionsCompanion Function({
      Value<String> id,
      Value<String> releaseId,
      Value<String> episodeId,
      Value<String> url,
      Value<String> type,
      Value<int> quality,
      Value<String> headersJson,
      Value<DateTime> createdAt,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });

class $$StreamSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $StreamSessionsTable> {
  $$StreamSessionsTableFilterComposer({
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

  ColumnFilters<String> get releaseId => $composableBuilder(
    column: $table.releaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreamSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $StreamSessionsTable> {
  $$StreamSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get releaseId => $composableBuilder(
    column: $table.releaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreamSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreamSessionsTable> {
  $$StreamSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get releaseId =>
      $composableBuilder(column: $table.releaseId, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$StreamSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StreamSessionsTable,
          StreamSession,
          $$StreamSessionsTableFilterComposer,
          $$StreamSessionsTableOrderingComposer,
          $$StreamSessionsTableAnnotationComposer,
          $$StreamSessionsTableCreateCompanionBuilder,
          $$StreamSessionsTableUpdateCompanionBuilder,
          (
            StreamSession,
            BaseReferences<_$AppDatabase, $StreamSessionsTable, StreamSession>,
          ),
          StreamSession,
          PrefetchHooks Function()
        > {
  $$StreamSessionsTableTableManager(
    _$AppDatabase db,
    $StreamSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreamSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreamSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreamSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> releaseId = const Value.absent(),
                Value<String> episodeId = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> quality = const Value.absent(),
                Value<String> headersJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreamSessionsCompanion(
                id: id,
                releaseId: releaseId,
                episodeId: episodeId,
                url: url,
                type: type,
                quality: quality,
                headersJson: headersJson,
                createdAt: createdAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String releaseId,
                required String episodeId,
                required String url,
                required String type,
                required int quality,
                Value<String> headersJson = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreamSessionsCompanion.insert(
                id: id,
                releaseId: releaseId,
                episodeId: episodeId,
                url: url,
                type: type,
                quality: quality,
                headersJson: headersJson,
                createdAt: createdAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreamSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StreamSessionsTable,
      StreamSession,
      $$StreamSessionsTableFilterComposer,
      $$StreamSessionsTableOrderingComposer,
      $$StreamSessionsTableAnnotationComposer,
      $$StreamSessionsTableCreateCompanionBuilder,
      $$StreamSessionsTableUpdateCompanionBuilder,
      (
        StreamSession,
        BaseReferences<_$AppDatabase, $StreamSessionsTable, StreamSession>,
      ),
      StreamSession,
      PrefetchHooks Function()
    >;
typedef $$WatchEntriesTableCreateCompanionBuilder =
    WatchEntriesCompanion Function({
      required String releaseId,
      required String episodeId,
      required String releaseTitle,
      required String episodeTitle,
      Value<String?> posterUrl,
      required int episodeOrdinal,
      Value<int> positionMs,
      Value<int?> durationMs,
      Value<bool> isWatched,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WatchEntriesTableUpdateCompanionBuilder =
    WatchEntriesCompanion Function({
      Value<String> releaseId,
      Value<String> episodeId,
      Value<String> releaseTitle,
      Value<String> episodeTitle,
      Value<String?> posterUrl,
      Value<int> episodeOrdinal,
      Value<int> positionMs,
      Value<int?> durationMs,
      Value<bool> isWatched,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WatchEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WatchEntriesTable> {
  $$WatchEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get releaseId => $composableBuilder(
    column: $table.releaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseTitle => $composableBuilder(
    column: $table.releaseTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeOrdinal => $composableBuilder(
    column: $table.episodeOrdinal,
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

  ColumnFilters<bool> get isWatched => $composableBuilder(
    column: $table.isWatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchEntriesTable> {
  $$WatchEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get releaseId => $composableBuilder(
    column: $table.releaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseTitle => $composableBuilder(
    column: $table.releaseTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeOrdinal => $composableBuilder(
    column: $table.episodeOrdinal,
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

  ColumnOrderings<bool> get isWatched => $composableBuilder(
    column: $table.isWatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchEntriesTable> {
  $$WatchEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get releaseId =>
      $composableBuilder(column: $table.releaseId, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<String> get releaseTitle => $composableBuilder(
    column: $table.releaseTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<int> get episodeOrdinal => $composableBuilder(
    column: $table.episodeOrdinal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWatched =>
      $composableBuilder(column: $table.isWatched, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WatchEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchEntriesTable,
          WatchEntry,
          $$WatchEntriesTableFilterComposer,
          $$WatchEntriesTableOrderingComposer,
          $$WatchEntriesTableAnnotationComposer,
          $$WatchEntriesTableCreateCompanionBuilder,
          $$WatchEntriesTableUpdateCompanionBuilder,
          (
            WatchEntry,
            BaseReferences<_$AppDatabase, $WatchEntriesTable, WatchEntry>,
          ),
          WatchEntry,
          PrefetchHooks Function()
        > {
  $$WatchEntriesTableTableManager(_$AppDatabase db, $WatchEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> releaseId = const Value.absent(),
                Value<String> episodeId = const Value.absent(),
                Value<String> releaseTitle = const Value.absent(),
                Value<String> episodeTitle = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<int> episodeOrdinal = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> isWatched = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchEntriesCompanion(
                releaseId: releaseId,
                episodeId: episodeId,
                releaseTitle: releaseTitle,
                episodeTitle: episodeTitle,
                posterUrl: posterUrl,
                episodeOrdinal: episodeOrdinal,
                positionMs: positionMs,
                durationMs: durationMs,
                isWatched: isWatched,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String releaseId,
                required String episodeId,
                required String releaseTitle,
                required String episodeTitle,
                Value<String?> posterUrl = const Value.absent(),
                required int episodeOrdinal,
                Value<int> positionMs = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> isWatched = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WatchEntriesCompanion.insert(
                releaseId: releaseId,
                episodeId: episodeId,
                releaseTitle: releaseTitle,
                episodeTitle: episodeTitle,
                posterUrl: posterUrl,
                episodeOrdinal: episodeOrdinal,
                positionMs: positionMs,
                durationMs: durationMs,
                isWatched: isWatched,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchEntriesTable,
      WatchEntry,
      $$WatchEntriesTableFilterComposer,
      $$WatchEntriesTableOrderingComposer,
      $$WatchEntriesTableAnnotationComposer,
      $$WatchEntriesTableCreateCompanionBuilder,
      $$WatchEntriesTableUpdateCompanionBuilder,
      (
        WatchEntry,
        BaseReferences<_$AppDatabase, $WatchEntriesTable, WatchEntry>,
      ),
      WatchEntry,
      PrefetchHooks Function()
    >;
typedef $$DownloadedEpisodesTableCreateCompanionBuilder =
    DownloadedEpisodesCompanion Function({
      required int releaseId,
      required String episodeId,
      required String releaseTitle,
      required String episodeTitle,
      Value<String?> posterUrl,
      required int episodeOrdinal,
      required String localFilePath,
      required int fileSize,
      required int downloadedBytes,
      required String status,
      required int streamQuality,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DownloadedEpisodesTableUpdateCompanionBuilder =
    DownloadedEpisodesCompanion Function({
      Value<int> releaseId,
      Value<String> episodeId,
      Value<String> releaseTitle,
      Value<String> episodeTitle,
      Value<String?> posterUrl,
      Value<int> episodeOrdinal,
      Value<String> localFilePath,
      Value<int> fileSize,
      Value<int> downloadedBytes,
      Value<String> status,
      Value<int> streamQuality,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DownloadedEpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadedEpisodesTable> {
  $$DownloadedEpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get releaseId => $composableBuilder(
    column: $table.releaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseTitle => $composableBuilder(
    column: $table.releaseTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeOrdinal => $composableBuilder(
    column: $table.episodeOrdinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streamQuality => $composableBuilder(
    column: $table.streamQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedEpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadedEpisodesTable> {
  $$DownloadedEpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get releaseId => $composableBuilder(
    column: $table.releaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseTitle => $composableBuilder(
    column: $table.releaseTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeOrdinal => $composableBuilder(
    column: $table.episodeOrdinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streamQuality => $composableBuilder(
    column: $table.streamQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedEpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadedEpisodesTable> {
  $$DownloadedEpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get releaseId =>
      $composableBuilder(column: $table.releaseId, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<String> get releaseTitle => $composableBuilder(
    column: $table.releaseTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<int> get episodeOrdinal => $composableBuilder(
    column: $table.episodeOrdinal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get streamQuality => $composableBuilder(
    column: $table.streamQuality,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DownloadedEpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadedEpisodesTable,
          DownloadedEpisode,
          $$DownloadedEpisodesTableFilterComposer,
          $$DownloadedEpisodesTableOrderingComposer,
          $$DownloadedEpisodesTableAnnotationComposer,
          $$DownloadedEpisodesTableCreateCompanionBuilder,
          $$DownloadedEpisodesTableUpdateCompanionBuilder,
          (
            DownloadedEpisode,
            BaseReferences<
              _$AppDatabase,
              $DownloadedEpisodesTable,
              DownloadedEpisode
            >,
          ),
          DownloadedEpisode,
          PrefetchHooks Function()
        > {
  $$DownloadedEpisodesTableTableManager(
    _$AppDatabase db,
    $DownloadedEpisodesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedEpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedEpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedEpisodesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> releaseId = const Value.absent(),
                Value<String> episodeId = const Value.absent(),
                Value<String> releaseTitle = const Value.absent(),
                Value<String> episodeTitle = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<int> episodeOrdinal = const Value.absent(),
                Value<String> localFilePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> streamQuality = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedEpisodesCompanion(
                releaseId: releaseId,
                episodeId: episodeId,
                releaseTitle: releaseTitle,
                episodeTitle: episodeTitle,
                posterUrl: posterUrl,
                episodeOrdinal: episodeOrdinal,
                localFilePath: localFilePath,
                fileSize: fileSize,
                downloadedBytes: downloadedBytes,
                status: status,
                streamQuality: streamQuality,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int releaseId,
                required String episodeId,
                required String releaseTitle,
                required String episodeTitle,
                Value<String?> posterUrl = const Value.absent(),
                required int episodeOrdinal,
                required String localFilePath,
                required int fileSize,
                required int downloadedBytes,
                required String status,
                required int streamQuality,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadedEpisodesCompanion.insert(
                releaseId: releaseId,
                episodeId: episodeId,
                releaseTitle: releaseTitle,
                episodeTitle: episodeTitle,
                posterUrl: posterUrl,
                episodeOrdinal: episodeOrdinal,
                localFilePath: localFilePath,
                fileSize: fileSize,
                downloadedBytes: downloadedBytes,
                status: status,
                streamQuality: streamQuality,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedEpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadedEpisodesTable,
      DownloadedEpisode,
      $$DownloadedEpisodesTableFilterComposer,
      $$DownloadedEpisodesTableOrderingComposer,
      $$DownloadedEpisodesTableAnnotationComposer,
      $$DownloadedEpisodesTableCreateCompanionBuilder,
      $$DownloadedEpisodesTableUpdateCompanionBuilder,
      (
        DownloadedEpisode,
        BaseReferences<
          _$AppDatabase,
          $DownloadedEpisodesTable,
          DownloadedEpisode
        >,
      ),
      DownloadedEpisode,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db, _db.cacheEntries);
  $$PlaybackPositionsTableTableManager get playbackPositions =>
      $$PlaybackPositionsTableTableManager(_db, _db.playbackPositions);
  $$StreamSessionsTableTableManager get streamSessions =>
      $$StreamSessionsTableTableManager(_db, _db.streamSessions);
  $$WatchEntriesTableTableManager get watchEntries =>
      $$WatchEntriesTableTableManager(_db, _db.watchEntries);
  $$DownloadedEpisodesTableTableManager get downloadedEpisodes =>
      $$DownloadedEpisodesTableTableManager(_db, _db.downloadedEpisodes);
}
