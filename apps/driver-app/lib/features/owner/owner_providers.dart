// Owner mode's data: plain FutureProviders over [OwnerApi], online-first. Screens
// show loading/error/retry and refresh by invalidating; actions call the API and
// then invalidate what they changed (see [refreshAfter]).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/models.dart';
import '../../core/api/owner_api.dart';
import '../../core/api/owner_models.dart';

final ownerTripsProvider = FutureProvider.autoDispose
    .family<List<Trip>, TripFilter>(
      (ref, filter) => ref.watch(ownerApiProvider).trips(filter),
    );

final ownerTripProvider = FutureProvider.autoDispose.family<Trip, String>(
  (ref, id) => ref.watch(ownerApiProvider).trip(id),
);

final tripEventsProvider = FutureProvider.autoDispose
    .family<List<TripEvent>, String>(
      (ref, id) => ref.watch(ownerApiProvider).tripEvents(id),
    );

final tripRouteProvider = FutureProvider.autoDispose.family<TripRoute, String>(
  (ref, id) => ref.watch(ownerApiProvider).tripRoute(id),
);

final distanceCheckProvider = FutureProvider.autoDispose
    .family<DistanceCheck?, String>(
      (ref, id) => ref.watch(ownerApiProvider).distanceCheck(id),
    );

/// All vehicles, active and inactive.
final fleetVehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>(
  (ref) => ref.watch(ownerApiProvider).vehicles(),
);

final fleetVehicleProvider = FutureProvider.autoDispose.family<Vehicle, String>(
  (ref, id) => ref.watch(ownerApiProvider).vehicle(id),
);

final vehicleModelsProvider = FutureProvider.autoDispose<List<VehicleModel>>(
  (ref) => ref.watch(ownerApiProvider).vehicleModels(),
);

final driversProvider = FutureProvider.autoDispose<List<Driver>>(
  (ref) => ref.watch(ownerApiProvider).drivers(),
);

final membersProvider = FutureProvider.autoDispose<List<Member>>(
  (ref) => ref.watch(ownerApiProvider).members(),
);

typedef DocumentQuery = ({
  String? vehicleId,
  String? driverId,
  int? expiringWithinDays,
});

final documentsProvider = FutureProvider.autoDispose
    .family<List<FleetDocument>, DocumentQuery>(
      (ref, q) => ref
          .watch(ownerApiProvider)
          .documents(
            vehicleId: q.vehicleId,
            driverId: q.driverId,
            expiringWithinDays: q.expiringWithinDays,
          ),
    );

final auditSettingsProvider = FutureProvider.autoDispose<AuditSettings>(
  (ref) => ref.watch(ownerApiProvider).auditSettings(),
);

final defaultPayRuleProvider = FutureProvider.autoDispose<PayRule>(
  (ref) => ref.watch(ownerApiProvider).defaultPayRule(),
);

/// Fills for one vehicle (null: every vehicle), voided ones included.
final fuelFillsProvider = FutureProvider.autoDispose
    .family<List<FuelFill>, String?>(
      (ref, vehicleId) =>
          ref.watch(ownerApiProvider).fuelFills(vehicleId: vehicleId),
    );

final vehicleAuditProvider = FutureProvider.autoDispose
    .family<VehicleFuelAudit, String>(
      (ref, vehicleId) => ref.watch(ownerApiProvider).vehicleAudit(vehicleId),
    );

typedef AlertQuery = ({String? status, String? kind, String? tripId});

final alertsProvider = FutureProvider.autoDispose
    .family<List<Alert>, AlertQuery>(
      (ref, q) => ref
          .watch(ownerApiProvider)
          .alerts(status: q.status, kind: q.kind, tripId: q.tripId),
    );

final alertSummaryProvider = FutureProvider.autoDispose<AlertSummary>(
  (ref) => ref.watch(ownerApiProvider).alertSummary(),
);

/// Review items with a status (null: all).
final reviewItemsProvider = FutureProvider.autoDispose
    .family<List<ReviewItem>, String?>(
      (ref, status) => ref.watch(ownerApiProvider).reviewItems(status: status),
    );

final settlementsProvider = FutureProvider.autoDispose
    .family<List<SettlementSummary>, String>(
      (ref, date) => ref.watch(ownerApiProvider).settlements(date),
    );

final settlementProvider = FutureProvider.autoDispose
    .family<SettlementDetail, ({String date, String driverId})>(
      (ref, key) =>
          ref.watch(ownerApiProvider).settlement(key.date, key.driverId),
    );

final mediaUrlProvider = FutureProvider.autoDispose.family<MediaUrl, String>(
  (ref, mediaId) => ref.watch(ownerApiProvider).mediaUrl(mediaId),
);

/// What a change touches, so the screens showing it reload.
enum OwnerArea { trips, fleet, documents, settings, fuel, alerts, settlements }

/// Reloads every provider in [areas] after a successful change.
void refreshAfter(WidgetRef ref, Set<OwnerArea> areas) {
  for (final area in areas) {
    switch (area) {
      case OwnerArea.trips:
        ref
          ..invalidate(ownerTripsProvider)
          ..invalidate(ownerTripProvider)
          ..invalidate(tripEventsProvider);
      case OwnerArea.fleet:
        ref
          ..invalidate(fleetVehiclesProvider)
          ..invalidate(fleetVehicleProvider)
          ..invalidate(driversProvider)
          ..invalidate(membersProvider);
      case OwnerArea.documents:
        ref.invalidate(documentsProvider);
      case OwnerArea.settings:
        ref
          ..invalidate(auditSettingsProvider)
          ..invalidate(defaultPayRuleProvider);
      case OwnerArea.fuel:
        ref
          ..invalidate(fuelFillsProvider)
          ..invalidate(vehicleAuditProvider);
      case OwnerArea.alerts:
        ref
          ..invalidate(alertsProvider)
          ..invalidate(alertSummaryProvider)
          ..invalidate(reviewItemsProvider);
      case OwnerArea.settlements:
        ref
          ..invalidate(settlementsProvider)
          ..invalidate(settlementProvider);
    }
  }
}
