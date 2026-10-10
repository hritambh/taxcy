import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/core/api/json.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/features/fuel/fuel_vehicle.dart';

import 'support/fakes.dart';

final now = DateTime.utc(2026, 10, 10, 12);

Trip trip(
  String id,
  String status, {
  String vehicleId = 'v1',
  DateTime? start,
  DateTime? endedAt,
}) {
  final json = tripJson(id: id, status: status, scheduledStartAt: start ?? now);
  final vehicle = Map<String, Object?>.of(asJsonMap(json['vehicle']))
    ..['id'] = vehicleId
    ..['registrationNo'] = 'MH12${vehicleId.toUpperCase()}';
  return Trip.fromJson({
    ...json,
    'vehicle': vehicle,
    'endedAt': endedAt?.toIso8601String(),
  });
}

List<String> ids(List<FuelVehicleOption> options) => [
  for (final o in options) '${o.vehicle.id}/${o.trip.id}',
];

void main() {
  test('a running trip decides the vehicle on its own', () {
    final options = fuelVehicleOptions([
      trip('t1', 'assigned', vehicleId: 'v1'),
      trip('t2', 'started', vehicleId: 'v2'),
    ], now);
    expect(ids(options), ['v2/t2']);
  });

  test(
    'otherwise assigned trips (soonest first), then trips ended in the last day',
    () {
      final options = fuelVehicleOptions([
        trip(
          'old',
          'ended',
          vehicleId: 'v4',
          endedAt: now.subtract(const Duration(days: 2)),
        ),
        trip(
          'recent',
          'ended',
          vehicleId: 'v3',
          endedAt: now.subtract(const Duration(hours: 3)),
        ),
        trip(
          'later',
          'assigned',
          vehicleId: 'v2',
          start: now.add(const Duration(days: 1)),
        ),
        trip(
          'soon',
          'assigned',
          vehicleId: 'v1',
          start: now.add(const Duration(hours: 1)),
        ),
        trip(
          'same-car',
          'assigned',
          vehicleId: 'v1',
          start: now.add(const Duration(days: 2)),
        ),
        trip('gone', 'cancelled', vehicleId: 'v5'),
      ], now);
      expect(ids(options), ['v1/soon', 'v2/later', 'v3/recent']);
    },
  );

  test('no trips with a vehicle means nothing to log fuel for', () {
    expect(fuelVehicleOptions([trip('x', 'cancelled')], now), isEmpty);
    expect(fuelVehicleOptions(const [], now), isEmpty);
  });
}
