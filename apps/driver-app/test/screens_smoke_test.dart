import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/api/owner_models.dart';
import 'package:taxcy_driver/features/common/consent_screen.dart';
import 'package:taxcy_driver/features/fuel/fuel_fill_screen.dart';
import 'package:taxcy_driver/features/login/login_screen.dart';
import 'package:taxcy_driver/features/owner/alerts_screen.dart';
import 'package:taxcy_driver/features/owner/documents_screen.dart';
import 'package:taxcy_driver/features/owner/fuel_screens.dart';
import 'package:taxcy_driver/features/owner/owner_shell.dart';
import 'package:taxcy_driver/features/owner/people_screens.dart';
import 'package:taxcy_driver/features/owner/review_screen.dart';
import 'package:taxcy_driver/features/owner/settings_screen.dart';
import 'package:taxcy_driver/features/owner/settlements_screen.dart';
import 'package:taxcy_driver/features/owner/trips/create_trip_screen.dart';
import 'package:taxcy_driver/features/owner/trips/owner_trip_detail_screen.dart';
import 'package:taxcy_driver/features/owner/trips/owner_trips_screen.dart';
import 'package:taxcy_driver/features/owner/vehicles_screen.dart';
import 'package:taxcy_driver/features/trips/new_trip_screen.dart';
import 'package:taxcy_driver/features/trips/trip_detail_screen.dart';
import 'package:taxcy_driver/features/trips/trip_forms.dart';
import 'package:taxcy_driver/features/trips/trips_screen.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/owner_fakes.dart';

/// Every owner and driver screen renders on a small phone (360 px) in both
/// languages without overflowing or throwing.
void main() {
  final busyTrip = {
    ...tripJson(status: 'started', cancellationPending: true),
    'includedKm': 150,
    'charges': [
      {
        'id': 'c1',
        'kind': 'state_tax',
        'amountPaise': 125000,
        'paidByDriver': true,
        'mediaId': null,
        'note': 'Karnataka border',
        'enteredBy': 'u1',
        'enteredRole': 'driver',
        'voidedAt': null,
        'createdAt': '2026-10-09T04:00:00.000Z',
      },
    ],
    'collections': [
      {
        'id': 'p1',
        'method': 'upi',
        'amountPaise': 100000,
        'reference': 'UPI-1234567890',
        'collectedAt': '2026-10-09T05:00:00.000Z',
      },
    ],
  };
  final busyTripId = busyTrip['id']! as String;

  final screens = <String, Widget>{
    'shell': const OwnerShell(),
    'trips': const OwnerTripsScreen(),
    'create trip': const CreateTripScreen(),
    'trip detail': OwnerTripDetailScreen(tripId: busyTripId),
    'alerts': const AlertsScreen(),
    'more': const MoreScreen(),
    'vehicles': const VehiclesScreen(),
    'vehicle form': VehicleFormScreen(vehicle: Vehicle.fromJson(vehicleJson())),
    'vehicle detail': const VehicleDetailScreen(vehicleId: vehicleId),
    'fuel': const FuelIndexScreen(),
    'vehicle fuel': const VehicleFuelScreen(vehicleId: vehicleId),
    'drivers': const DriversScreen(),
    'driver': DriverScreen(
      driver: Driver.fromJson(
        driverJson(payRule: payRuleJson(kind: 'per_trip')),
      ),
    ),
    'members': const MembersScreen(),
    'documents': const DocumentsScreen(),
    'document form': const DocumentFormScreen(),
    'renew document': DocumentFormScreen(
      renewing: FleetDocument.fromJson(documentJson()),
    ),
    'review': const ReviewScreen(),
    'settlements': const SettlementsScreen(initialDate: '2026-10-09'),
    'settlement': const SettlementDetailScreen(
      date: '2026-10-09',
      driverId: driverId,
    ),
    'settings': const SettingsScreen(),
  };

  for (final language in ['en', 'hi']) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} ($language)', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(360, 1600);
        addTearDown(tester.view.reset);
        final h = await Harness.create(
          session: Session.fromJson(sessionJson(roles: ['owner', 'driver'])),
          language: language,
        );
        addTearDown(h.dispose);
        h.owner
          ..tripsById[busyTripId] = busyTrip
          ..distanceCheckResult = distanceCheckJson(result: 'inconclusive')
          ..alertList = [
            for (final kind in alertMessages.keys)
              alertJson(id: 'a-$kind', kind: kind, severity: 'critical'),
          ]
          ..reviewList = [
            reviewItemJson(),
            reviewItemJson(
              id: 'r2',
              kind: 'implausible_efficiency',
              subjectType: 'fuel_cycle',
              context: {'reason': 'x', 'reasonCode': 'implausibly_good'},
            ),
          ];
        await tester.pumpWidget(h.screen(entry.value));
        await settle(tester);
        // Any overflow or exception fails the test with the widget at fault.
      });
    }
  }

  final started = Trip.fromJson({...busyTrip, 'cancellationRequest': null});
  final driverScreens = <String, Widget>{
    'login': const LoginScreen(),
    'consent': LocationConsentScreen(onDone: () {}),
    'my trips': const TripsScreen(),
    'driver trip': TripDetailScreen(tripId: busyTripId),
    'start trip': StartTripScreen(trip: Trip.fromJson(tripJson())),
    'end trip': EndTripScreen(trip: started),
    'cancel request': CancelRequestScreen(trip: started),
    'new trip': const NewTripScreen(),
    'log fuel': const FuelFillScreen(),
  };
  for (final language in ['en', 'hi']) {
    for (final entry in driverScreens.entries) {
      testWidgets('driver: ${entry.key} ($language)', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(360, 1600);
        addTearDown(tester.view.reset);
        final h = await Harness.create(
          session: Session.fromJson(sessionJson()),
          language: language,
        );
        addTearDown(h.dispose);
        h.api.vehicleList = [Vehicle.fromJson(vehicleJson())];
        await h.engine.cacheTrip(started);
        await tester.pumpWidget(h.screen(entry.value));
        await settle(tester);
        if (entry.key == 'end trip') {
          // A charge row and a split payment are the widest rows.
          await tester.tap(find.byIcon(Icons.add).first);
          await tester.tap(find.byIcon(Icons.call_split));
          await settle(tester);
        }
        // Any overflow or exception fails the test with the widget at fault.
      });
    }
  }
}
