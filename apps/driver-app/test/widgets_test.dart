import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/app/app.dart';
import 'package:taxcy_driver/app/providers.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/auth/session_store.dart';
import 'package:taxcy_driver/core/repositories/trips_repository.dart';
import 'package:taxcy_driver/core/sync/sync_engine.dart';
import 'package:taxcy_driver/features/common/widgets.dart';
import 'package:taxcy_driver/features/trips/trip_forms.dart';
import 'package:taxcy_driver/features/trips/trips_screen.dart';

import 'support/fakes.dart';

class Harness {
  Harness({Session? session}) : sessions = InMemorySessionStore(session);
  final db = memoryDb();
  final api = FakeApi();
  final InMemorySessionStore sessions;
  late final engine = SyncEngine(
    db: db,
    api: api,
    readPhoto: (_) async => Uint8List(0),
    deviceId: sessions.deviceId,
  );

  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      apiProvider.overrideWithValue(api),
      sessionStoreProvider.overrideWithValue(sessions),
      syncEngineProvider.overrideWithValue(engine),
      backgroundWorkProvider.overrideWithValue(false),
      photoStoreProvider.overrideWithValue(MemoryPhotoStore()),
      photoCaptureProvider.overrideWithValue(
        (context, kind) async => fakePhoto('captured-$kind', kind: kind),
      ),
    ],
    child: child,
  );

  Future<void> dispose() => db.close();
}

/// Lets real async work (drift queries, stream emissions) run, then rebuilds.
/// pumpAndSettle alone can't: drift completes outside the test's fake clock, and
/// screens show a spinner (an endless animation) until it does.
Future<void> settle(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  test('reports the platform it runs on at login', () {
    expect(devicePlatform, 'android');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(devicePlatform, 'ios');
  });

  testWidgets('login: phone → code → signed in as a driver', (tester) async {
    final h = Harness();
    addTearDown(h.dispose);
    await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
    await settle(tester);

    await tester.enterText(find.byKey(const Key('phone-field')), '12345');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Enter your 10-digit mobile number'), findsOneWidget);
    expect(h.api.names, isEmpty);

    await tester.enterText(find.byKey(const Key('phone-field')), '9000000011');
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(h.api.calls.single.args['phone'], '+919000000011');
    expect(find.byKey(const Key('code-field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('code-field')), '482913');
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(h.api.names.last, 'verifyOtp');
    expect(find.text('My trips'), findsOneWidget);
    expect((await h.sessions.load())?.isDriver, isTrue);
  });

  testWidgets(
    'an owner without a driver role is told this app is for drivers',
    (tester) async {
      final h = Harness(
        session: Session.fromJson(sessionJson(roles: ['owner'])),
      );
      addTearDown(h.dispose);
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.text('This app is for drivers'), findsOneWidget);
    },
  );

  testWidgets('trips are grouped: on the road, today, upcoming, recent', (
    tester,
  ) async {
    final h = Harness();
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
    expect(grouped.keys, ['On the road', 'Today', 'Upcoming', 'Recent']);

    await tester.pumpWidget(h.wrap(const MaterialApp(home: TripsScreen())));
    await settle(tester);
    // "On the road" is both a section header and the started trip's status chip.
    expect(find.text('On the road'), findsNWidgets(2));
    for (final label in ['Today', 'Upcoming', 'Recent']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Pune Station → Mumbai Airport T2'), findsNWidgets(4));
  });

  testWidgets(
    'start trip needs an odometer photo and a reading, then queues offline',
    (tester) async {
      final h = Harness();
      addTearDown(h.dispose);
      final trip = Trip.fromJson(tripJson());
      await h.engine.cacheTrip(trip);
      await tester.pumpWidget(
        h.wrap(
          MaterialApp(
            home: Builder(builder: (_) => StartTripScreen(trip: trip)),
          ),
        ),
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
      expect(SyncStatusBar.label(s()), 'Synced');
      expect(SyncStatusBar.label(s(pending: 3)), '3 pending');
      expect(SyncStatusBar.label(s(online: false)), 'Offline');
      expect(
        SyncStatusBar.label(s(online: false, pending: 2)),
        'Offline · 2 saved on phone',
      );
    });

    testWidgets('shows pending writes and goes offline when sync fails', (
      tester,
    ) async {
      final h = Harness();
      addTearDown(h.dispose);
      await tester.pumpWidget(
        h.wrap(const MaterialApp(home: Scaffold(body: SyncStatusBar()))),
      );
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
