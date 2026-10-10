import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../api/api.dart';
import '../api/json.dart';
import '../api/models.dart';
import '../db/database.dart';
import '../media/captured_photo.dart';
import '../sync/outbox.dart';

class FuelFillInput {
  const FuelFillInput({
    required this.vehicle,
    required this.fuel,
    required this.quantityMilli,
    required this.costPaise,
    required this.isFullTank,
    required this.paidBy,
    required this.odometerKm,
    required this.odometerPhoto,
    required this.receipt,
    this.tripId,
  });

  final Vehicle vehicle;
  final String fuel;

  /// Millilitres (petrol, diesel) or grams (CNG).
  final int quantityMilli;
  final int costPaise;
  final bool isFullTank;

  /// driver_cash, owner or fuel_card.
  final String paidBy;
  final int odometerKm;
  final CapturedPhoto odometerPhoto;
  final CapturedPhoto receipt;
  final String? tripId;
}

class FuelRepository {
  FuelRepository(this.db, this.api, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _outbox = Outbox(db, now: now);

  final AppDatabase db;
  final TaxcyApi api;
  final DateTime Function() _now;
  final Outbox _outbox;

  /// Records a fill locally and queues it (receipt and odometer photos first).
  Future<String> record(FuelFillInput input) async {
    if (!input.vehicle.allowedFuels.contains(input.fuel)) {
      throw ArgumentError(
        '${input.vehicle.registrationNo} does not take ${input.fuel}',
      );
    }
    final id = const Uuid().v4();
    final filledAt = _now();
    await db.transaction(() async {
      for (final photo in [input.receipt, input.odometerPhoto]) {
        await savePhoto(db, photo);
        await _outbox.enqueue(OutboxKind.media, {'photoId': photo.id});
      }
      await _outbox.enqueue(OutboxKind.fuelFill, {
        'body': {
          'id': id,
          'vehicleId': input.vehicle.id,
          if (input.tripId != null) 'tripId': input.tripId,
          'fuel': input.fuel,
          'quantityMilli': input.quantityMilli,
          'costPaise': input.costPaise,
          'odometer': {
            'id': const Uuid().v4(),
            'typedKm': input.odometerKm,
            'mediaId': input.odometerPhoto.id,
            'capturedAt': input.odometerPhoto.capturedAt
                .toUtc()
                .toIso8601String(),
          },
          'isFullTank': input.isFullTank,
          'receiptMediaId': input.receipt.id,
          'paidBy': input.paidBy,
          'filledAt': filledAt.toUtc().toIso8601String(),
        },
        // Tagged with the trip so a sync doesn't replace the trip's local view
        // (which already shows this fill) until the fill has reached the server.
      }, tripId: input.tripId);
      final tripId = input.tripId;
      if (tripId != null) {
        await _showOnTrip(
          tripId,
          TripFuelFill(
            id: id,
            fuel: input.fuel,
            quantityMilli: input.quantityMilli,
            costPaise: input.costPaise,
            paidBy: input.paidBy,
            isFullTank: input.isFullTank,
            filledAt: filledAt,
          ),
        );
      }
    });
    return id;
  }

  Future<void> _showOnTrip(String tripId, TripFuelFill fill) async {
    final row = await (db.select(
      db.cachedTrips,
    )..where((t) => t.id.equals(tripId))).getSingleOrNull();
    if (row == null) return;
    final trip = Trip.fromJson(asJsonMap(jsonDecode(row.json)));
    await (db.update(db.cachedTrips)..where((t) => t.id.equals(tripId))).write(
      CachedTripsCompanion(
        json: Value(
          jsonEncode(
            trip.copyWith(fuelFills: [...trip.fuelFills, fill]).toJson(),
          ),
        ),
      ),
    );
  }

  /// Vehicles the driver can pick, cached for offline use.
  Future<List<Vehicle>> vehicles({bool refresh = true}) async {
    if (refresh) {
      try {
        final fresh = await api.vehicles();
        await db.transaction(() async {
          await db.delete(db.cachedVehicles).go();
          for (final v in fresh) {
            await db
                .into(db.cachedVehicles)
                .insert(
                  CachedVehiclesCompanion.insert(
                    id: v.id,
                    json: jsonEncode(v.toJson()),
                  ),
                );
          }
        });
        return fresh;
      } on ApiException {
        // Offline: fall back to the cache below.
      }
    }
    final rows = await db.select(db.cachedVehicles).get();
    return rows
        .map((r) => Vehicle.fromJson(asJsonMap(jsonDecode(r.json))))
        .toList();
  }
}
