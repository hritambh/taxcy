import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Trips assigned to this driver, cached as the API's JSON so the app works offline.
/// Local, not-yet-synced changes (e.g. a trip started offline) are applied to the
/// cached JSON too, so the UI always shows the driver's latest view.
class CachedTrips extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();
  TextColumn get status => text()();
  DateTimeColumn get scheduledStartAt => dateTime()();

  /// Set when the server rejected a queued command for this trip (cancelled or
  /// reassigned while the phone was offline). Shown as a notice on the trip.
  TextColumn get conflict => text().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedVehicles extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Writes waiting to reach the server, replayed strictly in insertion order.
class OutboxItems extends Table {
  IntColumn get seq => integer().autoIncrement()();

  /// Stable client UUID for this write. Used as the Idempotency-Key for commands,
  /// so every retry of the same write is recognised by the server.
  TextColumn get key => text().unique()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
  TextColumn get tripId => text().nullable()();

  /// pending (to send), attention (rejected; needs the driver), done.
  TextColumn get state => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Photos taken with the in-app camera, kept on disk until uploaded.
class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get path => text()();
  TextColumn get sha256 => text()();
  IntColumn get byteSize => integer()();
  TextColumn get contentType => text()();
  DateTimeColumn get capturedAt => dateTime()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  RealColumn get accuracyM => real().nullable()();
  BoolColumn get isMock => boolean().withDefault(const Constant(false))();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class GpsPoints extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get speedMps => real().nullable()();
  RealColumn get heading => real().nullable()();
  BoolColumn get isMock => boolean().withDefault(const Constant(false))();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [CachedTrips, CachedVehicles, OutboxItems, Photos, GpsPoints],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database (SQLite file in the app's documents directory).
  factory AppDatabase.onDevice() =>
      AppDatabase(driftDatabase(name: 'taxcy_driver'));

  @override
  int get schemaVersion => 1;

  /// Removes everything when the driver signs out.
  Future<void> clearAll() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}
