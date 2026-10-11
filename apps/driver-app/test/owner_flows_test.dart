import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/app/app.dart';
import 'package:taxcy_driver/app/preferences.dart';
import 'package:taxcy_driver/core/api/api.dart';
import 'package:taxcy_driver/core/api/json.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/api/owner_models.dart';
import 'package:taxcy_driver/features/owner/alerts_screen.dart';
import 'package:taxcy_driver/features/owner/people_screens.dart';
import 'package:taxcy_driver/features/owner/review_screen.dart';
import 'package:taxcy_driver/features/owner/settings_screen.dart';
import 'package:taxcy_driver/features/owner/settlements_screen.dart';
import 'package:taxcy_driver/features/owner/trips/owner_trip_detail_screen.dart';
import 'package:taxcy_driver/features/owner/vehicles_screen.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/owner_fakes.dart';

Session session(List<String> roles) =>
    Session.fromJson(sessionJson(roles: roles));

/// A tall phone, so long owner pages fit without scrolling.
void phone(WidgetTester tester, {double width = 420}) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, 2400);
  addTearDown(tester.view.reset);
}

Future<Harness> owner(
  WidgetTester tester, {
  List<String> roles = const ['owner'],
  String language = 'en',
}) async {
  phone(tester);
  final h = await Harness.create(session: session(roles), language: language);
  addTearDown(h.dispose);
  return h;
}

/// Picks [item] from the dropdown that has [key].
Future<void> pick(WidgetTester tester, Key key, String item) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  group('who sees what', () {
    test('screens by role', () {
      expect(screensFor(session(['driver']), null), AppMode.driver);
      expect(screensFor(session(['owner']), null), AppMode.owner);
      expect(screensFor(session(['manager']), AppMode.driver), AppMode.owner);
      expect(screensFor(session(['owner', 'driver']), null), AppMode.driver);
      expect(
        screensFor(session(['owner', 'driver']), AppMode.owner),
        AppMode.owner,
      );
      expect(screensFor(session([]), null), isNull);
    });

    testWidgets('a driver gets their trips, with no owner mode', (
      tester,
    ) async {
      final h = await owner(tester, roles: ['driver']);
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.text('My trips'), findsOneWidget);
      expect(find.byKey(const Key('owner-nav')), findsNothing);
      await tester.tap(find.byKey(const Key('driver-menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('switch-to-owner')), findsNothing);
    });

    for (final role in ['owner', 'manager']) {
      testWidgets('an $role gets owner mode', (tester) async {
        final h = await owner(tester, roles: [role]);
        await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
        await settle(tester);
        expect(find.byKey(const Key('owner-nav')), findsOneWidget);
        expect(find.text('Today’s trips'), findsOneWidget);
        expect(find.text('My trips'), findsNothing);
      });
    }

    testWidgets('an owner-driver switches between driver and owner screens', (
      tester,
    ) async {
      final h = await owner(tester, roles: ['owner', 'driver']);
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.text('My trips'), findsOneWidget);

      await tester.tap(find.byKey(const Key('driver-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('switch-to-owner')));
      await settle(tester);
      expect(find.byKey(const Key('owner-nav')), findsOneWidget);
      expect(h.prefs.getString('app_mode_v1'), 'owner');

      await tester.tap(find.text('More'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('switch-to-driver')));
      await settle(tester);
      expect(find.text('My trips'), findsOneWidget);
      expect(h.prefs.getString('app_mode_v1'), 'driver');
    });

    testWidgets('an owner-driver who last used owner mode starts there', (
      tester,
    ) async {
      phone(tester);
      final h = await Harness.create(
        session: session(['owner', 'driver']),
        preferences: {'app_mode_v1': 'owner'},
      );
      addTearDown(h.dispose);
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.byKey(const Key('owner-nav')), findsOneWidget);
    });

    testWidgets('on a wide screen owner mode uses a side rail', (tester) async {
      phone(tester, width: 1280);
      final h = await Harness.create(session: session(['owner']));
      addTearDown(h.dispose);
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.byKey(const Key('owner-rail')), findsOneWidget);
      expect(find.byKey(const Key('owner-nav')), findsNothing);
    });

    testWidgets('owner mode is in Hindi too', (tester) async {
      final h = await owner(tester, language: 'hi');
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.text('डैशबोर्ड'), findsWidgets);
      expect(find.text('आज की ट्रिप'), findsOneWidget);
      // The open fuel alert, worded from its message code.
      expect(
        find.text(
          'MH12AB1234 (Innova Crysta, डीज़ल) ने आम से ज़्यादा फ़्यूल खाया',
        ),
        findsOneWidget,
      );
    });
  });

  group('managers', () {
    testWidgets('can see members but not invite or remove managers', (
      tester,
    ) async {
      final h = await owner(tester, roles: ['manager']);
      await tester.pumpWidget(h.screen(const MembersScreen()));
      await settle(tester);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.byKey(const Key('invite-manager')), findsNothing);
      expect(find.byIcon(Icons.person_remove), findsNothing);
    });

    testWidgets('see settings read-only', (tester) async {
      final h = await owner(tester, roles: ['manager']);
      await tester.pumpWidget(h.screen(const SettingsScreen()));
      await settle(tester);
      expect(find.byKey(const Key('settings-owner-only')), findsOneWidget);
      expect(find.byKey(const Key('save-thresholds')), findsNothing);
      expect(find.byKey(const Key('save-default-pay')), findsNothing);
      final field = tester.widget<TextField>(find.byKey(const Key('audit-k')));
      expect(field.enabled, isFalse);
    });

    testWidgets("can't change a driver's pay", (tester) async {
      final h = await owner(tester, roles: ['manager']);
      await tester.pumpWidget(
        h.screen(DriverScreen(driver: Driver.fromJson(driverJson()))),
      );
      await settle(tester);
      expect(find.byKey(const Key('only-owner-pay')), findsOneWidget);
      final box = tester.widget<CheckboxListTile>(
        find.byKey(const Key('pay-override')),
      );
      expect(box.onChanged, isNull);
      await tester.tap(find.byKey(const Key('driver-save')));
      await settle(tester);
      expect(h.owner.names, contains('updateDriver'));
      expect(h.owner.names, isNot(contains('setDriverPayRule')));
    });

    testWidgets('owners can change settings and pay', (tester) async {
      final h = await owner(tester);
      await tester.pumpWidget(h.screen(const SettingsScreen()));
      await settle(tester);
      expect(find.byKey(const Key('settings-owner-only')), findsNothing);
      await tester.enterText(find.byKey(const Key('audit-odo')), '12');
      await tester.tap(find.byKey(const Key('save-thresholds')));
      await settle(tester);
      expect(
        h.owner.last('updateAuditSettings').args['odoGpsTolerancePct'],
        12,
      );
      expect(
        find.text(
          'Saved. Fuel audits use the new thresholds from the next recompute.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('create a trip, then assign a vehicle and driver', (
    tester,
  ) async {
    final h = await owner(tester);
    await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
    await settle(tester);
    await tester.tap(find.text('Trips').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('owner-new-trip')));
    await settle(tester);

    await tester.tap(find.byKey(const Key('owner-create-trip')));
    await tester.pump();
    expect(find.text('Enter the pickup'), findsOneWidget);
    expect(h.owner.names, isNot(contains('createTrip')));

    await tester.enterText(find.byKey(const Key('owner-trip-from')), 'Pune');
    await tester.enterText(find.byKey(const Key('owner-trip-to')), 'Shirdi');
    await tester.enterText(find.byKey(const Key('owner-trip-fare')), '4500');
    await tester.enterText(find.byKey(const Key('owner-trip-km')), '300');
    await tester.tap(find.byKey(const Key('owner-create-trip')));
    await settle(tester);
    final body = h.owner.last('createTrip').args;
    expect(body['quotedFarePaise'], 450000);
    expect(body['includedKm'], 300);
    expect(body.containsKey('vehicleId'), isFalse);

    // On the new trip's page: assign it.
    expect(find.byKey(const Key('trip-assign')), findsOneWidget);
    await tester.tap(find.byKey(const Key('trip-assign')));
    await settle(tester);
    await tester.tap(find.text('Vehicle').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MH 12 CD 5678 · Innova Crysta').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suresh Patil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-confirm')));
    await settle(tester);

    final assign = h.owner.last('assign').args;
    expect(assign['vehicleId'], vehicle2Id);
    expect(assign['driverId'], driver2Id);
    expect(assign['key'], isNotEmpty);
    expect(find.text('Reassign'), findsOneWidget);
    expect(find.text('Suresh Patil'), findsOneWidget);
  });

  testWidgets('approve a driver’s cancellation request with a fare', (
    tester,
  ) async {
    final h = await owner(tester);
    final trip = tripJson(
      status: 'started',
      cancellationPending: true,
      allowed: ['end', 'approveCancel', 'rejectCancel'],
    );
    h.owner.tripsById[trip['id']! as String] = trip;
    await tester.pumpWidget(
      h.screen(OwnerTripDetailScreen(tripId: trip['id']! as String)),
    );
    await settle(tester);
    expect(find.text('“Customer got off early”'), findsOneWidget);

    await tester.tap(find.byKey(const Key('approve-cancellation')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('dialog-text')), '1,200');
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await settle(tester);

    final call = h.owner.last('approveCancellation').args;
    expect(call['requestId'], '0199c7a2-0000-7000-8000-0000000000e1');
    expect(call['cancellationFarePaise'], 120000);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.byKey(const Key('approve-cancellation')), findsNothing);
  });

  testWidgets('rejecting a cancellation needs a note for the driver', (
    tester,
  ) async {
    final h = await owner(tester);
    final trip = tripJson(status: 'started', cancellationPending: true);
    h.owner.tripsById[trip['id']! as String] = trip;
    await tester.pumpWidget(
      h.screen(OwnerTripDetailScreen(tripId: trip['id']! as String)),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('reject-cancellation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('dialog-text')),
      'Finish the trip',
    );
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await settle(tester);
    expect(h.owner.last('rejectCancellation').args['note'], 'Finish the trip');
  });

  testWidgets('extra-fare charges have no "driver paid" choice', (
    tester,
  ) async {
    final h = await owner(tester);
    final trip = tripJson(status: 'started');
    h.owner.tripsById[trip['id']! as String] = trip;
    await tester.pumpWidget(
      h.screen(OwnerTripDetailScreen(tripId: trip['id']! as String)),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('owner-add-charge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('owner-charge-driver-paid')), findsOneWidget);
    await pick(tester, const Key('owner-charge-kind'), 'Night charge');
    expect(find.byKey(const Key('owner-charge-driver-paid')), findsNothing);
    expect(find.byKey(const Key('owner-extra-fare-info')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('owner-charge-amount')), '300');
    await tester.tap(find.byKey(const Key('owner-charge-save')));
    await settle(tester);
    final call = h.owner.last('addCharge').args;
    expect(call['kind'], 'night_charge');
    expect(call['paidByDriver'], isFalse);
    expect(call['amountPaise'], 30000);
  });

  testWidgets(
    'the trip page shows the km over the included km and the timeline',
    (tester) async {
      final h = await owner(tester);
      JsonMap reading(int km) => {
        'id': 'r$km',
        'typedKm': km,
        'ocrKm': null,
        'mediaId': 'm$km',
        'capturedAt': '2026-10-09T03:00:00.000Z',
      };
      final trip = {
        ...tripJson(status: 'ended'),
        'includedKm': 150,
        'startedAt': '2026-10-09T03:00:00.000Z',
        'endedAt': '2026-10-09T08:00:00.000Z',
        'startOdometer': reading(48210),
        'endOdometer': reading(48400),
      };
      h.owner
        ..tripsById[trip['id']! as String] = trip
        ..distanceCheckResult = distanceCheckJson()
        ..alertList = [
          alertJson(kind: 'odo_gps_mismatch', tripId: trip['id']! as String),
        ];
      await tester.pumpWidget(
        h.screen(OwnerTripDetailScreen(tripId: trip['id']! as String)),
      );
      await settle(tester);
      expect(find.text('40 km over (driven 190 km)'), findsOneWidget);
      expect(find.text('Odometer higher than GPS'), findsOneWidget);
      expect(
        find.textContaining("phone's GPS recorded 150 km"),
        findsOneWidget,
      );
      expect(find.text('Started by Driver'), findsOneWidget);
      expect(find.textContaining('45 min later'), findsOneWidget);
    },
  );

  testWidgets('resolve a review item with the photo’s value, or a correction', (
    tester,
  ) async {
    final h = await owner(tester);
    h.owner.reviewList = [
      reviewItemJson(),
      reviewItemJson(
        id: '0199c7a2-0000-7000-8000-0000000r0002',
        kind: 'ocr_mismatch_receipt',
        subjectType: 'fuel_fill',
        typed: '380000',
        ocr: '360000',
      ),
    ];
    await tester.pumpWidget(h.screen(const ReviewScreen()));
    await settle(tester);
    expect(find.text('48,210 km'), findsOneWidget);
    expect(find.text('48,270 km'), findsOneWidget);
    expect(find.text('₹3,800'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-use-photo')).first);
    await settle(tester);
    expect(h.owner.last('resolveReviewItem').args, {
      'id': '0199c7a2-0000-7000-8000-0000000r0001',
      'resolution': 'accepted_ocr',
      'correctedValue': null,
    });

    await tester.tap(find.byKey(const Key('review-correct')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('dialog-text')), '3,700');
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await settle(tester);
    expect(h.owner.last('resolveReviewItem').args['correctedValue'], 370000);
    expect(find.text('Nothing to review'), findsOneWidget);
  });

  testWidgets("settle a driver's day", (tester) async {
    final h = await owner(tester);
    await tester.pumpWidget(
      h.screen(const SettlementsScreen(initialDate: '2026-10-09')),
    );
    await settle(tester);
    expect(find.text('Driver pays you ₹2,100'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    await tester.tap(find.text('Ramesh Kumar'));
    await settle(tester);

    expect(
      find.text('Toll, paid by the driver · Pune Station → Mumbai Airport T2'),
      findsOneWidget,
    );
    expect(find.text('Late parking from 8 Oct'), findsOneWidget);
    expect(
      find.text('From 8 Oct 2026, synced after that day was settled'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('mark-settled')));
    await settle(tester);
    final call = h.owner.last('settle').args;
    expect(call['date'], '2026-10-09');
    expect(call['driverId'], driverId);
    expect(call['key'], isNotEmpty);
    expect(find.byKey(const Key('settled-note')), findsOneWidget);
    expect(find.byKey(const Key('mark-settled')), findsNothing);
  });

  testWidgets(
    'a failed settle shows the reason and can be retried with the same key',
    (tester) async {
      final h = await owner(tester);
      await tester.pumpWidget(
        h.screen(
          const SettlementDetailScreen(date: '2026-10-09', driverId: driverId),
        ),
      );
      await settle(tester);
      h.owner.failNext = ApiException(
        status: 0,
        code: 'NETWORK',
        message: 'offline',
      );
      await tester.tap(find.byKey(const Key('mark-settled')));
      await settle(tester);
      expect(
        find.text('No connection. Check your internet and try again.'),
        findsOneWidget,
      );
      final first = h.owner.last('settle').args['key'];
      await tester.tap(find.byKey(const Key('mark-settled')));
      await settle(tester);
      expect(h.owner.last('settle').args['key'], first);
    },
  );

  testWidgets('invite a manager, then remove their access', (tester) async {
    final h = await owner(tester);
    await tester.pumpWidget(h.screen(const MembersScreen()));
    await settle(tester);
    await tester.tap(find.byKey(const Key('invite-manager')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('invite-name')), 'Kavita Rao');
    await tester.enterText(find.byKey(const Key('invite-phone')), '12345');
    await tester.tap(find.byKey(const Key('invite-send')));
    await tester.pump();
    expect(find.text('Enter a 10-digit Indian mobile number'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('invite-phone')),
      '98765 43210',
    );
    await tester.tap(find.byKey(const Key('invite-send')));
    await settle(tester);
    expect(h.owner.last('inviteManager').args, {
      'name': 'Kavita Rao',
      'phone': '+919876543210',
    });
    expect(find.text('Kavita Rao'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('remove-manager-0199c7a2-0000-7000-8000-000000000m01'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-yes')));
    await settle(tester);
    expect(
      h.owner.last('removeManager').args['id'],
      '0199c7a2-0000-7000-8000-000000000m01',
    );
    expect(find.textContaining('Suspended'), findsOneWidget);
  });

  testWidgets('dismiss a fuel alert as a false alarm', (tester) async {
    final h = await owner(tester);
    await tester.pumpWidget(h.screen(const AlertsScreen()));
    await settle(tester);
    expect(
      find.text('MH12AB1234 (Innova Crysta, diesel) used more fuel than usual'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('alert-false-alarm')));
    await settle(tester);
    expect(h.owner.last('updateAlert').args, {
      'id': '0199c7a2-0000-7000-8000-0000000a0001',
      'status': 'dismissed',
      'falsePositive': true,
    });
    expect(find.text('All clear: no open alerts'), findsOneWidget);
  });

  testWidgets('a list that fails to load can be retried', (tester) async {
    final h = await owner(tester);
    h.owner.failNext = ApiException(status: 0, code: 'NETWORK', message: 'x');
    await tester.pumpWidget(h.screen(const VehiclesScreen()));
    await settle(tester);
    expect(find.text('Could not load this.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry')));
    await settle(tester);
    expect(find.text('MH 12 AB 1234'), findsOneWidget);
  });

  testWidgets('invite a driver from the drivers list', (tester) async {
    final h = await owner(tester);
    await tester.pumpWidget(h.screen(const DriversScreen()));
    await settle(tester);
    expect(find.textContaining('Default · 20% of quoted fare'), findsWidgets);
    await tester.tap(find.byKey(const Key('invite-driver')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('invite-name')), 'Vijay');
    await tester.enterText(find.byKey(const Key('invite-phone')), '9876543210');
    await tester.tap(find.byKey(const Key('invite-send')));
    await settle(tester);
    expect(h.owner.last('inviteDriver').args['phone'], '+919876543210');
  });
}
