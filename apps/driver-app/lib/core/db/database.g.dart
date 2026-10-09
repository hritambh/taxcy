// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedTripsTable extends CachedTrips
    with TableInfo<$CachedTripsTable, CachedTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _scheduledStartAtMeta = const VerificationMeta(
    'scheduledStartAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledStartAt =
      GeneratedColumn<DateTime>(
        'scheduled_start_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _conflictMeta = const VerificationMeta(
    'conflict',
  );
  @override
  late final GeneratedColumn<String> conflict = GeneratedColumn<String>(
    'conflict',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    json,
    status,
    scheduledStartAt,
    conflict,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('scheduled_start_at')) {
      context.handle(
        _scheduledStartAtMeta,
        scheduledStartAt.isAcceptableOrUnknown(
          data['scheduled_start_at']!,
          _scheduledStartAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledStartAtMeta);
    }
    if (data.containsKey('conflict')) {
      context.handle(
        _conflictMeta,
        conflict.isAcceptableOrUnknown(data['conflict']!, _conflictMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTrip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      scheduledStartAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_start_at'],
      )!,
      conflict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $CachedTripsTable createAlias(String alias) {
    return $CachedTripsTable(attachedDatabase, alias);
  }
}

class CachedTrip extends DataClass implements Insertable<CachedTrip> {
  final String id;
  final String json;
  final String status;
  final DateTime scheduledStartAt;

  /// Set when the server rejected a queued command for this trip (cancelled or
  /// reassigned while the phone was offline). Shown as a notice on the trip.
  final String? conflict;
  final DateTime syncedAt;
  const CachedTrip({
    required this.id,
    required this.json,
    required this.status,
    required this.scheduledStartAt,
    this.conflict,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['status'] = Variable<String>(status);
    map['scheduled_start_at'] = Variable<DateTime>(scheduledStartAt);
    if (!nullToAbsent || conflict != null) {
      map['conflict'] = Variable<String>(conflict);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  CachedTripsCompanion toCompanion(bool nullToAbsent) {
    return CachedTripsCompanion(
      id: Value(id),
      json: Value(json),
      status: Value(status),
      scheduledStartAt: Value(scheduledStartAt),
      conflict: conflict == null && nullToAbsent
          ? const Value.absent()
          : Value(conflict),
      syncedAt: Value(syncedAt),
    );
  }

  factory CachedTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTrip(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      status: serializer.fromJson<String>(json['status']),
      scheduledStartAt: serializer.fromJson<DateTime>(json['scheduledStartAt']),
      conflict: serializer.fromJson<String?>(json['conflict']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'status': serializer.toJson<String>(status),
      'scheduledStartAt': serializer.toJson<DateTime>(scheduledStartAt),
      'conflict': serializer.toJson<String?>(conflict),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  CachedTrip copyWith({
    String? id,
    String? json,
    String? status,
    DateTime? scheduledStartAt,
    Value<String?> conflict = const Value.absent(),
    DateTime? syncedAt,
  }) => CachedTrip(
    id: id ?? this.id,
    json: json ?? this.json,
    status: status ?? this.status,
    scheduledStartAt: scheduledStartAt ?? this.scheduledStartAt,
    conflict: conflict.present ? conflict.value : this.conflict,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  CachedTrip copyWithCompanion(CachedTripsCompanion data) {
    return CachedTrip(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      status: data.status.present ? data.status.value : this.status,
      scheduledStartAt: data.scheduledStartAt.present
          ? data.scheduledStartAt.value
          : this.scheduledStartAt,
      conflict: data.conflict.present ? data.conflict.value : this.conflict,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTrip(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('status: $status, ')
          ..write('scheduledStartAt: $scheduledStartAt, ')
          ..write('conflict: $conflict, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, json, status, scheduledStartAt, conflict, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTrip &&
          other.id == this.id &&
          other.json == this.json &&
          other.status == this.status &&
          other.scheduledStartAt == this.scheduledStartAt &&
          other.conflict == this.conflict &&
          other.syncedAt == this.syncedAt);
}

class CachedTripsCompanion extends UpdateCompanion<CachedTrip> {
  final Value<String> id;
  final Value<String> json;
  final Value<String> status;
  final Value<DateTime> scheduledStartAt;
  final Value<String?> conflict;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const CachedTripsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.status = const Value.absent(),
    this.scheduledStartAt = const Value.absent(),
    this.conflict = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedTripsCompanion.insert({
    required String id,
    required String json,
    required String status,
    required DateTime scheduledStartAt,
    this.conflict = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       status = Value(status),
       scheduledStartAt = Value(scheduledStartAt),
       syncedAt = Value(syncedAt);
  static Insertable<CachedTrip> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<String>? status,
    Expression<DateTime>? scheduledStartAt,
    Expression<String>? conflict,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (status != null) 'status': status,
      if (scheduledStartAt != null) 'scheduled_start_at': scheduledStartAt,
      if (conflict != null) 'conflict': conflict,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedTripsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<String>? status,
    Value<DateTime>? scheduledStartAt,
    Value<String?>? conflict,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return CachedTripsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      status: status ?? this.status,
      scheduledStartAt: scheduledStartAt ?? this.scheduledStartAt,
      conflict: conflict ?? this.conflict,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (scheduledStartAt.present) {
      map['scheduled_start_at'] = Variable<DateTime>(scheduledStartAt.value);
    }
    if (conflict.present) {
      map['conflict'] = Variable<String>(conflict.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTripsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('status: $status, ')
          ..write('scheduledStartAt: $scheduledStartAt, ')
          ..write('conflict: $conflict, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedVehiclesTable extends CachedVehicles
    with TableInfo<$CachedVehiclesTable, CachedVehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedVehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedVehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedVehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedVehicle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $CachedVehiclesTable createAlias(String alias) {
    return $CachedVehiclesTable(attachedDatabase, alias);
  }
}

class CachedVehicle extends DataClass implements Insertable<CachedVehicle> {
  final String id;
  final String json;
  const CachedVehicle({required this.id, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    return map;
  }

  CachedVehiclesCompanion toCompanion(bool nullToAbsent) {
    return CachedVehiclesCompanion(id: Value(id), json: Value(json));
  }

  factory CachedVehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedVehicle(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
    };
  }

  CachedVehicle copyWith({String? id, String? json}) =>
      CachedVehicle(id: id ?? this.id, json: json ?? this.json);
  CachedVehicle copyWithCompanion(CachedVehiclesCompanion data) {
    return CachedVehicle(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedVehicle(')
          ..write('id: $id, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedVehicle &&
          other.id == this.id &&
          other.json == this.json);
}

class CachedVehiclesCompanion extends UpdateCompanion<CachedVehicle> {
  final Value<String> id;
  final Value<String> json;
  final Value<int> rowid;
  const CachedVehiclesCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedVehiclesCompanion.insert({
    required String id,
    required String json,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json);
  static Insertable<CachedVehicle> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedVehiclesCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return CachedVehiclesCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedVehiclesCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxItemsTable extends OutboxItems
    with TableInfo<$OutboxItemsTable, OutboxItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    key,
    kind,
    payload,
    tripId,
    state,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxItem(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxItemsTable createAlias(String alias) {
    return $OutboxItemsTable(attachedDatabase, alias);
  }
}

class OutboxItem extends DataClass implements Insertable<OutboxItem> {
  final int seq;

  /// Stable client UUID for this write. Used as the Idempotency-Key for commands,
  /// so every retry of the same write is recognised by the server.
  final String key;
  final String kind;
  final String payload;
  final String? tripId;

  /// pending (to send), attention (rejected; needs the driver), done.
  final String state;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  const OutboxItem({
    required this.seq,
    required this.key,
    required this.kind,
    required this.payload,
    this.tripId,
    required this.state,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['key'] = Variable<String>(key);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxItemsCompanion toCompanion(bool nullToAbsent) {
    return OutboxItemsCompanion(
      seq: Value(seq),
      key: Value(key),
      kind: Value(kind),
      payload: Value(payload),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      state: Value(state),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxItem(
      seq: serializer.fromJson<int>(json['seq']),
      key: serializer.fromJson<String>(json['key']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'key': serializer.toJson<String>(key),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'tripId': serializer.toJson<String?>(tripId),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxItem copyWith({
    int? seq,
    String? key,
    String? kind,
    String? payload,
    Value<String?> tripId = const Value.absent(),
    String? state,
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxItem(
    seq: seq ?? this.seq,
    key: key ?? this.key,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    tripId: tripId.present ? tripId.value : this.tripId,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxItem copyWithCompanion(OutboxItemsCompanion data) {
    return OutboxItem(
      seq: data.seq.present ? data.seq.value : this.seq,
      key: data.key.present ? data.key.value : this.key,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxItem(')
          ..write('seq: $seq, ')
          ..write('key: $key, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('tripId: $tripId, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    key,
    kind,
    payload,
    tripId,
    state,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxItem &&
          other.seq == this.seq &&
          other.key == this.key &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.tripId == this.tripId &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class OutboxItemsCompanion extends UpdateCompanion<OutboxItem> {
  final Value<int> seq;
  final Value<String> key;
  final Value<String> kind;
  final Value<String> payload;
  final Value<String?> tripId;
  final Value<String> state;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const OutboxItemsCompanion({
    this.seq = const Value.absent(),
    this.key = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.tripId = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxItemsCompanion.insert({
    this.seq = const Value.absent(),
    required String key,
    required String kind,
    required String payload,
    this.tripId = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
  }) : key = Value(key),
       kind = Value(kind),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxItem> custom({
    Expression<int>? seq,
    Expression<String>? key,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<String>? tripId,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (key != null) 'key': key,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (tripId != null) 'trip_id': tripId,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxItemsCompanion copyWith({
    Value<int>? seq,
    Value<String>? key,
    Value<String>? kind,
    Value<String>? payload,
    Value<String?>? tripId,
    Value<String>? state,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return OutboxItemsCompanion(
      seq: seq ?? this.seq,
      key: key ?? this.key,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      tripId: tripId ?? this.tripId,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxItemsCompanion(')
          ..write('seq: $seq, ')
          ..write('key: $key, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('tripId: $tripId, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMockMeta = const VerificationMeta('isMock');
  @override
  late final GeneratedColumn<bool> isMock = GeneratedColumn<bool>(
    'is_mock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _uploadedMeta = const VerificationMeta(
    'uploaded',
  );
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
    'uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    path,
    sha256,
    byteSize,
    contentType,
    capturedAt,
    lat,
    lng,
    accuracyM,
    isMock,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('is_mock')) {
      context.handle(
        _isMockMeta,
        isMock.isAcceptableOrUnknown(data['is_mock']!, _isMockMeta),
      );
    }
    if (data.containsKey('uploaded')) {
      context.handle(
        _uploadedMeta,
        uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      isMock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mock'],
      )!,
      uploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded'],
      )!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class Photo extends DataClass implements Insertable<Photo> {
  final String id;
  final String kind;
  final String path;
  final String sha256;
  final int byteSize;
  final String contentType;
  final DateTime capturedAt;
  final double? lat;
  final double? lng;
  final double? accuracyM;
  final bool isMock;
  final bool uploaded;
  const Photo({
    required this.id,
    required this.kind,
    required this.path,
    required this.sha256,
    required this.byteSize,
    required this.contentType,
    required this.capturedAt,
    this.lat,
    this.lng,
    this.accuracyM,
    required this.isMock,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['path'] = Variable<String>(path);
    map['sha256'] = Variable<String>(sha256);
    map['byte_size'] = Variable<int>(byteSize);
    map['content_type'] = Variable<String>(contentType);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    map['is_mock'] = Variable<bool>(isMock);
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      kind: Value(kind),
      path: Value(path),
      sha256: Value(sha256),
      byteSize: Value(byteSize),
      contentType: Value(contentType),
      capturedAt: Value(capturedAt),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      isMock: Value(isMock),
      uploaded: Value(uploaded),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      path: serializer.fromJson<String>(json['path']),
      sha256: serializer.fromJson<String>(json['sha256']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      contentType: serializer.fromJson<String>(json['contentType']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      isMock: serializer.fromJson<bool>(json['isMock']),
      uploaded: serializer.fromJson<bool>(json['uploaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'path': serializer.toJson<String>(path),
      'sha256': serializer.toJson<String>(sha256),
      'byteSize': serializer.toJson<int>(byteSize),
      'contentType': serializer.toJson<String>(contentType),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'isMock': serializer.toJson<bool>(isMock),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  Photo copyWith({
    String? id,
    String? kind,
    String? path,
    String? sha256,
    int? byteSize,
    String? contentType,
    DateTime? capturedAt,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<double?> accuracyM = const Value.absent(),
    bool? isMock,
    bool? uploaded,
  }) => Photo(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    path: path ?? this.path,
    sha256: sha256 ?? this.sha256,
    byteSize: byteSize ?? this.byteSize,
    contentType: contentType ?? this.contentType,
    capturedAt: capturedAt ?? this.capturedAt,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    isMock: isMock ?? this.isMock,
    uploaded: uploaded ?? this.uploaded,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      path: data.path.present ? data.path.value : this.path,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      isMock: data.isMock.present ? data.isMock.value : this.isMock,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('sha256: $sha256, ')
          ..write('byteSize: $byteSize, ')
          ..write('contentType: $contentType, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('isMock: $isMock, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    path,
    sha256,
    byteSize,
    contentType,
    capturedAt,
    lat,
    lng,
    accuracyM,
    isMock,
    uploaded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.path == this.path &&
          other.sha256 == this.sha256 &&
          other.byteSize == this.byteSize &&
          other.contentType == this.contentType &&
          other.capturedAt == this.capturedAt &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.accuracyM == this.accuracyM &&
          other.isMock == this.isMock &&
          other.uploaded == this.uploaded);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> path;
  final Value<String> sha256;
  final Value<int> byteSize;
  final Value<String> contentType;
  final Value<DateTime> capturedAt;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<double?> accuracyM;
  final Value<bool> isMock;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.path = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.contentType = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.isMock = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotosCompanion.insert({
    required String id,
    required String kind,
    required String path,
    required String sha256,
    required int byteSize,
    required String contentType,
    required DateTime capturedAt,
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.isMock = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       path = Value(path),
       sha256 = Value(sha256),
       byteSize = Value(byteSize),
       contentType = Value(contentType),
       capturedAt = Value(capturedAt);
  static Insertable<Photo> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? path,
    Expression<String>? sha256,
    Expression<int>? byteSize,
    Expression<String>? contentType,
    Expression<DateTime>? capturedAt,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? accuracyM,
    Expression<bool>? isMock,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (path != null) 'path': path,
      if (sha256 != null) 'sha256': sha256,
      if (byteSize != null) 'byte_size': byteSize,
      if (contentType != null) 'content_type': contentType,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (isMock != null) 'is_mock': isMock,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? path,
    Value<String>? sha256,
    Value<int>? byteSize,
    Value<String>? contentType,
    Value<DateTime>? capturedAt,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<double?>? accuracyM,
    Value<bool>? isMock,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      path: path ?? this.path,
      sha256: sha256 ?? this.sha256,
      byteSize: byteSize ?? this.byteSize,
      contentType: contentType ?? this.contentType,
      capturedAt: capturedAt ?? this.capturedAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracyM: accuracyM ?? this.accuracyM,
      isMock: isMock ?? this.isMock,
      uploaded: uploaded ?? this.uploaded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (isMock.present) {
      map['is_mock'] = Variable<bool>(isMock.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('sha256: $sha256, ')
          ..write('byteSize: $byteSize, ')
          ..write('contentType: $contentType, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('isMock: $isMock, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GpsPointsTable extends GpsPoints
    with TableInfo<$GpsPointsTable, GpsPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GpsPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMockMeta = const VerificationMeta('isMock');
  @override
  late final GeneratedColumn<bool> isMock = GeneratedColumn<bool>(
    'is_mock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _uploadedMeta = const VerificationMeta(
    'uploaded',
  );
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
    'uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    recordedAt,
    lat,
    lng,
    accuracyM,
    speedMps,
    heading,
    isMock,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gps_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<GpsPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    }
    if (data.containsKey('is_mock')) {
      context.handle(
        _isMockMeta,
        isMock.isAcceptableOrUnknown(data['is_mock']!, _isMockMeta),
      );
    }
    if (data.containsKey('uploaded')) {
      context.handle(
        _uploadedMeta,
        uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GpsPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GpsPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      ),
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      ),
      isMock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mock'],
      )!,
      uploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded'],
      )!,
    );
  }

  @override
  $GpsPointsTable createAlias(String alias) {
    return $GpsPointsTable(attachedDatabase, alias);
  }
}

class GpsPoint extends DataClass implements Insertable<GpsPoint> {
  final String id;
  final String tripId;
  final DateTime recordedAt;
  final double lat;
  final double lng;
  final double? accuracyM;
  final double? speedMps;
  final double? heading;
  final bool isMock;
  final bool uploaded;
  const GpsPoint({
    required this.id,
    required this.tripId,
    required this.recordedAt,
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.speedMps,
    this.heading,
    required this.isMock,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    map['is_mock'] = Variable<bool>(isMock);
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  GpsPointsCompanion toCompanion(bool nullToAbsent) {
    return GpsPointsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      recordedAt: Value(recordedAt),
      lat: Value(lat),
      lng: Value(lng),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      isMock: Value(isMock),
      uploaded: Value(uploaded),
    );
  }

  factory GpsPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GpsPoint(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
      heading: serializer.fromJson<double?>(json['heading']),
      isMock: serializer.fromJson<bool>(json['isMock']),
      uploaded: serializer.fromJson<bool>(json['uploaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'speedMps': serializer.toJson<double?>(speedMps),
      'heading': serializer.toJson<double?>(heading),
      'isMock': serializer.toJson<bool>(isMock),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  GpsPoint copyWith({
    String? id,
    String? tripId,
    DateTime? recordedAt,
    double? lat,
    double? lng,
    Value<double?> accuracyM = const Value.absent(),
    Value<double?> speedMps = const Value.absent(),
    Value<double?> heading = const Value.absent(),
    bool? isMock,
    bool? uploaded,
  }) => GpsPoint(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    recordedAt: recordedAt ?? this.recordedAt,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    speedMps: speedMps.present ? speedMps.value : this.speedMps,
    heading: heading.present ? heading.value : this.heading,
    isMock: isMock ?? this.isMock,
    uploaded: uploaded ?? this.uploaded,
  );
  GpsPoint copyWithCompanion(GpsPointsCompanion data) {
    return GpsPoint(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      heading: data.heading.present ? data.heading.value : this.heading,
      isMock: data.isMock.present ? data.isMock.value : this.isMock,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GpsPoint(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedMps: $speedMps, ')
          ..write('heading: $heading, ')
          ..write('isMock: $isMock, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    recordedAt,
    lat,
    lng,
    accuracyM,
    speedMps,
    heading,
    isMock,
    uploaded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GpsPoint &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.recordedAt == this.recordedAt &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.accuracyM == this.accuracyM &&
          other.speedMps == this.speedMps &&
          other.heading == this.heading &&
          other.isMock == this.isMock &&
          other.uploaded == this.uploaded);
}

class GpsPointsCompanion extends UpdateCompanion<GpsPoint> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<DateTime> recordedAt;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double?> accuracyM;
  final Value<double?> speedMps;
  final Value<double?> heading;
  final Value<bool> isMock;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const GpsPointsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.heading = const Value.absent(),
    this.isMock = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GpsPointsCompanion.insert({
    required String id,
    required String tripId,
    required DateTime recordedAt,
    required double lat,
    required double lng,
    this.accuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.heading = const Value.absent(),
    this.isMock = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       recordedAt = Value(recordedAt),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<GpsPoint> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<DateTime>? recordedAt,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? accuracyM,
    Expression<double>? speedMps,
    Expression<double>? heading,
    Expression<bool>? isMock,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (heading != null) 'heading': heading,
      if (isMock != null) 'is_mock': isMock,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GpsPointsCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<DateTime>? recordedAt,
    Value<double>? lat,
    Value<double>? lng,
    Value<double?>? accuracyM,
    Value<double?>? speedMps,
    Value<double?>? heading,
    Value<bool>? isMock,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return GpsPointsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      recordedAt: recordedAt ?? this.recordedAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracyM: accuracyM ?? this.accuracyM,
      speedMps: speedMps ?? this.speedMps,
      heading: heading ?? this.heading,
      isMock: isMock ?? this.isMock,
      uploaded: uploaded ?? this.uploaded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (isMock.present) {
      map['is_mock'] = Variable<bool>(isMock.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GpsPointsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedMps: $speedMps, ')
          ..write('heading: $heading, ')
          ..write('isMock: $isMock, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedTripsTable cachedTrips = $CachedTripsTable(this);
  late final $CachedVehiclesTable cachedVehicles = $CachedVehiclesTable(this);
  late final $OutboxItemsTable outboxItems = $OutboxItemsTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $GpsPointsTable gpsPoints = $GpsPointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedTrips,
    cachedVehicles,
    outboxItems,
    photos,
    gpsPoints,
  ];
}

typedef $$CachedTripsTableCreateCompanionBuilder =
    CachedTripsCompanion Function({
      required String id,
      required String json,
      required String status,
      required DateTime scheduledStartAt,
      Value<String?> conflict,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$CachedTripsTableUpdateCompanionBuilder =
    CachedTripsCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<String> status,
      Value<DateTime> scheduledStartAt,
      Value<String?> conflict,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$CachedTripsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTripsTable> {
  $$CachedTripsTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledStartAt => $composableBuilder(
    column: $table.scheduledStartAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflict => $composableBuilder(
    column: $table.conflict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedTripsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTripsTable> {
  $$CachedTripsTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledStartAt => $composableBuilder(
    column: $table.scheduledStartAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflict => $composableBuilder(
    column: $table.conflict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedTripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTripsTable> {
  $$CachedTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledStartAt => $composableBuilder(
    column: $table.scheduledStartAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conflict =>
      $composableBuilder(column: $table.conflict, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CachedTripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTripsTable,
          CachedTrip,
          $$CachedTripsTableFilterComposer,
          $$CachedTripsTableOrderingComposer,
          $$CachedTripsTableAnnotationComposer,
          $$CachedTripsTableCreateCompanionBuilder,
          $$CachedTripsTableUpdateCompanionBuilder,
          (
            CachedTrip,
            BaseReferences<_$AppDatabase, $CachedTripsTable, CachedTrip>,
          ),
          CachedTrip,
          PrefetchHooks Function()
        > {
  $$CachedTripsTableTableManager(_$AppDatabase db, $CachedTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> scheduledStartAt = const Value.absent(),
                Value<String?> conflict = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedTripsCompanion(
                id: id,
                json: json,
                status: status,
                scheduledStartAt: scheduledStartAt,
                conflict: conflict,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required String status,
                required DateTime scheduledStartAt,
                Value<String?> conflict = const Value.absent(),
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedTripsCompanion.insert(
                id: id,
                json: json,
                status: status,
                scheduledStartAt: scheduledStartAt,
                conflict: conflict,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTripsTable,
      CachedTrip,
      $$CachedTripsTableFilterComposer,
      $$CachedTripsTableOrderingComposer,
      $$CachedTripsTableAnnotationComposer,
      $$CachedTripsTableCreateCompanionBuilder,
      $$CachedTripsTableUpdateCompanionBuilder,
      (
        CachedTrip,
        BaseReferences<_$AppDatabase, $CachedTripsTable, CachedTrip>,
      ),
      CachedTrip,
      PrefetchHooks Function()
    >;
typedef $$CachedVehiclesTableCreateCompanionBuilder =
    CachedVehiclesCompanion Function({
      required String id,
      required String json,
      Value<int> rowid,
    });
typedef $$CachedVehiclesTableUpdateCompanionBuilder =
    CachedVehiclesCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<int> rowid,
    });

class $$CachedVehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedVehiclesTable> {
  $$CachedVehiclesTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedVehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedVehiclesTable> {
  $$CachedVehiclesTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedVehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedVehiclesTable> {
  $$CachedVehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$CachedVehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedVehiclesTable,
          CachedVehicle,
          $$CachedVehiclesTableFilterComposer,
          $$CachedVehiclesTableOrderingComposer,
          $$CachedVehiclesTableAnnotationComposer,
          $$CachedVehiclesTableCreateCompanionBuilder,
          $$CachedVehiclesTableUpdateCompanionBuilder,
          (
            CachedVehicle,
            BaseReferences<_$AppDatabase, $CachedVehiclesTable, CachedVehicle>,
          ),
          CachedVehicle,
          PrefetchHooks Function()
        > {
  $$CachedVehiclesTableTableManager(
    _$AppDatabase db,
    $CachedVehiclesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedVehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedVehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedVehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedVehiclesCompanion(id: id, json: json, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => CachedVehiclesCompanion.insert(
                id: id,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedVehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedVehiclesTable,
      CachedVehicle,
      $$CachedVehiclesTableFilterComposer,
      $$CachedVehiclesTableOrderingComposer,
      $$CachedVehiclesTableAnnotationComposer,
      $$CachedVehiclesTableCreateCompanionBuilder,
      $$CachedVehiclesTableUpdateCompanionBuilder,
      (
        CachedVehicle,
        BaseReferences<_$AppDatabase, $CachedVehiclesTable, CachedVehicle>,
      ),
      CachedVehicle,
      PrefetchHooks Function()
    >;
typedef $$OutboxItemsTableCreateCompanionBuilder =
    OutboxItemsCompanion Function({
      Value<int> seq,
      required String key,
      required String kind,
      required String payload,
      Value<String?> tripId,
      Value<String> state,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      required DateTime createdAt,
    });
typedef $$OutboxItemsTableUpdateCompanionBuilder =
    OutboxItemsCompanion Function({
      Value<int> seq,
      Value<String> key,
      Value<String> kind,
      Value<String> payload,
      Value<String?> tripId,
      Value<String> state,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$OutboxItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxItemsTable> {
  $$OutboxItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxItemsTable> {
  $$OutboxItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxItemsTable> {
  $$OutboxItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxItemsTable,
          OutboxItem,
          $$OutboxItemsTableFilterComposer,
          $$OutboxItemsTableOrderingComposer,
          $$OutboxItemsTableAnnotationComposer,
          $$OutboxItemsTableCreateCompanionBuilder,
          $$OutboxItemsTableUpdateCompanionBuilder,
          (
            OutboxItem,
            BaseReferences<_$AppDatabase, $OutboxItemsTable, OutboxItem>,
          ),
          OutboxItem,
          PrefetchHooks Function()
        > {
  $$OutboxItemsTableTableManager(_$AppDatabase db, $OutboxItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxItemsCompanion(
                seq: seq,
                key: key,
                kind: kind,
                payload: payload,
                tripId: tripId,
                state: state,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String key,
                required String kind,
                required String payload,
                Value<String?> tripId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxItemsCompanion.insert(
                seq: seq,
                key: key,
                kind: kind,
                payload: payload,
                tripId: tripId,
                state: state,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxItemsTable,
      OutboxItem,
      $$OutboxItemsTableFilterComposer,
      $$OutboxItemsTableOrderingComposer,
      $$OutboxItemsTableAnnotationComposer,
      $$OutboxItemsTableCreateCompanionBuilder,
      $$OutboxItemsTableUpdateCompanionBuilder,
      (
        OutboxItem,
        BaseReferences<_$AppDatabase, $OutboxItemsTable, OutboxItem>,
      ),
      OutboxItem,
      PrefetchHooks Function()
    >;
typedef $$PhotosTableCreateCompanionBuilder =
    PhotosCompanion Function({
      required String id,
      required String kind,
      required String path,
      required String sha256,
      required int byteSize,
      required String contentType,
      required DateTime capturedAt,
      Value<double?> lat,
      Value<double?> lng,
      Value<double?> accuracyM,
      Value<bool> isMock,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$PhotosTableUpdateCompanionBuilder =
    PhotosCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> path,
      Value<String> sha256,
      Value<int> byteSize,
      Value<String> contentType,
      Value<DateTime> capturedAt,
      Value<double?> lat,
      Value<double?> lng,
      Value<double?> accuracyM,
      Value<bool> isMock,
      Value<bool> uploaded,
      Value<int> rowid,
    });

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMock => $composableBuilder(
    column: $table.isMock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMock => $composableBuilder(
    column: $table.isMock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<bool> get isMock =>
      $composableBuilder(column: $table.isMock, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          Photo,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (Photo, BaseReferences<_$AppDatabase, $PhotosTable, Photo>),
          Photo,
          PrefetchHooks Function()
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<bool> isMock = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                kind: kind,
                path: path,
                sha256: sha256,
                byteSize: byteSize,
                contentType: contentType,
                capturedAt: capturedAt,
                lat: lat,
                lng: lng,
                accuracyM: accuracyM,
                isMock: isMock,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String path,
                required String sha256,
                required int byteSize,
                required String contentType,
                required DateTime capturedAt,
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<bool> isMock = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                kind: kind,
                path: path,
                sha256: sha256,
                byteSize: byteSize,
                contentType: contentType,
                capturedAt: capturedAt,
                lat: lat,
                lng: lng,
                accuracyM: accuracyM,
                isMock: isMock,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      Photo,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (Photo, BaseReferences<_$AppDatabase, $PhotosTable, Photo>),
      Photo,
      PrefetchHooks Function()
    >;
typedef $$GpsPointsTableCreateCompanionBuilder =
    GpsPointsCompanion Function({
      required String id,
      required String tripId,
      required DateTime recordedAt,
      required double lat,
      required double lng,
      Value<double?> accuracyM,
      Value<double?> speedMps,
      Value<double?> heading,
      Value<bool> isMock,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$GpsPointsTableUpdateCompanionBuilder =
    GpsPointsCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<DateTime> recordedAt,
      Value<double> lat,
      Value<double> lng,
      Value<double?> accuracyM,
      Value<double?> speedMps,
      Value<double?> heading,
      Value<bool> isMock,
      Value<bool> uploaded,
      Value<int> rowid,
    });

class $$GpsPointsTableFilterComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableFilterComposer({
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

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMock => $composableBuilder(
    column: $table.isMock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GpsPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableOrderingComposer({
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

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMock => $composableBuilder(
    column: $table.isMock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GpsPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<bool> get isMock =>
      $composableBuilder(column: $table.isMock, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);
}

class $$GpsPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GpsPointsTable,
          GpsPoint,
          $$GpsPointsTableFilterComposer,
          $$GpsPointsTableOrderingComposer,
          $$GpsPointsTableAnnotationComposer,
          $$GpsPointsTableCreateCompanionBuilder,
          $$GpsPointsTableUpdateCompanionBuilder,
          (GpsPoint, BaseReferences<_$AppDatabase, $GpsPointsTable, GpsPoint>),
          GpsPoint,
          PrefetchHooks Function()
        > {
  $$GpsPointsTableTableManager(_$AppDatabase db, $GpsPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GpsPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GpsPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GpsPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<bool> isMock = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GpsPointsCompanion(
                id: id,
                tripId: tripId,
                recordedAt: recordedAt,
                lat: lat,
                lng: lng,
                accuracyM: accuracyM,
                speedMps: speedMps,
                heading: heading,
                isMock: isMock,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required DateTime recordedAt,
                required double lat,
                required double lng,
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<bool> isMock = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GpsPointsCompanion.insert(
                id: id,
                tripId: tripId,
                recordedAt: recordedAt,
                lat: lat,
                lng: lng,
                accuracyM: accuracyM,
                speedMps: speedMps,
                heading: heading,
                isMock: isMock,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GpsPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GpsPointsTable,
      GpsPoint,
      $$GpsPointsTableFilterComposer,
      $$GpsPointsTableOrderingComposer,
      $$GpsPointsTableAnnotationComposer,
      $$GpsPointsTableCreateCompanionBuilder,
      $$GpsPointsTableUpdateCompanionBuilder,
      (GpsPoint, BaseReferences<_$AppDatabase, $GpsPointsTable, GpsPoint>),
      GpsPoint,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedTripsTableTableManager get cachedTrips =>
      $$CachedTripsTableTableManager(_db, _db.cachedTrips);
  $$CachedVehiclesTableTableManager get cachedVehicles =>
      $$CachedVehiclesTableTableManager(_db, _db.cachedVehicles);
  $$OutboxItemsTableTableManager get outboxItems =>
      $$OutboxItemsTableTableManager(_db, _db.outboxItems);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$GpsPointsTableTableManager get gpsPoints =>
      $$GpsPointsTableTableManager(_db, _db.gpsPoints);
}
