import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taxcy_driver/core/api/owner_models.dart';
import 'package:taxcy_driver/features/common/format.dart';
import 'package:taxcy_driver/features/owner/owner_text.dart';
import 'package:taxcy_driver/features/owner/settings_screen.dart';
import 'package:taxcy_driver/features/owner/trips/create_trip_screen.dart';
import 'package:taxcy_driver/features/owner/vehicles_screen.dart';
import 'package:taxcy_driver/l10n/app_localizations.dart';

import 'support/owner_fakes.dart';

final en = Fmt(lookupAppLocalizations(const Locale('en')));
final hi = Fmt(lookupAppLocalizations(const Locale('hi')));

Alert alert(String kind) => Alert.fromJson(alertJson(kind: kind));

void main() {
  setUpAll(initializeDateFormatting);

  group('alerts are worded from their message, in English', () {
    test('fuel_efficiency_low', () {
      final a = alert('fuel_efficiency_low');
      expect(
        alertTitle(en, a),
        'MH12AB1234 (Innova Crysta, diesel) used more fuel than usual',
      );
      expect(
        alertBody(en, a),
        'Between 1 Oct and 8 Oct it ran 620 km on 54.5 L of diesel, which is '
        '11.4 km/L. This car usually does about 14.6 km/L, so this is 22% '
        "worse than normal. That's roughly 12.0 L (about ₹1,140) more diesel "
        'than expected. Fills in this period were logged by Ramesh Kumar and '
        'Suresh Patil. Check the receipts and odometer photos.',
      );
    });

    test('fuel_cost_high', () {
      final a = alert('fuel_cost_high');
      expect(
        alertTitle(en, a),
        'MH12CD5678 (Ertiga, petrol + CNG) cost more to run than usual',
      );
      expect(
        alertBody(en, a),
        'Between 1 Oct and 8 Oct it ran 500 km for ₹3,900 of fuel, which is '
        '₹7.80/km. This car usually costs about ₹6/km, so this is 30% more '
        'than normal. ₹1,500 of that was petrol. Fills in this period were '
        'logged by Vijay. Check whether the car was run on petrol '
        'unnecessarily, and check the receipts.',
      );
    });

    test('odo_gps_mismatch', () {
      final a = alert('odo_gps_mismatch');
      expect(
        alertTitle(en, a),
        'Trip on 9 Oct (Pune Station → Mumbai Airport T2, MH12AB1234) shows '
        'more km on the odometer than the GPS route',
      );
      expect(
        alertBody(en, a),
        "The odometer readings say 190 km, but the phone's GPS recorded 150 km. "
        'The odometer distance is 27% higher; the allowed difference is 10%. '
        'Check the start and end odometer photos.',
      );
    });

    test('document_expiring and document_expired', () {
      expect(
        alertTitle(en, alert('document_expiring')),
        'Insurance for MH12AB1234 expires in 5 days',
      );
      expect(
        alertBody(en, alert('document_expiring')),
        'Insurance for MH12AB1234 expires on 15 Oct 2026. Renew it and upload '
        'the new copy before then.',
      );
      expect(
        alertTitle(en, alert('document_expired')),
        'Pollution (PUC) for MH12AB1234 has expired',
      );
      expect(
        alertBody(en, alert('document_expired')),
        startsWith('Pollution (PUC) for MH12AB1234 expired on 1 Oct 2026.'),
      );
      final tomorrow = Alert.fromJson(
        alertJson(
          kind: 'document_expiring',
          message: {
            'key': 'document_expiring',
            'params': {
              'docType': 'driving_licence',
              'subjectKind': 'driver',
              'subject': 'Ramesh Kumar',
              'expiresOn': '2026-10-11',
              'daysLeft': 1,
            },
          },
        ),
      );
      expect(
        alertTitle(en, tomorrow),
        'Driving licence for Ramesh Kumar expires tomorrow',
      );
    });

    test('cancellation_requested', () {
      final a = alert('cancellation_requested');
      expect(
        alertTitle(en, a),
        'Cancellation requested for the trip from Pune Station',
      );
      expect(
        alertBody(en, a),
        'Ramesh Kumar asked to cancel this running trip: "Customer got off '
        'early". The odometer read 48,300 km. Approve (optionally with a '
        'cancellation fare) or reject it on the trip page.',
      );
    });
  });

  group('alerts in Hindi', () {
    test('every key is worded in Hindi, with Indian number formatting', () {
      for (final kind in alertMessages.keys) {
        final a = alert(kind);
        expect(alertTitle(hi, a), isNot(alertTitle(en, a)), reason: kind);
        expect(alertBody(hi, a), isNot(alertBody(en, a)), reason: kind);
        expect(alertBody(hi, a), isNot(contains('English')), reason: kind);
      }
      expect(
        alertTitle(hi, alert('fuel_efficiency_low')),
        'MH12AB1234 (Innova Crysta, डीज़ल) ने आम से ज़्यादा फ़्यूल खाया',
      );
      expect(
        alertBody(hi, alert('fuel_efficiency_low')),
        contains('54.5 लीटर डीज़ल में 620 किमी चली'),
      );
      expect(
        alertBody(hi, alert('fuel_efficiency_low')),
        contains('Ramesh Kumar और Suresh Patil'),
      );
      expect(
        alertTitle(hi, alert('document_expiring')),
        'MH12AB1234 का बीमा 5 दिन में खत्म हो रहा है',
      );
      expect(
        alertBody(hi, alert('cancellation_requested')),
        contains('ओडोमीटर 48,300 किमी था'),
      );
    });

    test('an alert without a message shows the English text', () {
      final old = Alert.fromJson(alertJson(useMessage: false));
      expect(alertTitle(hi, old), 'English title for fuel_efficiency_low');
      expect(alertBody(hi, old), 'English explanation for fuel_efficiency_low');
    });
  });

  group('settlement lines are worded from their item', () {
    final detail = SettlementDetail.fromJson(settlementDetailJson());
    List<String> texts(Fmt f) => [
      for (final line in detail.lines) settlementLineText(f, line),
    ];

    test('in English', () {
      expect(texts(en), [
        'Pune Station → Mumbai Airport T2 (MH12AB1234)',
        'Toll, paid by the driver · Pune Station → Mumbai Airport T2',
        'Cash payment',
        'Diesel 20.0 L, ₹1,800, Driver paid cash',
        // No item: the server's English description.
        'Late parking from 8 Oct',
      ]);
      expect(
        [
          for (final line in detail.lines)
            settlementLineLabel(en.l, line.refType),
        ],
        ['Trip', 'Charge', 'Payment', 'Fuel', 'Late item'],
      );
    });

    test('in Hindi', () {
      expect(texts(hi), [
        'Pune Station → Mumbai Airport T2 (MH12AB1234)',
        'टोल, ड्राइवर ने दिया · Pune Station → Mumbai Airport T2',
        'नकद भुगतान',
        'डीज़ल 20.0 लीटर, ₹1,800, ड्राइवर ने नकद दिया',
        'Late parking from 8 Oct',
      ]);
    });

    test('extra fare, billed charges, references and cancelled trips', () {
      SettlementLine line(Map<String, Object?> item) =>
          SettlementLine.fromJson({
            'refType': 'trip_charge',
            'refId': 'x',
            'amountPaise': 1,
            'description': 'fallback',
            'item': item,
            'originalDate': null,
          });
      expect(
        settlementLineText(
          en,
          line({
            'kind': 'charge',
            'chargeKind': 'night_charge',
            'amountPaise': 30000,
            'paidByDriver': false,
            'trip': null,
          }),
        ),
        'Night charge, extra fare',
      );
      expect(
        settlementLineText(
          en,
          line({
            'kind': 'charge',
            'chargeKind': 'parking',
            'amountPaise': 5000,
            'paidByDriver': false,
            'trip': null,
          }),
        ),
        'Parking, billed to the customer',
      );
      expect(
        settlementLineText(
          en,
          line({
            'kind': 'collection',
            'method': 'upi',
            'amountPaise': 5000,
            'reference': 'UPI42',
            'trip': null,
          }),
        ),
        'UPI payment (ref UPI42)',
      );
      expect(
        settlementLineText(
          hi,
          line({
            'kind': 'trip',
            'trip': {'from': 'Pune', 'to': null, 'registrationNo': null},
            'cancelled': true,
          }),
        ),
        'Pune · रद्द',
      );
    });
  });

  test('pay rules and who owes whom', () {
    expect(
      payRuleText(en, PayRule.fromJson(payRuleJson())),
      '20% of quoted fare + driver allowance',
    );
    expect(
      payRuleText(en, PayRule.fromJson(payRuleJson(kind: 'per_trip'))),
      '₹300 per trip',
    );
    expect(
      payRuleText(hi, PayRule.fromJson(payRuleJson())),
      'तय किराए का 20% + ड्राइवर भत्ता',
    );
    expect(netPayableText(en, 210000), 'Driver pays you ₹2,100');
    expect(netPayableText(en, -5000), 'You pay the driver ₹50');
    expect(netPayableText(hi, 0), 'कुछ लेना-देना नहीं');
  });

  test('review items: reasons by code, values in their unit', () {
    final cycle = ReviewItem.fromJson(
      reviewItemJson(
        kind: 'implausible_efficiency',
        subjectType: 'fuel_cycle',
        context: {'reason': 'English', 'reasonCode': 'no_fuel'},
      ),
    );
    expect(
      reviewReasonText(en.l, cycle),
      'No fuel was recorded between the two full-tank fills.',
    );
    expect(reviewReasonText(hi.l, cycle), hi.l.reasonNoFuel);
    final unknown = ReviewItem.fromJson(
      reviewItemJson(context: {'reason': 'English only', 'reasonCode': 'new'}),
    );
    expect(reviewReasonText(hi.l, unknown), 'English only');
    final odometer = ReviewItem.fromJson(reviewItemJson());
    expect(reviewValueText(en, odometer, '48210'), '48,210 km');
    final receipt = ReviewItem.fromJson(
      reviewItemJson(subjectType: 'fuel_fill', typed: '380000'),
    );
    expect(reviewValueText(en, receipt, '380000'), '₹3,800');
  });

  test('IST days', () {
    expect(istDate(DateTime.utc(2026, 10, 9, 19)), '2026-10-10');
    expect(istDate(DateTime.utc(2026, 10, 9, 18, 29)), '2026-10-09');
    final (from, to) = istDayRange('2026-10-10');
    expect(from, DateTime.utc(2026, 10, 9, 18, 30));
    expect(to, DateTime.utc(2026, 10, 10, 18, 30));
  });

  test('phones and registrations', () {
    expect(normalizeIndianMobile('98123 45678'), '+919812345678');
    expect(normalizeIndianMobile('+91 98123-45678'), '+919812345678');
    expect(normalizeIndianMobile('12345'), isNull);
    expect(formatPhone('+919812345678'), '+91 98123 45678');
    expect(normalizeRegistration('mh 12 ab-1234'), 'MH12AB1234');
    expect(normalizeRegistration('MH'), isNull);
    expect(formatRegistration('MH12AB1234'), 'MH 12 AB 1234');
  });

  group('new trip body', () {
    final start = DateTime.utc(2026, 10, 11, 4);
    NewTripInput input({
      String to = 'Mumbai',
      String fare = '3,500',
      String km = '',
      String? vehicle,
      String? driver,
      DateTime? end,
      String type = 'one_way',
    }) => NewTripInput(
      tripType: type,
      fromText: ' Pune ',
      toText: to,
      start: start,
      end: end ?? start.add(const Duration(hours: 4)),
      fare: fare,
      includedKm: km,
      customerName: 'Anita',
      customerPhone: '98222 22222',
      vehicleId: vehicle,
      driverId: driver,
    );

    test('builds the API body', () {
      final r = newTripBody(
        en.l,
        input(km: '300', vehicle: vehicleId, driver: driverId),
        id: 'id-1',
      );
      expect(r.problem, isNull);
      expect(r.body, {
        'id': 'id-1',
        'tripType': 'one_way',
        'from': {'text': 'Pune'},
        'to': {'text': 'Mumbai'},
        'scheduledStartAt': '2026-10-11T04:00:00.000Z',
        'scheduledEndAt': '2026-10-11T08:00:00.000Z',
        'quotedFarePaise': 350000,
        'includedKm': 300,
        'customer': {'name': 'Anita', 'phone': '+919822222222'},
        'vehicleId': vehicleId,
        'driverId': driverId,
      });
      final local = newTripBody(
        en.l,
        input(type: 'local_rental', to: ''),
        id: 'x',
      );
      expect(local.body!.containsKey('to'), isFalse);
    });

    test('reports the first problem in the user’s language', () {
      expect(
        newTripBody(en.l, input(to: ''), id: 'x').problem,
        'Enter the drop',
      );
      expect(
        newTripBody(en.l, input(fare: 'abc'), id: 'x').problem,
        'Enter the fare in ₹',
      );
      expect(
        newTripBody(en.l, input(km: '0'), id: 'x').problem,
        'Enter km, or leave empty',
      );
      expect(
        newTripBody(en.l, input(end: start), id: 'x').problem,
        'The trip must end after it starts',
      );
      expect(
        newTripBody(hi.l, input(vehicle: vehicleId), id: 'x').problem,
        'गाड़ी और ड्राइवर दोनों चुनें, या कोई भी नहीं',
      );
    });
  });

  test('vehicle body and settings parsing', () {
    final values = {
      'registrationNo': 'mh 12 ab 1234',
      'make': 'Toyota',
      'model': 'Innova',
      'year': '2022',
      'odometer': '',
    };
    final r = vehicleBody(
      (k) => values[k]!,
      registrationInvalid: 'bad reg',
      requiredText: 'required',
      fuelType: 'diesel',
      status: 'inactive',
    );
    expect(r.body, {
      'registrationNo': 'MH12AB1234',
      'make': 'Toyota',
      'model': 'Innova',
      'fuelType': 'diesel',
      'year': 2022,
      'status': 'inactive',
    });
    values['registrationNo'] = 'x';
    expect(
      vehicleBody(
        (k) => values[k]!,
        registrationInvalid: 'bad reg',
        requiredText: 'required',
        fuelType: 'diesel',
      ).problem,
      'bad reg',
    );
    expect(parseDayList('30, 7,1'), [30, 7, 1]);
    expect(parseDayList('30, x'), isNull);
  });

  test('labels exist for every status, kind and role in both languages', () {
    for (final f in [en, hi]) {
      final l = f.l;
      for (final k in Alert.kinds) {
        expect(alertKindLabel(l, k), isNot(k));
      }
      for (final s in ['info', 'warning', 'critical']) {
        expect(severityLabel(l, s), isNot(s));
      }
      for (final r in ['owner', 'manager', 'driver']) {
        expect(roleLabel(l, r), isNot(r));
      }
      for (final d in [
        ...FleetDocument.vehicleTypes,
        ...FleetDocument.driverTypes,
      ]) {
        expect(docTypeLabel(l, d), isNot(d));
      }
      for (final e in [
        'trip.created',
        'trip.assigned',
        'trip.started',
        'trip.ended',
        'trip.cancellation_requested',
        'trip.cancellation_approved',
        'trip.settled',
      ]) {
        expect(eventLabel(l, e), isNot(contains('_')));
      }
    }
  });
}
