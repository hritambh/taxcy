import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/core/api/json.dart';
import 'package:taxcy_driver/core/api/models.dart';

import 'support/fakes.dart';

void main() {
  group('Trip', () {
    test('parses the API payload', () {
      final trip = Trip.fromJson(
        tripJson(status: 'started', cancellationPending: true),
      );
      expect(trip.status, 'started');
      expect(trip.routeLabel, 'Pune Station → Mumbai Airport T2');
      expect(trip.vehicle?.registrationNo, 'MH12AB1234');
      expect(trip.customerName, 'Anita Desai');
      expect(trip.startOdometer?.typedKm, 48210);
      expect(trip.cancellationPending, isTrue);
      expect(trip.allowedCommands, ['end', 'requestCancel']);
      expect(trip.quotedFarePaise, 350000);
    });

    test('survives a round trip through the local cache format', () {
      final original = Trip.fromJson(tripJson(status: 'started'));
      final again = Trip.fromJson(original.toJson());
      expect(again.toJson(), original.toJson());
    });

    test(
      'parses fuel filled during the trip, and tolerates caches without it',
      () {
        final trip = Trip.fromJson({
          ...tripJson(status: 'started'),
          'fuelFills': [
            {
              'id': 'f1',
              'fuel': 'cng',
              'quantityMilli': 8500,
              'costPaise': 76500,
              'paidBy': 'driver_cash',
              'isFullTank': true,
              'filledAt': '2026-10-10T06:00:00.000Z',
            },
          ],
        });
        expect(trip.fuelFills.single.unit, 'kg');
        expect(Trip.fromJson(trip.toJson()).fuelFills.single.costPaise, 76500);
        expect(
          Trip.fromJson(tripJson()..remove('fuelFills')).fuelFills,
          isEmpty,
        );
      },
    );

    test('reports the field that has the wrong shape', () {
      final broken = tripJson()..['quotedFarePaise'] = 'lots';
      expect(
        () => Trip.fromJson(broken),
        throwsA(
          isA<JsonShapeError>().having(
            (e) => e.message,
            'message',
            contains('quotedFarePaise'),
          ),
        ),
      );
    });
  });

  group('Session', () {
    test('knows whether the active membership is a driver', () {
      expect(Session.fromJson(sessionJson()).isDriver, isTrue);
      expect(Session.fromJson(sessionJson(roles: ['owner'])).isDriver, isFalse);
      expect(
        Session.fromJson(sessionJson(roles: ['owner', 'driver'])).isDriver,
        isTrue,
      );
    });

    test('round-trips through secure storage JSON', () {
      final session = Session.fromJson(sessionJson());
      final again = Session.fromJson(session.toJson());
      expect(again.refreshToken, session.refreshToken);
      expect(again.refreshTokenExpiresAt, session.refreshTokenExpiresAt);
      expect(again.memberships.single.orgName, 'Sharma Travels');
    });
  });

  test('UploadTicket and Vehicle parse', () {
    final ticket = UploadTicket.fromJson({
      'id': 'm1',
      'kind': 'odometer',
      'status': 'pending',
      'contentType': 'image/jpeg',
      'capturedAt': '2026-10-09T03:00:00.000Z',
      'uploadedAt': null,
      'uploadUrl': 'http://localhost:9000/taxcy-media/x?X-Amz-Signature=abc',
      'uploadHeaders': {'Content-Type': 'image/jpeg'},
      'uploadUrlExpiresAt': '2026-10-09T03:10:00.000Z',
    });
    expect(ticket.uploadHeaders, {'Content-Type': 'image/jpeg'});

    final bifuel = Vehicle.fromJson({
      'id': 'v1',
      'registrationNo': 'MH12CD5678',
      'make': 'Maruti Suzuki',
      'model': 'Ertiga',
      'year': 2022,
      'fuelType': 'petrol_cng',
      'vehicleModelId': null,
      'lastOdometerKm': 50000,
      'status': 'active',
      'createdAt': '2026-10-01T00:00:00.000Z',
    });
    expect(bifuel.allowedFuels, ['cng', 'petrol']);
  });
}
