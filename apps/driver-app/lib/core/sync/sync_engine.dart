import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../api/api.dart';
import '../api/json.dart';
import '../api/models.dart';
import '../db/database.dart';
import '../domain/trip_state_machine.dart';
import 'outbox.dart';

/// Reads a captured photo's bytes (from disk in the app; from memory in tests).
typedef PhotoReader = Future<Uint8List> Function(String path);

class SyncStatus {
  const SyncStatus({
    required this.online,
    required this.pending,
    required this.attention,
    required this.syncing,
    this.lastSyncedAt,
    this.lastError,
  });

  final bool online;
  final int pending;
  final int attention;
  final bool syncing;
  final DateTime? lastSyncedAt;
  final String? lastError;

  SyncStatus copyWith({
    bool? online,
    int? pending,
    int? attention,
    bool? syncing,
    DateTime? lastSyncedAt,
    String? lastError,
  }) => SyncStatus(
    online: online ?? this.online,
    pending: pending ?? this.pending,
    attention: attention ?? this.attention,
    syncing: syncing ?? this.syncing,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    lastError: lastError ?? this.lastError,
  );
}

/// Something the driver must be told about, e.g. a trip cancelled while offline.
/// The UI words it from [code] (TRIP_CANCELLED or TRIP_REASSIGNED).
class SyncNotice {
  const SyncNotice({required this.tripId, required this.code});
  final String tripId;
  final String code;
}

const _conflictCodes = {'TRIP_CANCELLED', 'TRIP_REASSIGNED'};

/// Retry delay after `attempts` failures: 2 s, 4 s, 8 s … capped at 5 minutes.
Duration backoffFor(int attempts) {
  final seconds = 2 * pow(2, max(0, attempts - 1));
  return Duration(seconds: min(seconds.toInt(), 300));
}

/// Pushes the outbox to the API in order, uploads GPS, and pulls the driver's trips.
///
/// Ordering rule: the outbox is strictly FIFO. A retryable failure (offline,
/// 5xx, 429) stops the drain so later writes never overtake earlier ones — a
/// photo is always confirmed before the command that cites it. A permanent
/// rejection moves the item to "needs attention" and the drain continues.
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.api,
    required this.readPhoto,
    required this.deviceId,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       outbox = Outbox(db, now: now);

  final AppDatabase db;
  final TaxcyApi api;
  final PhotoReader readPhoto;
  final Future<String> Function() deviceId;
  final Outbox outbox;
  final DateTime Function() _now;

  static const gpsBatchSize = 500;

  final _status = StreamController<SyncStatus>.broadcast();
  final _notices = StreamController<SyncNotice>.broadcast();
  SyncStatus _current = const SyncStatus(
    online: true,
    pending: 0,
    attention: 0,
    syncing: false,
  );
  Future<void>? _running;

  Stream<SyncStatus> get status => _status.stream;
  Stream<SyncNotice> get notices => _notices.stream;
  SyncStatus get current => _current;

  void _emit(SyncStatus status) {
    _current = status;
    _status.add(status);
  }

  /// Connectivity changed (from connectivity_plus). Going online triggers a sync.
  void setOnline(bool online) {
    _emit(_current.copyWith(online: online));
    if (online) unawaited(syncNow());
  }

  /// Runs one full sync; concurrent callers share the run in progress.
  Future<void> syncNow() => _running ??= _sync().whenComplete(() {
    _running = null;
  });

  Future<void> _sync() async {
    _emit(_current.copyWith(syncing: true));
    try {
      final drained = await drainOutbox();
      if (drained) await uploadGps();
      if (_current.online) await pullTrips();
    } finally {
      await _refreshCounts(syncing: false);
    }
  }

  Future<void> _refreshCounts({bool? syncing}) async {
    final rows = await db.select(db.outboxItems).get();
    _emit(
      _current.copyWith(
        pending: rows.where((r) => r.state == OutboxState.pending).length,
        attention: rows.where((r) => r.state == OutboxState.attention).length,
        syncing: syncing,
      ),
    );
  }

  /// Sends queued writes in order. Returns false if it stopped early on a
  /// retryable failure (offline or server trouble).
  Future<bool> drainOutbox() async {
    for (final item in await outbox.pending()) {
      final due = item.nextAttemptAt;
      if (due != null && due.isAfter(_now())) return false;
      // The item may have been dropped by a conflict earlier in this pass.
      final stillQueued = await (db.select(
        db.outboxItems,
      )..where((t) => t.seq.equals(item.seq))).getSingleOrNull();
      if (stillQueued == null) continue;
      try {
        await _send(item);
        await outbox.remove(item.seq);
        _emit(_current.copyWith(online: true, lastSyncedAt: _now()));
      } on ApiException catch (error) {
        if (_conflictCodes.contains(error.code)) {
          await outbox.remove(item.seq);
          await _applyConflict(item.tripId, error.code);
          continue;
        }
        if (error.isRetryable || error.code == 'UPLOAD_NOT_FOUND') {
          await outbox.scheduleRetry(
            item,
            _now().add(backoffFor(item.attempts + 1)),
            '${error.code}: ${error.message}',
          );
          _emit(
            _current.copyWith(
              online: !error.isNetwork,
              lastError: error.message,
            ),
          );
          return false;
        }
        await outbox.needsAttention(item, '${error.code}: ${error.message}');
        _emit(_current.copyWith(online: true, lastError: error.message));
      }
      await _refreshCounts();
    }
    return true;
  }

  Future<void> _send(OutboxItem item) async {
    final payload = decodePayload(item);
    switch (item.kind) {
      case OutboxKind.media:
        await _sendPhoto(payload.str('photoId'));
      case OutboxKind.tripCommand:
        final trip = await api.tripCommand(
          payload.str('tripId'),
          payload.str('command'),
          item.key,
          payload.obj('body'),
        );
        await _storeServerTrip(trip, excludingSeq: item.seq);
      case OutboxKind.tripCreate:
        final trip = await api.createTrip(payload.obj('body'));
        await _storeServerTrip(trip, excludingSeq: item.seq);
      case OutboxKind.tripCharge:
        final trip = await api.addCharge(
          payload.str('tripId'),
          payload.obj('body'),
        );
        await _storeServerTrip(trip, excludingSeq: item.seq);
      case OutboxKind.tripCollection:
        final trip = await api.addCollection(
          payload.str('tripId'),
          payload.obj('body'),
        );
        await _storeServerTrip(trip, excludingSeq: item.seq);
      case OutboxKind.fuelFill:
        await api.recordFuelFill(payload.obj('body'));
      default:
        throw ApiException(
          status: 400,
          code: 'UNKNOWN_KIND',
          message: 'Unknown outbox item ${item.kind}',
        );
    }
  }

  Future<void> _sendPhoto(String photoId) async {
    final photo = await (db.select(
      db.photos,
    )..where((p) => p.id.equals(photoId))).getSingle();
    if (photo.uploaded) return;
    final ticket = await api.registerMedia({
      'id': photo.id,
      'kind': photo.kind,
      'contentType': photo.contentType,
      'sha256': photo.sha256,
      'byteSize': photo.byteSize,
      'capturedAt': photo.capturedAt.toUtc().toIso8601String(),
      if (photo.lat != null && photo.lng != null)
        'location': {
          'lat': photo.lat,
          'lng': photo.lng,
          if (photo.accuracyM != null) 'accuracyM': photo.accuracyM,
        },
      'isMockLocation': photo.isMock,
      'deviceId': await deviceId(),
    });
    final url = ticket.uploadUrl;
    if (ticket.status == 'pending' && url != null) {
      await api.uploadBytes(
        url,
        ticket.uploadHeaders,
        await readPhoto(photo.path),
      );
    }
    if (ticket.status != 'uploaded') await api.completeMedia(photo.id);
    await (db.update(db.photos)..where((p) => p.id.equals(photo.id))).write(
      const PhotosCompanion(uploaded: Value(true)),
    );
  }

  /// The server's view replaces the cached trip, unless more local writes for
  /// the trip are still queued (then the optimistic local view stays until they land).
  Future<void> _storeServerTrip(Trip trip, {required int excludingSeq}) async {
    final morePending =
        await (db.select(db.outboxItems)..where(
              (t) =>
                  t.tripId.equals(trip.id) &
                  t.state.equals(OutboxState.pending) &
                  t.seq.isNotValue(excludingSeq) &
                  t.kind.isNotValue(OutboxKind.media),
            ))
            .get();
    if (morePending.isEmpty) await cacheTrip(trip);
  }

  Future<void> cacheTrip(Trip trip, {String? conflict}) => db
      .into(db.cachedTrips)
      .insertOnConflictUpdate(
        CachedTripsCompanion.insert(
          id: trip.id,
          json: jsonEncode(trip.toJson()),
          status: trip.status,
          scheduledStartAt: trip.scheduledStartAt,
          conflict: Value(conflict),
          syncedAt: _now(),
        ),
      );

  /// Server wins: mark the trip, drop its queued writes (photos still upload), tell the driver.
  Future<void> _applyConflict(String? tripId, String code) async {
    if (tripId == null) return;
    await outbox.dropTripWrites(tripId);
    final cached = await (db.select(
      db.cachedTrips,
    )..where((t) => t.id.equals(tripId))).getSingleOrNull();
    if (cached != null) {
      final trip = Trip.fromJson(asJsonMap(jsonDecode(cached.json)));
      final updated = code == 'TRIP_CANCELLED'
          ? trip.copyWith(
              status: 'cancelled',
              allowedCommands: allowedCommands(const TripState('cancelled')),
            )
          : trip.copyWith(allowedCommands: const []);
      await cacheTrip(updated, conflict: code);
    }
    _notices.add(SyncNotice(tripId: tripId, code: code));
  }

  /// Uploads recorded GPS points in batches, once the trip's start has reached the server.
  Future<void> uploadGps() async {
    final rows =
        await (db.select(db.gpsPoints)
              ..where((p) => p.uploaded.equals(false))
              ..orderBy([(p) => OrderingTerm.asc(p.recordedAt)]))
            .get();
    final byTrip = <String, List<GpsPoint>>{};
    for (final row in rows) {
      (byTrip[row.tripId] ??= []).add(row);
    }
    for (final entry in byTrip.entries) {
      if (await outbox.hasPendingFor(entry.key, kind: OutboxKind.tripCommand)) {
        continue; // wait until the start command has synced
      }
      for (var i = 0; i < entry.value.length; i += gpsBatchSize) {
        final batch = entry.value.sublist(
          i,
          min(i + gpsBatchSize, entry.value.length),
        );
        try {
          await api.uploadGps(entry.key, [
            for (final p in batch)
              {
                'id': p.id,
                'recordedAt': p.recordedAt.toUtc().toIso8601String(),
                'lat': p.lat,
                'lng': p.lng,
                if (p.accuracyM != null) 'accuracyM': p.accuracyM,
                if (p.speedMps != null) 'speedMps': p.speedMps,
                if (p.heading != null) 'heading': p.heading,
                'isMock': p.isMock,
              },
          ]);
        } on ApiException catch (error) {
          if (error.isRetryable) return;
          // 404 (trip no longer ours) etc.: these points can never be accepted.
        }
        await (db.update(db.gpsPoints)
              ..where((p) => p.id.isIn(batch.map((b) => b.id))))
            .write(const GpsPointsCompanion(uploaded: Value(true)));
      }
    }
  }

  DateTime? _lastPullAt;

  /// Refreshes the cached trips from the server, keeping trips with unsynced local
  /// writes. An active trip that's no longer returned was reassigned to someone else.
  Future<void> pullTrips() async {
    final pulledAt = _now();
    final trips = await api.myTrips(
      since: _lastPullAt?.subtract(const Duration(minutes: 1)),
    );
    final returned = trips.map((t) => t.id).toSet();
    for (final trip in trips) {
      if (await outbox.hasPendingFor(trip.id)) continue;
      final cached = await (db.select(
        db.cachedTrips,
      )..where((t) => t.id.equals(trip.id))).getSingleOrNull();
      await cacheTrip(trip, conflict: cached?.conflict);
    }
    final active =
        await (db.select(db.cachedTrips)..where(
              (t) =>
                  t.status.isIn(['assigned', 'started']) & t.conflict.isNull(),
            ))
            .get();
    for (final row in active) {
      if (returned.contains(row.id) || await outbox.hasPendingFor(row.id)) {
        continue;
      }
      await _applyConflict(row.id, 'TRIP_REASSIGNED');
    }
    _lastPullAt = pulledAt;
    _emit(_current.copyWith(online: true, lastSyncedAt: pulledAt));
  }

  Future<void> dispose() async {
    await _status.close();
    await _notices.close();
  }
}
