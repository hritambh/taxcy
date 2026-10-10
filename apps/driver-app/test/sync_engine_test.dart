import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/core/api/api.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/db/database.dart';
import 'package:taxcy_driver/core/repositories/fuel_repository.dart';
import 'package:taxcy_driver/core/repositories/trips_repository.dart';
import 'package:taxcy_driver/core/sync/outbox.dart';
import 'package:taxcy_driver/core/sync/sync_engine.dart';

import 'support/fakes.dart';

const tripId = '0199c7a2-0000-7000-8000-000000000001';

void main() {
  late AppDatabase db;
  late FakeApi api;
  late SyncEngine engine;
  late TripsRepository trips;
  late DateTime now;

  setUp(() async {
    db = memoryDb();
    api = FakeApi();
    now = DateTime.utc(2026, 10, 9, 4);
    engine = SyncEngine(
      db: db,
      api: api,
      readPhoto: (_) async => Uint8List.fromList([1, 2, 3]),
      deviceId: () async => 'device-1',
      now: () => now,
    );
    trips = TripsRepository(db, engine, now: () => now);
    await engine.cacheTrip(Trip.fromJson(tripJson()));
  });

  tearDown(() async {
    await engine.dispose();
    await db.close();
  });

  Future<Trip> cached() async => (await trips.trip(tripId))!.trip;

  group('outbox', () {
    test(
      'keeps writes in insertion order and survives as rows in SQLite',
      () async {
        final outbox = Outbox(db, now: () => now);
        await outbox.enqueue(OutboxKind.media, {'photoId': 'p1'});
        await outbox.enqueue(OutboxKind.tripCommand, {
          'tripId': tripId,
        }, tripId: tripId);
        await outbox.enqueue(OutboxKind.fuelFill, {
          'body': <String, Object?>{},
        });
        expect((await outbox.pending()).map((i) => i.kind), [
          OutboxKind.media,
          OutboxKind.tripCommand,
          OutboxKind.fuelFill,
        ]);
      },
    );

    test('dropping a trip’s writes keeps its fuel fills', () async {
      final outbox = Outbox(db, now: () => now);
      await outbox.enqueue(OutboxKind.fuelFill, {
        'body': <String, Object?>{},
      }, tripId: tripId);
      await outbox.enqueue(OutboxKind.tripCharge, {
        'tripId': tripId,
      }, tripId: tripId);
      expect(await outbox.dropTripWrites(tripId), 1);
      expect((await outbox.pending()).map((i) => i.kind), [
        OutboxKind.fuelFill,
      ]);
    });

    test('dropping a trip’s writes keeps its photo uploads', () async {
      final outbox = Outbox(db, now: () => now);
      await outbox.enqueue(OutboxKind.media, {'photoId': 'p1'}, tripId: tripId);
      await outbox.enqueue(OutboxKind.tripCommand, {
        'tripId': tripId,
      }, tripId: tripId);
      await outbox.enqueue(OutboxKind.tripCharge, {
        'tripId': tripId,
      }, tripId: tripId);
      expect(await outbox.dropTripWrites(tripId), 2);
      expect((await outbox.pending()).map((i) => i.kind), [OutboxKind.media]);
    });
  });

  group('fuel during a trip', () {
    const vehicle = Vehicle(
      id: '0199c7a2-0000-7000-8000-0000000000aa',
      registrationNo: 'MH12AB1234',
      model: 'Innova Crysta',
      fuelType: 'diesel',
    );

    test(
      'a fill shows on the trip at once and survives a pull until it has synced',
      () async {
        await engine.cacheTrip(Trip.fromJson(tripJson(status: 'started')));
        final fuel = FuelRepository(db, api, now: () => now);
        final id = await fuel.record(
          FuelFillInput(
            vehicle: vehicle,
            fuel: 'diesel',
            quantityMilli: 20000,
            costPaise: 180000,
            isFullTank: false,
            paidBy: 'driver_cash',
            odometerKm: 48300,
            odometerPhoto: fakePhoto('odo'),
            receipt: fakePhoto('receipt', kind: 'fuel_receipt'),
            tripId: tripId,
          ),
        );
        expect((await cached()).fuelFills.map((f) => f.id), [id]);

        // The server doesn't know the fill yet; its copy of the trip must not
        // replace the local one while the fill is queued.
        api.trips[tripId] = tripJson(status: 'started');
        await engine.pullTrips();
        expect((await cached()).fuelFills.map((f) => f.id), [id]);
      },
    );
  });

  group('local-first trip actions', () {
    test(
      'starting offline updates the trip immediately and queues photo then command',
      () async {
        await trips.start(
          await cached(),
          photo: fakePhoto('photo-1'),
          km: 48210,
        );
        final trip = await cached();
        expect(trip.status, 'started');
        expect(trip.allowedCommands, ['end', 'requestCancel']);
        expect((await engine.outbox.pending()).map((i) => i.kind), [
          OutboxKind.media,
          OutboxKind.tripCommand,
        ]);
      },
    );

    test(
      'the Dart state machine rejects an impossible action before anything is queued',
      () async {
        expect(
          () => trips.end(
            Trip.fromJson(tripJson()),
            photo: fakePhoto('p'),
            km: 1,
          ),
          throwsA(isA<LocalRejection>()),
        );
        expect(await engine.outbox.pending(), isEmpty);
      },
    );
  });

  group('sync engine', () {
    test(
      'uploads the photo (register, PUT, confirm) before sending the command that cites it',
      () async {
        await trips.start(
          await cached(),
          photo: fakePhoto('photo-1'),
          km: 48210,
        );
        await engine.syncNow();
        expect(api.names, [
          'registerMedia',
          'uploadBytes',
          'completeMedia',
          'trip.start',
          'myTrips',
        ]);
        expect(api.calls[0].args['deviceId'], 'device-1');
        final start = api.calls[3].args;
        expect(
          (start['body']! as Map<String, Object?>)['odometer'],
          containsPair('mediaId', 'photo-1'),
        );
        expect(await engine.outbox.pending(), isEmpty);
        final photo = await (db.select(
          db.photos,
        )..where((p) => p.id.equals('photo-1'))).getSingle();
        expect(photo.uploaded, isTrue);
      },
    );

    test(
      'retries a failed command with the same Idempotency-Key, after the backoff',
      () async {
        await trips.start(
          await cached(),
          photo: fakePhoto('photo-1'),
          km: 48210,
        );
        api.failNext(
          'trip.start',
          ApiException(status: 503, code: 'INTERNAL', message: 'down'),
        );
        await engine.syncNow();
        final firstKey = api.calls
            .firstWhere((c) => c.name == 'trip.start')
            .args['key'];
        expect(await engine.outbox.pending(), hasLength(1));

        // Too early: the backoff hasn't elapsed, so nothing is sent.
        api.calls.clear();
        now = now.add(const Duration(seconds: 1));
        await engine.syncNow();
        expect(api.names, isNot(contains('trip.start')));

        now = now.add(const Duration(seconds: 5));
        await engine.syncNow();
        final retry = api.calls.firstWhere((c) => c.name == 'trip.start');
        expect(retry.args['key'], firstKey);
        expect(await engine.outbox.pending(), isEmpty);
      },
    );

    test(
      'a failing write blocks the writes queued after it (strict order)',
      () async {
        await trips.start(
          await cached(),
          photo: fakePhoto('photo-1'),
          km: 48210,
        );
        api.failNext('registerMedia', FakeApi.network());
        await engine.syncNow();
        expect(api.names, ['registerMedia']);
        expect(engine.current.online, isFalse);
        expect(await engine.outbox.pending(), hasLength(2));
      },
    );

    test('drains everything once the phone is back online', () async {
      api.offline = true;
      final trip = await cached();
      await trips.start(trip, photo: fakePhoto('s'), km: 48210);
      await trips.addCharge(
        await cached(),
        const TripCharge(
          id: 'c1',
          kind: 'toll',
          amountPaise: 25000,
          paidByDriver: true,
        ),
      );
      await engine.syncNow();
      expect(engine.current.online, isFalse);
      expect(engine.current.pending, 3);

      api
        ..offline = false
        ..calls.clear();
      now = now.add(const Duration(minutes: 10));
      engine.setOnline(true);
      await engine.syncNow();
      expect(api.names.where((n) => n != 'myTrips'), [
        'registerMedia',
        'uploadBytes',
        'completeMedia',
        'trip.start',
        'addCharge',
      ]);
      expect(engine.current.pending, 0);
      expect(engine.current.online, isTrue);
    });

    test(
      'server wins on TRIP_CANCELLED: trip marked, later writes dropped, photo still sent, driver told',
      () async {
        final notices = <SyncNotice>[];
        engine.notices.listen(notices.add);
        await trips.start(
          await cached(),
          photo: fakePhoto('photo-1'),
          km: 48210,
        );
        await trips.addCharge(
          await cached(),
          const TripCharge(
            id: 'c1',
            kind: 'parking',
            amountPaise: 5000,
            paidByDriver: true,
          ),
        );
        api.failNext('trip.start', FakeApi.conflict('TRIP_CANCELLED'));
        await engine.syncNow();
        await pumpEventQueue();

        expect(
          api.names,
          containsAllInOrder([
            'registerMedia',
            'uploadBytes',
            'completeMedia',
            'trip.start',
          ]),
        );
        expect(api.names, isNot(contains('addCharge')));
        expect(await engine.outbox.pending(), isEmpty);
        final view = (await trips.trip(tripId))!;
        expect(view.trip.status, 'cancelled');
        expect(view.conflict, 'TRIP_CANCELLED');
        expect(notices.single.message, 'This trip was cancelled by the owner');
      },
    );

    test(
      'a validation error goes to "needs attention" and the queue moves on',
      () async {
        await engine.outbox.enqueue(OutboxKind.fuelFill, {
          'body': <String, Object?>{'id': 'f1'},
        });
        await engine.outbox.enqueue(OutboxKind.fuelFill, {
          'body': <String, Object?>{'id': 'f2'},
        });
        api.failNext(
          'recordFuelFill',
          ApiException(
            status: 422,
            code: 'FUEL_TYPE_MISMATCH',
            message: 'wrong fuel',
          ),
        );
        await engine.syncNow();
        expect(api.names.where((n) => n == 'recordFuelFill'), hasLength(2));
        expect(engine.current.attention, 1);
        expect(engine.current.pending, 0);
        final [item] = await engine.outbox.attentionItems();
        expect(item.lastError, contains('FUEL_TYPE_MISMATCH'));
      },
    );

    test(
      'uploads GPS in batches of at most 500, only after the start has synced',
      () async {
        await trips.start(
          await cached(),
          photo: fakePhoto('photo-1'),
          km: 48210,
        );
        for (var i = 0; i < 1200; i++) {
          await db
              .into(db.gpsPoints)
              .insert(
                GpsPointsCompanion.insert(
                  id: 'g$i',
                  tripId: tripId,
                  recordedAt: now.add(Duration(seconds: 15 * i)),
                  lat: 18.5 + i * 0.0001,
                  lng: 73.8,
                  accuracyM: const Value(8),
                ),
              );
        }
        api.failNext('trip.start', FakeApi.network());
        await engine.syncNow();
        expect(api.names, isNot(contains('uploadGps')));

        now = now.add(const Duration(minutes: 1));
        await engine.syncNow();
        final batches = api.calls
            .where((c) => c.name == 'uploadGps')
            .map((c) => c.args['count'])
            .toList();
        expect(batches, [500, 500, 200]);
        final left = await (db.select(
          db.gpsPoints,
        )..where((p) => p.uploaded.equals(false))).get();
        expect(left, isEmpty);
      },
    );

    test(
      'pulling trips keeps local changes that have not synced yet',
      () async {
        await trips.start(
          await cached(),
          photo: fakePhoto('photo-1'),
          km: 48210,
        );
        api
          ..trips[tripId] = tripJson()
          ..offline = false;
        await engine.pullTrips();
        expect((await cached()).status, 'started');
      },
    );

    test(
      'an active trip the server no longer returns was reassigned',
      () async {
        final notices = <SyncNotice>[];
        engine.notices.listen(notices.add);
        await engine.pullTrips();
        await pumpEventQueue();
        expect((await trips.trip(tripId))!.conflict, 'TRIP_REASSIGNED');
        expect(notices.single.code, 'TRIP_REASSIGNED');
      },
    );

    test('backoff doubles and is capped at five minutes', () {
      expect(backoffFor(1), const Duration(seconds: 2));
      expect(backoffFor(2), const Duration(seconds: 4));
      expect(backoffFor(5), const Duration(seconds: 32));
      expect(backoffFor(20), const Duration(minutes: 5));
    });
  });
}
