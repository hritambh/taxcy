import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taxcy_driver/app/app.dart';
import 'package:taxcy_driver/core/api/api.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/repositories/trips_repository.dart';
import 'package:taxcy_driver/features/common/errors.dart';
import 'package:taxcy_driver/features/common/format.dart';
import 'package:taxcy_driver/l10n/app_localizations.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

final en = lookupAppLocalizations(const Locale('en'));
final hi = lookupAppLocalizations(const Locale('hi'));

Map<String, Object?> _arb(String name) =>
    (jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map)
        .cast<String, Object?>();

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)[,}]').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  setUpAll(initializeDateFormatting);

  group('translations', () {
    final english = _arb('app_en.arb');
    final keys = english.keys.where((k) => !k.startsWith('@')).toSet();

    test(
      'every English message has a Hindi translation, and nothing extra',
      () {
        final hindi = _arb('app_hi.arb');
        final hindiKeys = hindi.keys.where((k) => !k.startsWith('@')).toSet();
        expect(keys.difference(hindiKeys), isEmpty, reason: 'missing in Hindi');
        expect(hindiKeys.difference(keys), isEmpty, reason: 'only in Hindi');
        for (final key in keys) {
          expect(
            _placeholders(hindi[key]! as String),
            _placeholders(english[key]! as String),
            reason: 'placeholders of $key',
          );
        }
      },
    );

    test('every other ARB file is a complete translation too', () {
      for (final file in Directory('lib/l10n').listSync()) {
        final name = file.uri.pathSegments.last;
        if (!name.endsWith('.arb') || name == 'app_en.arb') continue;
        final other = _arb(name).keys.where((k) => !k.startsWith('@'));
        expect(keys.difference(other.toSet()), isEmpty, reason: name);
      }
    });

    test('Hindi is written in Devanagari', () {
      expect(hi.myTrips, 'मेरी ट्रिप');
      expect(hi.startTrip, 'ट्रिप शुरू करें');
      expect(hi.hours(count: 1), '1 घंटा');
      expect(hi.hours(count: 4), '4 घंटे');
    });
  });

  group('formatting follows the language', () {
    final now = DateTime(2026, 10, 10, 9);

    test('money uses ₹ and Indian digit grouping in both languages', () {
      for (final l in [en, hi]) {
        final f = Fmt(l);
        expect(f.inr(12345678), '₹1,23,456.78');
        expect(f.inr(350000), '₹3,500');
        expect(f.inr(0), '₹0');
        expect(f.number(1234567), '12,34,567');
      }
      expect(Fmt(en).locale, 'en_IN');
      expect(Fmt(hi).locale, 'hi_IN');
    });

    test('days and dates are in the app language', () {
      final at = DateTime(2026, 10, 10, 14, 30);
      expect(Fmt(en).day(at, now: now), 'Today');
      expect(Fmt(hi).day(at, now: now), 'आज');
      expect(Fmt(en).day(DateTime(2026, 10, 11, 8), now: now), 'Tomorrow');
      expect(Fmt(en).date(DateTime(2026, 10, 20), now: now), '20 Oct');
      expect(Fmt(hi).date(DateTime(2026, 10, 20), now: now), contains('20'));
      expect(Fmt(hi).date(DateTime(2026, 10, 20), now: now), contains('अक्तू'));
      expect(Fmt(en).time(at), '2:30 pm');
      expect(Fmt(en).calendarDate('2026-11-01'), '1 Nov 2026');
    });

    test('fuel quantities use the language’s units', () {
      expect(Fmt(en).quantity(20000, 'diesel'), '20.0 L');
      expect(Fmt(hi).quantity(8500, 'cng'), '8.5 किलो');
    });

    test('validation messages are translated', () {
      expect(validateKm(en, ''), 'Enter the odometer reading in km');
      expect(validateKm(hi, '5', atLeast: 10), 'कम से कम 10 किमी होना चाहिए');
      expect(validateRupees(hi, '0'), 'रकम ₹0 से ज़्यादा होनी चाहिए');
      expect(parseRupees('₹1,234.50'), 123450);
    });
  });

  group('errors', () {
    ApiException error(String code, [String message = 'Server text']) =>
        ApiException(status: 409, code: code, message: message);

    test('known error codes are translated', () {
      expect(errorText(en, error('VEHICLE_BUSY')), en.errorVehicleBusy);
      expect(
        errorText(hi, error('VEHICLE_BUSY')),
        'यह गाड़ी उस समय पहले से बुक है।',
      );
      expect(errorText(hi, error('NETWORK')), hi.errorNetwork);
      expect(errorText(en, error('FORBIDDEN_ROLE')), en.errorForbiddenRole);
    });

    test('every contract error code has a translation', () {
      const codes = [
        'VALIDATION_FAILED', 'UNAUTHENTICATED', 'TOKEN_EXPIRED', //
        'FORBIDDEN_ROLE', 'NO_ACTIVE_ORG', 'NOT_FOUND', 'ILLEGAL_TRANSITION',
        'TRIP_CANCELLED', 'TRIP_REASSIGNED', 'VEHICLE_BUSY', 'DRIVER_BUSY',
        'CANCELLATION_PENDING', 'ALREADY_SETTLED', 'IDEMPOTENCY_CONFLICT',
        'IDEMPOTENCY_KEY_REQUIRED', 'VERSION_CONFLICT', 'CONFLICT',
        'FUEL_TYPE_MISMATCH', 'ODOMETER_BEFORE_START', 'OTP_INVALID',
        'OTP_EXPIRED', 'RATE_LIMITED', 'UPLOAD_NOT_FOUND', 'UPLOAD_MISMATCH',
        'INTERNAL', 'INVALID_CREDENTIALS', 'ACCOUNT_EXISTS', //
        'GOOGLE_TOKEN_INVALID', 'GOOGLE_ACCOUNT_CONFLICT',
      ];
      for (final code in codes) {
        expect(errorCodeText(en, code), isNotNull, reason: code);
        expect(errorCodeText(hi, code), isNot(errorCodeText(en, code)));
      }
    });

    test('unknown codes fall back to the server message', () {
      expect(errorText(hi, error('SOMETHING_NEW', 'New thing')), 'New thing');
    });

    test('stored outbox errors are translated by their code', () {
      expect(
        outboxErrorText(hi, 'TRIP_CANCELLED: This trip has been cancelled'),
        hi.errorTripCancelled,
      );
      expect(outboxErrorText(en, 'WEIRD: raw text'), 'raw text');
      expect(outboxErrorText(en, null), '');
    });

    test('local checks are worded in the app language', () {
      final belowStart = LocalRejection(
        RejectionReason.endBelowStart,
        'End reading must be at least 48210 km',
        km: 48210,
      );
      expect(
        rejectionText(en, belowStart),
        'End reading must be at least 48210 km',
      );
      expect(
        rejectionText(hi, belowStart),
        'आखिरी रीडिंग कम से कम 48210 किमी होनी चाहिए',
      );
      final wrongState = LocalRejection(
        RejectionReason.wrongState,
        'Cannot end a trip that is assigned',
        status: 'assigned',
      );
      expect(
        rejectionText(en, wrongState),
        "This can't be done while the trip is Assigned",
      );
    });
  });

  group('in Hindi', () {
    testWidgets('the login screen is in Hindi', (tester) async {
      final h = await Harness.create(language: 'hi');
      addTearDown(h.dispose);
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.text('मोबाइल नंबर'), findsOneWidget);
      expect(find.text('कोड भेजें'), findsOneWidget);

      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();
      expect(find.text('अपना 10 अंकों का मोबाइल नंबर डालें'), findsOneWidget);
    });

    testWidgets('a driver sees their trips in Hindi', (tester) async {
      final h = await Harness.create(
        language: 'hi',
        session: Session.fromJson(sessionJson()),
      );
      addTearDown(h.dispose);
      await h.engine.cacheTrip(Trip.fromJson(tripJson(status: 'started')));
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.text('मेरी ट्रिप'), findsOneWidget);
      // Section header and status chip.
      expect(find.text('रास्ते में'), findsNWidgets(2));
    });

    testWidgets('switching language from the login screen is remembered', (
      tester,
    ) async {
      final h = await Harness.create();
      addTearDown(h.dispose);
      await tester.pumpWidget(h.wrap(const TaxcyDriverApp()));
      await settle(tester);
      expect(find.text('Send code'), findsOneWidget);

      await tester.tap(find.byKey(const Key('language-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-hi')));
      await tester.pumpAndSettle();
      expect(find.text('कोड भेजें'), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(h.prefs.getString('locale_v1'), 'hi');
    });
  });
}
