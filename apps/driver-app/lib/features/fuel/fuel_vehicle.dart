import '../../core/api/models.dart';

/// A vehicle the driver may log fuel for, and the trip that gives it to them.
class FuelVehicleOption {
  const FuelVehicleOption({required this.vehicle, required this.trip});
  final TripVehicle vehicle;
  final Trip trip;
}

/// Which vehicles a driver can log fuel for, from their trips: the vehicle of a
/// running trip if there is one (the fill is then linked to that trip); otherwise
/// the vehicles of assigned trips, then of trips that ended in the last day (e.g.
/// filling up after the drop). The driver never picks from the whole fleet.
List<FuelVehicleOption> fuelVehicleOptions(List<Trip> trips, DateTime now) {
  final withVehicle = trips.where((t) => t.vehicle != null).toList();

  final started = withVehicle.where((t) => t.status == 'started').toList();
  if (started.isNotEmpty) {
    return [
      FuelVehicleOption(vehicle: started.first.vehicle!, trip: started.first),
    ];
  }

  final assigned = withVehicle.where((t) => t.status == 'assigned').toList()
    ..sort((a, b) => a.scheduledStartAt.compareTo(b.scheduledStartAt));
  final recentlyEnded =
      withVehicle
          .where(
            (t) =>
                t.status == 'ended' &&
                t.endedAt != null &&
                now.difference(t.endedAt!) <= const Duration(hours: 24),
          )
          .toList()
        ..sort((a, b) => b.endedAt!.compareTo(a.endedAt!));

  final seen = <String>{};
  return [
    for (final t in [...assigned, ...recentlyEnded])
      if (seen.add(t.vehicle!.id))
        FuelVehicleOption(vehicle: t.vehicle!, trip: t),
  ];
}
