import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/core/api/json.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/api/owner_api.dart';
import 'package:taxcy_driver/core/api/owner_models.dart';

import 'support/fakes.dart';
import 'support/owner_fakes.dart';

void main() {
  group('Trip (staff fields)', () {
    test('parses the driver id, map points, cancellation fare and details', () {
      final trip = Trip.fromJson({
        ...tripJson(status: 'started', cancellationPending: true),
        'includedKm': 150,
        'cancellationFarePaise': 50000,
        'charges': [
          {
            'id': 'c1',
            'kind': 'toll',
            'amountPaise': 25000,
            'paidByDriver': true,
            'mediaId': null,
            'note': 'Khalapur',
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
            'reference': 'UPI123',
            'collectedAt': '2026-10-09T05:00:00.000Z',
          },
        ],
      });
      expect(trip.driverId, '0199c7a2-0000-7000-8000-0000000000dd');
      expect(trip.fromPoint?.lat, 18.5286);
      expect(trip.toPoint, isNull);
      expect(trip.cancellationFarePaise, 50000);
      expect(trip.charges.single.enteredRole, 'driver');
      expect(trip.collections.single.collectedAt, isNotNull);
      final request = trip.cancellationRequest!;
      expect(request.requestedRole, 'driver');
      expect(request.createdAt, DateTime.utc(2026, 10, 9, 4));
      // The richer trip still round-trips through the driver's cache format.
      expect(Trip.fromJson(trip.toJson()).toJson(), trip.toJson());
    });

    test('knows the km driven and how far over the included km', () {
      JsonMap reading(int km) => {
        'id': 'r$km',
        'typedKm': km,
        'ocrKm': null,
        'mediaId': 'm$km',
        'capturedAt': '2026-10-09T03:00:00.000Z',
      };
      final trip = Trip.fromJson({
        ...tripJson(status: 'ended'),
        'includedKm': 150,
        'startOdometer': reading(1000),
        'endOdometer': reading(1190),
      });
      expect(trip.drivenKm, 190);
      expect(trip.kmOverIncluded, 40);
    });
  });

  test(
    'Vehicle parses the fleet fields, and old cached vehicles still parse',
    () {
      final v = Vehicle.fromJson(vehicleJson(status: 'inactive'));
      expect(v.make, 'Toyota');
      expect(v.year, 2022);
      expect(v.isActive, isFalse);
      final cached = Vehicle.fromJson({
        'id': vehicleId,
        'registrationNo': 'MH12AB1234',
        'model': 'Innova',
        'fuelType': 'diesel',
        'lastOdometerKm': null,
      });
      expect(cached.status, 'active');
      expect(cached.make, '');
    },
  );

  test('VehicleModel', () {
    final m = VehicleModel.fromJson({
      'id': 'm1',
      'make': 'Maruti',
      'model': 'Ertiga',
      'fuelType': 'petrol_cng',
    });
    expect(m.fuelType, 'petrol_cng');
  });

  group('PayRule', () {
    test('parses each kind and writes only the fields that kind uses', () {
      final percent = PayRule.fromJson(payRuleJson());
      expect(percent.percent, 20);
      expect(percent.base, 'quoted');
      expect(percent.toJson(), {
        'kind': 'percent_of_fare',
        'allowanceToDriver': true,
        'percent': 20.0,
        'base': 'quoted',
      });
      final perTrip = PayRule.fromJson(payRuleJson(kind: 'per_trip'));
      expect(perTrip.toJson(), {
        'kind': 'per_trip',
        'allowanceToDriver': false,
        'amountPaise': 30000,
      });
      expect(PayRule.fromJson(perTrip.toJson()), perTrip);
    });

    test('validity follows the contract', () {
      expect(
        PayRule.defaultsFor('per_km', allowanceToDriver: false).isValid,
        isTrue,
      );
      expect(
        const PayRule(
          kind: 'percent_of_fare',
          allowanceToDriver: false,
          percent: 120,
          base: 'quoted',
        ).isValid,
        isFalse,
      );
      expect(
        const PayRule(kind: 'per_trip', allowanceToDriver: false).isValid,
        isFalse,
      );
    });
  });

  test('Driver, with and without its own pay rule', () {
    final d = Driver.fromJson(
      driverJson(payRule: payRuleJson(kind: 'per_trip')),
    );
    expect(d.payRule?.amountPaise, 30000);
    expect(d.isActive, isTrue);
    expect(Driver.fromJson(driverJson()).payRule, isNull);
  });

  test('Member', () {
    final m = Member.fromJson(memberJson());
    expect(m.isManager, isTrue);
    expect(m.isOwner, isFalse);
    expect(m.status, 'active');
  });

  test('FleetDocument keeps calendar dates as written', () {
    final d = FleetDocument.fromJson(documentJson());
    expect(d.expiresOn, '2026-10-15');
    expect(d.validFrom, '2025-10-16');
    expect(d.daysLeft, 5);
  });

  test('AuditSettings round-trips and checks ranges', () {
    final s = AuditSettings.fromJson(auditSettingsJson());
    expect(s.docAlertDays, [30, 7, 1]);
    expect(s.isValid, isTrue);
    expect(AuditSettings.fromJson(s.toJson()).toJson(), s.toJson());
    final bad = AuditSettings.fromJson({
      ...auditSettingsJson(),
      'fuelKSigma': 9,
    });
    expect(bad.isValid, isFalse);
  });

  test('TripEvent, TripRoute and DistanceCheck', () {
    final e = TripEvent.fromJson(eventJson(type: 'trip.started', role: null));
    expect(e.actorRole, isNull);
    expect(e.eventType, 'trip.started');
    final r = TripRoute.fromJson(routeJson());
    expect(r.points, hasLength(2));
    expect(r.droppedInaccurate, 2);
    final c = DistanceCheck.fromJson(distanceCheckJson());
    expect(c.gpsKm, 150.4);
    expect(c.maxGapSeconds, 240);
    expect(c.result, 'flagged');
  });

  test('FuelFill, FuelCycle and VehicleFuelAudit', () {
    final f = FuelFill.fromJson(fuelFillJson(voidedAt: '2026-10-10T05:00:00Z'));
    expect(f.voided, isTrue);
    expect(f.odometer.typedKm, 48000);
    expect(f.ocrCostPaise, 360000);
    final a = VehicleFuelAudit.fromJson(vehicleAuditJson());
    expect(a.baselineMean, 14.2);
    expect(a.baselineCycles, 3);
    expect(a.cycles.last.verdict, 'flagged');
    expect(a.isCost, isFalse);
    final empty = VehicleFuelAudit.fromJson({
      ...vehicleAuditJson(cycles: []),
      'baseline': null,
    });
    expect(empty.baselineMean, isNull);
  });

  group('Alert', () {
    test('parses every message key into its typed message', () {
      final types = {
        'fuel_efficiency_low': isA<FuelEfficiencyLowMessage>(),
        'fuel_cost_high': isA<FuelCostHighMessage>(),
        'odo_gps_mismatch': isA<OdoGpsMismatchMessage>(),
        'document_expiring': isA<DocumentExpiryMessage>().having(
          (m) => m.expired,
          'expired',
          false,
        ),
        'document_expired': isA<DocumentExpiryMessage>().having(
          (m) => m.expired,
          'expired',
          true,
        ),
        'cancellation_requested': isA<CancellationRequestedMessage>(),
      };
      for (final entry in types.entries) {
        final alert = Alert.fromJson(alertJson(kind: entry.key));
        expect(alert.message, entry.value, reason: entry.key);
      }
      final fuel =
          Alert.fromJson(alertJson()).message! as FuelEfficiencyLowMessage;
      expect(fuel.cycle.drivers, ['Ramesh Kumar', 'Suresh Patil']);
      expect(fuel.extraCostPaise, 114000);
    });

    test('a null or unknown message falls back to the English text', () {
      expect(Alert.fromJson(alertJson(useMessage: false)).message, isNull);
      final future = Alert.fromJson(
        alertJson(
          message: {'key': 'something_new', 'params': <String, Object?>{}},
        ),
      );
      expect(future.message, isNull);
      expect(future.title, startsWith('English title'));
    });

    test('reads the false-alarm flag and whether it is still open', () {
      final a = Alert.fromJson({
        ...alertJson(status: 'acknowledged'),
        'data': {'falsePositive': true},
      });
      expect(a.falsePositive, isTrue);
      expect(a.isOpen, isTrue);
      expect(a.isFuel, isTrue);
    });

    test('a broken message names the field', () {
      final broken = alertJson();
      (broken['message']! as Map)['params'] = {'from': 1};
      expect(() => Alert.fromJson(broken), throwsA(isA<JsonShapeError>()));
    });
  });

  test('AlertSummary', () {
    final s = AlertSummary.fromJson({
      'openAlerts': {'info': 1, 'warning': 2, 'critical': 3},
      'openReviewItems': 4,
    });
    expect(s.openAlerts, 6);
    expect(s.openReviewItems, 4);
  });

  test('ReviewItem reads the reason code and trip from its context', () {
    final item = ReviewItem.fromJson(
      reviewItemJson(
        kind: 'implausible_efficiency',
        subjectType: 'fuel_cycle',
        context: {
          'reason': 'English reason',
          'reasonCode': 'distance_too_long',
          'tripId': 't1',
          'distanceKm': 3400,
        },
      ),
    );
    expect(item.reasonCode, 'distance_too_long');
    expect(item.reason, 'English reason');
    expect(item.tripId, 't1');
    expect(item.valueKind, isNull);
    expect(ReviewItem.fromJson(reviewItemJson()).valueKind, 'km');
    expect(
      ReviewItem.fromJson(reviewItemJson(subjectType: 'fuel_fill')).valueKind,
      'paise',
    );
  });

  test('SettlementSummary, SettlementDetail and every line item kind', () {
    final s = SettlementSummary.fromJson(
      settlementSummaryJson(status: 'settled'),
    );
    expect(s.isSettled, isTrue);
    expect(s.settledAt, isNotNull);
    final d = SettlementDetail.fromJson(settlementDetailJson());
    expect(d.summary.netPayablePaise, 210000);
    expect(d.payRule.kind, 'percent_of_fare');
    expect(d.lines.map((l) => l.item.runtimeType), [
      TripSettlementItem,
      ChargeSettlementItem,
      CollectionSettlementItem,
      FuelFillSettlementItem,
      Null,
    ]);
    expect(d.lines.last.originalDate, '2026-10-08');
    final charge = d.lines[1].item! as ChargeSettlementItem;
    expect(charge.trip?.route, 'Pune Station → Mumbai Airport T2');
    expect(SettlementItem.fromJson({'kind': 'something_new'}), isNull);
  });

  test('MediaUrl', () {
    final m = MediaUrl.fromJson({
      'url': 'http://s3.local/x.jpg',
      'expiresAt': '2026-10-10T05:00:00Z',
    });
    expect(m.url, 'http://s3.local/x.jpg');
  });

  test('TripFilter becomes the query string, leaving out unset filters', () {
    final filter = TripFilter(
      status: 'started',
      from: DateTime.utc(2026, 10, 8, 18, 30),
      limit: 50,
    );
    expect(filter.toQuery(), {
      'status': 'started',
      'from': '2026-10-08T18:30:00.000Z',
      'limit': '50',
    });
    expect(
      filter,
      TripFilter(
        status: 'started',
        from: DateTime.utc(2026, 10, 8, 18, 30),
        limit: 50,
      ),
    );
  });
}
