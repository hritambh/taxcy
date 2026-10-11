import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/app/app.dart';
import 'package:taxcy_driver/app/providers.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/repositories/trips_repository.dart';
import 'package:taxcy_driver/core/sync/sync_engine.dart';
import 'package:taxcy_driver/features/common/widgets.dart';
import 'package:taxcy_driver/features/fuel/fuel_fill_screen.dart';
import 'package:taxcy_driver/features/trips/trip_forms.dart';
import 'package:taxcy_driver/features/trips/trips_screen.dart';
import 'package:taxcy_driver/l10n/app_localizations.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  test('reports the platform it runs on at login', () {
    expect(devicePlatform, 'android');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(devicePlatform, 'ios');
  });

  testWidgets('login with an SMS code: phone → code → signed in as a driver', (
    tester,
  ) async {
    final h = await Harness.create();
    addTearDown(h.dispose);
    await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
    await settle(tester);
    await tester.tap(find.byKey(const Key('use-sms')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('phone-field')), '12345');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Enter your 10-digit mobile number'), findsOneWidget);
    expect(h.auth.names, isNot(contains('requestOtp')));

    await tester.enterText(find.byKey(const Key('phone-field')), '9000000011');
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(h.auth.calls.last.args['phone'], '+919000000011');
    expect(find.byKey(const Key('code-field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('code-field')), '482913');
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(h.auth.names.last, 'verifyOtp');
    expect(find.text('My trips'), findsOneWidget);
    expect((await h.sessions.load())?.isDriver, isTrue);
  });

  testWidgets('a member with no role in the fleet is told to ask the owner', (
    tester,
  ) async {
    final h = await Harness.create(
      session: Session.fromJson(sessionJson(roles: [])),
    );
    addTearDown(h.dispose);
    await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
    await settle(tester);
    expect(find.text('Not part of a fleet yet'), findsOneWidget);
  });

  testWidgets('trips are grouped: on the road, today, upcoming, recent', (
    tester,
  ) async {
    final h = await Harness.create();
    addTearDown(h.dispose);
    final now = DateTime.now();
    final trips = [
      tripJson(id: 'a0000000-0000-4000-8000-000000000001', status: 'started'),
      tripJson(
        id: 'a0000000-0000-4000-8000-000000000002',
        scheduledStartAt: now.add(const Duration(minutes: 5)),
      ),
      tripJson(
        id: 'a0000000-0000-4000-8000-000000000003',
        scheduledStartAt: now.add(const Duration(days: 3)),
      ),
      tripJson(id: 'a0000000-0000-4000-8000-000000000004', status: 'ended'),
    ];
    for (final t in trips) {
      await h.engine.cacheTrip(Trip.fromJson(t));
    }
    final grouped = groupTrips([
      for (final t in trips) TripView(Trip.fromJson(t)),
    ]);
    expect(grouped.keys, TripGroup.values);

    await tester.pumpWidget(h.screen(const TripsScreen()));
    await settle(tester);
    // "On the road" is both a section header and the started trip's status chip.
    expect(find.text('On the road'), findsNWidgets(2));
    for (final label in ['Today', 'Upcoming', 'Recent']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Pune Station → Mumbai Airport T2'), findsNWidgets(4));
  });

  group('log fuel picks the vehicle from the driver\'s trips', () {
    const vehicle = Vehicle(
      id: '0199c7a2-0000-7000-8000-0000000000aa',
      registrationNo: 'MH12AB1234',
      model: 'Innova Crysta',
      fuelType: 'diesel',
    );

    testWidgets('a running trip fixes the vehicle', (tester) async {
      final h = await Harness.create();
      addTearDown(h.dispose);
      h.api.vehicleList = const [vehicle];
      await h.engine.cacheTrip(Trip.fromJson(tripJson(status: 'started')));

      await tester.pumpWidget(h.screen(const FuelFillScreen()));
      await settle(tester);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.text('MH12AB1234 · Innova Crysta'), findsOneWidget);
      expect(
        find.text('From your trip: Pune Station → Mumbai Airport T2'),
        findsOneWidget,
      );
    });

    testWidgets('with no trip, the driver is told why', (tester) async {
      final h = await Harness.create();
      addTearDown(h.dispose);
      h.api.vehicleList = const [vehicle];

      await tester.pumpWidget(h.screen(const FuelFillScreen()));
      await settle(tester);
      expect(
        find.textContaining('No vehicle is assigned to you'),
        findsOneWidget,
      );
      expect(find.text('Save fuel fill'), findsNothing);
    });
  });

  testWidgets(
    'end trip lists the charges and fuel added during the trip; charges count towards the fare',
    (tester) async {
      final h = await Harness.create();
      addTearDown(h.dispose);
      final trip = Trip.fromJson({
        ...tripJson(status: 'started'),
        'charges': [
          {
            'id': '0199c7a2-0000-7000-8000-0000000000c9',
            'kind': 'toll',
            'amountPaise': 25000,
            'paidByDriver': true,
            'mediaId': null,
            'note': null,
            'voidedAt': null,
          },
        ],
        'fuelFills': [
          {
            'id': '0199c7a2-0000-7000-8000-0000000000f9',
            'fuel': 'diesel',
            'quantityMilli': 20000,
            'costPaise': 180000,
            'paidBy': 'driver_cash',
            'isFullTank': false,
            'filledAt': '2026-10-10T06:00:00.000Z',
          },
        ],
      });

      await tester.pumpWidget(h.screen(EndTripScreen(trip: trip)));
      await settle(tester);
      expect(find.text('Toll'), findsOneWidget);
      expect(
        find.text(
          'Added during the trip · Paid by you · paid back in settlement',
        ),
        findsOneWidget,
      );
      expect(find.text('Fare ₹3,500 + tolls & expenses ₹250'), findsOneWidget);
      // ₹3,500 quoted + ₹250 toll; fuel is the owner's cost, not the customer's.
      expect(find.text('Customer paid · expected ₹3,750'), findsOneWidget);
      expect(find.text('Diesel 20.0 L'), findsOneWidget);
      expect(find.textContaining('₹1,800 of fuel paid by you'), findsOneWidget);
    },
  );

  testWidgets('end trip warns when the km go beyond the included km', (
    tester,
  ) async {
    final h = await Harness.create();
    addTearDown(h.dispose);
    final trip = Trip.fromJson({
      ...tripJson(status: 'started'),
      'includedKm': 150,
    });
    await tester.pumpWidget(h.screen(EndTripScreen(trip: trip)));
    await settle(tester);
    expect(find.byKey(const Key('km-over-included')), findsNothing);
    // Started at 48,210 km: 48,400 is 190 km, 40 over.
    await tester.enterText(find.byKey(const Key('end-km')), '48400');
    await tester.pump();
    expect(
      find.text(
        '40 km over the 150 km included in the fare. Add an extra km charge below.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'start trip needs an odometer photo and a reading, then queues offline',
    (tester) async {
      final h = await Harness.create();
      addTearDown(h.dispose);
      final trip = Trip.fromJson(tripJson());
      await h.engine.cacheTrip(trip);
      await tester.pumpWidget(
        h.screen(Builder(builder: (_) => StartTripScreen(trip: trip))),
      );

      await tester.tap(find.byKey(const Key('confirm-start')));
      await tester.pump();
      expect(find.text('Take a photo of the odometer'), findsOneWidget);
      expect(find.text('Enter the odometer reading in km'), findsOneWidget);

      await tester.tap(find.text('Take photo'));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('odometer-km')), '48210');
      await tester.tap(find.byKey(const Key('confirm-start')));
      await settle(tester);

      final pending = await h.engine.outbox.pending();
      expect(pending.map((i) => i.kind), ['media', 'trip.command']);
      final cached = await (h.db.select(h.db.cachedTrips)).getSingle();
      expect(cached.status, 'started');
    },
  );

  group('sync status bar', () {
    test('labels', () {
      SyncStatus s({bool online = true, int pending = 0}) => SyncStatus(
        online: online,
        pending: pending,
        attention: 0,
        syncing: false,
      );
      final en = lookupAppLocalizations(const Locale('en'));
      expect(SyncStatusBar.label(en, s()), 'Synced');
      expect(SyncStatusBar.label(en, s(pending: 3)), '3 pending');
      expect(SyncStatusBar.label(en, s(online: false)), 'Offline');
      expect(
        SyncStatusBar.label(en, s(online: false, pending: 2)),
        'Offline · 2 saved on phone',
      );
      final hi = lookupAppLocalizations(const Locale('hi'));
      expect(SyncStatusBar.label(hi, s()), 'सिंक हो गया');
      expect(
        SyncStatusBar.label(hi, s(online: false, pending: 2)),
        'ऑफ़लाइन · 2 फ़ोन में सेव',
      );
    });

    testWidgets('shows pending writes and goes offline when sync fails', (
      tester,
    ) async {
      final h = await Harness.create();
      addTearDown(h.dispose);
      await tester.pumpWidget(h.screen(const Scaffold(body: SyncStatusBar())));
      await settle(tester);
      expect(find.text('Synced'), findsOneWidget);

      h.api.offline = true;
      await h.engine.outbox.enqueue('fuel.fill', {
        'body': <String, Object?>{'id': 'f1'},
      });
      await tester.runAsync(h.engine.syncNow);
      await settle(tester);
      expect(find.text('Offline · 1 saved on phone'), findsOneWidget);
    });
  });
}
