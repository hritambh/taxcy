import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/json.dart';
import '../api/models.dart';
import '../db/database.dart';
import '../domain/trip_state_machine.dart';
import '../media/captured_photo.dart';
import '../sync/outbox.dart';
import '../sync/sync_engine.dart';

class TripView {
  const TripView(this.trip, {this.conflict});
  final Trip trip;

  /// TRIP_CANCELLED or TRIP_REASSIGNED when the server rejected an offline write.
  final String? conflict;
}

/// Why the app refused an action before queuing it (shown in the user's language).
enum RejectionReason {
  endBeforeStart,
  needDrop,
  endBelowStart,
  chargesActiveOnly,
  paymentsAfterStart,
  tripCancelled,
  cancellationPending,
  noPendingCancellation,
  notAllowed,
  wrongState,
}

class LocalRejection implements Exception {
  LocalRejection(this.reason, this.message, {this.km, this.status});
  final RejectionReason reason;

  /// English, for logs and tests; the UI translates [reason].
  final String message;

  /// The minimum km, for [RejectionReason.endBelowStart].
  final int? km;

  /// The trip's status, for [RejectionReason.wrongState].
  final String? status;

  @override
  String toString() => message;
}

/// The driver's trips. Every action is written locally first (cache + outbox), so
/// it works with no network; the sync engine delivers it later.
class TripsRepository {
  TripsRepository(this.db, this.engine, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase db;
  final SyncEngine engine;
  final DateTime Function() _now;
  Outbox get _outbox => engine.outbox;
  static const _uuid = Uuid();

  Stream<List<TripView>> watchTrips() =>
      (db.select(db.cachedTrips)
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledStartAt)]))
          .watch()
          .map((rows) => rows.map(_view).toList());

  Stream<TripView?> watchTrip(String id) =>
      (db.select(db.cachedTrips)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _view(row));

  Future<TripView?> trip(String id) async {
    final row = await (db.select(
      db.cachedTrips,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _view(row);
  }

  TripView _view(CachedTrip row) => TripView(
    Trip.fromJson(asJsonMap(jsonDecode(row.json))),
    conflict: row.conflict,
  );

  /// Checks the Dart port of the state machine before queuing, so the driver
  /// gets an immediate answer even offline.
  void _assertAllowed(Trip trip, String command) {
    final decision = decideTransition(
      TripState(trip.status, cancellationPending: trip.cancellationPending),
      command,
      const [TripActor.assignedDriver],
    );
    if (decision is Rejected) {
      final reason = switch (decision.error) {
        'TRIP_CANCELLED' => RejectionReason.tripCancelled,
        'CANCELLATION_PENDING' => RejectionReason.cancellationPending,
        'FORBIDDEN_ROLE' => RejectionReason.notAllowed,
        _ when tripTransitions[command]!.from.contains(trip.status) =>
          RejectionReason.noPendingCancellation,
        _ => RejectionReason.wrongState,
      };
      throw LocalRejection(reason, decision.message, status: trip.status);
    }
  }

  Future<OdometerReading> _odometer(CapturedPhoto photo, int km) async {
    await savePhoto(db, photo);
    await _outbox.enqueue(OutboxKind.media, {'photoId': photo.id});
    return OdometerReading(
      id: _uuid.v4(),
      typedKm: km,
      mediaId: photo.id,
      capturedAt: photo.capturedAt,
    );
  }

  Future<void> _save(Trip trip) => engine.cacheTrip(trip);

  /// Creates a trip for this driver, in [vehicle]. It shows straight away (as
  /// assigned, so it can be started at once) and reaches the server when online;
  /// any start or end queued after it is sent after it.
  Future<Trip> create({
    required String tripType,
    required String fromText,
    required String? toText,
    required DateTime scheduledStartAt,
    required DateTime scheduledEndAt,
    required int quotedFarePaise,
    required Vehicle vehicle,
    int? includedKm,
    String? customerName,
    String? customerPhone,
  }) async {
    if (!scheduledEndAt.isAfter(scheduledStartAt)) {
      throw LocalRejection(
        RejectionReason.endBeforeStart,
        'The trip must end after it starts',
      );
    }
    if (tripType != 'local_rental' && (toText == null || toText.isEmpty)) {
      throw LocalRejection(
        RejectionReason.needDrop,
        'Enter where the trip goes',
      );
    }
    final id = _uuid.v4();
    final trip = Trip(
      id: id,
      tripType: tripType,
      status: 'assigned',
      fromText: fromText,
      toText: tripType == 'local_rental' ? null : toText,
      scheduledStartAt: scheduledStartAt,
      scheduledEndAt: scheduledEndAt,
      quotedFarePaise: quotedFarePaise,
      includedKm: includedKm,
      customerName: customerName,
      customerPhone: customerName == null ? null : customerPhone,
      vehicle: TripVehicle(
        id: vehicle.id,
        registrationNo: vehicle.registrationNo,
        model: vehicle.model,
      ),
      allowedCommands: allowedCommands(const TripState('assigned')),
      updatedAt: _now(),
    );
    await db.transaction(() async {
      await _outbox.enqueue(OutboxKind.tripCreate, {
        'body': {
          'id': id,
          'tripType': tripType,
          'from': {'text': fromText},
          if (trip.toText != null) 'to': {'text': trip.toText},
          'scheduledStartAt': scheduledStartAt.toUtc().toIso8601String(),
          'scheduledEndAt': scheduledEndAt.toUtc().toIso8601String(),
          'quotedFarePaise': quotedFarePaise,
          'includedKm': ?includedKm,
          if (customerName != null)
            'customer': {'name': customerName, 'phone': ?customerPhone},
          'vehicleId': vehicle.id,
        },
      }, tripId: id);
      await _save(trip);
    });
    return trip;
  }

  Future<void> start(
    Trip trip, {
    required CapturedPhoto photo,
    required int km,
  }) async {
    _assertAllowed(trip, 'start');
    await db.transaction(() async {
      final odometer = await _odometer(photo, km);
      final at = _now();
      await _outbox.enqueue(OutboxKind.tripCommand, {
        'tripId': trip.id,
        'command': 'start',
        'body': {
          'odometer': odometer.toInput(),
          'occurredAt': at.toUtc().toIso8601String(),
        },
      }, tripId: trip.id);
      await _save(
        trip.copyWith(
          status: 'started',
          startedAt: at,
          startOdometer: odometer,
          allowedCommands: allowedCommands(const TripState('started')),
        ),
      );
    });
  }

  Future<void> end(
    Trip trip, {
    required CapturedPhoto photo,
    required int km,
    List<TripCollection> collections = const [],
    List<TripCharge> charges = const [],
  }) async {
    _assertAllowed(trip, 'end');
    final startKm = trip.startOdometer?.typedKm;
    if (startKm != null && km < startKm) {
      throw LocalRejection(
        RejectionReason.endBelowStart,
        'End reading must be at least $startKm km',
        km: startKm,
      );
    }
    await db.transaction(() async {
      final odometer = await _odometer(photo, km);
      final at = _now();
      await _outbox.enqueue(OutboxKind.tripCommand, {
        'tripId': trip.id,
        'command': 'end',
        'body': {
          'odometer': odometer.toInput(),
          'occurredAt': at.toUtc().toIso8601String(),
          'collections': collections.map((c) => c.toInput()).toList(),
          'charges': charges.map((c) => c.toInput()).toList(),
        },
      }, tripId: trip.id);
      await _save(
        trip.copyWith(
          status: 'ended',
          endedAt: at,
          endOdometer: odometer,
          collections: [...trip.collections, ...collections],
          charges: [...trip.charges, ...charges],
          allowedCommands: allowedCommands(const TripState('ended')),
        ),
      );
    });
  }

  Future<void> requestCancellation(
    Trip trip, {
    required String reason,
    required CapturedPhoto photo,
    required int km,
  }) async {
    _assertAllowed(trip, 'requestCancel');
    await db.transaction(() async {
      final odometer = await _odometer(photo, km);
      final requestId = _uuid.v4();
      await _outbox.enqueue(OutboxKind.tripCommand, {
        'tripId': trip.id,
        'command': 'cancellation-requests',
        'body': {
          'id': requestId,
          'reason': reason,
          'endOdometer': odometer.toInput(),
          'occurredAt': _now().toUtc().toIso8601String(),
        },
      }, tripId: trip.id);
      await _save(
        trip.copyWith(
          cancellationRequest: CancellationRequest(
            id: requestId,
            status: 'pending',
            reason: reason,
          ),
          allowedCommands: allowedCommands(
            const TripState('started', cancellationPending: true),
          ),
        ),
      );
    });
  }

  Future<void> addCharge(
    Trip trip,
    TripCharge charge, {
    CapturedPhoto? receipt,
  }) async {
    if (!['assigned', 'started', 'ended'].contains(trip.status)) {
      throw LocalRejection(
        RejectionReason.chargesActiveOnly,
        'Charges can only be added to an active trip',
      );
    }
    await db.transaction(() async {
      if (receipt != null) {
        await savePhoto(db, receipt);
        await _outbox.enqueue(OutboxKind.media, {'photoId': receipt.id});
      }
      await _outbox.enqueue(OutboxKind.tripCharge, {
        'tripId': trip.id,
        'body': charge.toInput(),
      }, tripId: trip.id);
      await _save(trip.copyWith(charges: [...trip.charges, charge]));
    });
  }

  Future<void> addCollection(Trip trip, TripCollection collection) async {
    if (trip.startedAt == null) {
      throw LocalRejection(
        RejectionReason.paymentsAfterStart,
        'Payments can be recorded once the trip has started',
      );
    }
    await db.transaction(() async {
      await _outbox.enqueue(OutboxKind.tripCollection, {
        'tripId': trip.id,
        'body': collection.toInput(),
      }, tripId: trip.id);
      await _save(
        trip.copyWith(collections: [...trip.collections, collection]),
      );
    });
  }
}
