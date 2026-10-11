import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/core/api/auth_models.dart';
import 'package:taxcy_driver/core/api/json.dart';

import 'support/auth_fakes.dart';
import 'support/fakes.dart';

void main() {
  test('OtpTicket parses the resend wait', () {
    final ticket = OtpTicket.fromJson({
      'expiresInSeconds': 300,
      'resendAfterSeconds': 30,
    });
    expect(ticket.expiresInSeconds, 300);
    expect(ticket.resendAfterSeconds, 30);
  });

  group('AuthConfig', () {
    test('real Google with the web client id', () {
      final config = AuthConfig.fromJson({
        'password': true,
        'google': {'mode': 'google', 'webClientId': 'web.apps.example'},
      });
      expect(config.password, isTrue);
      expect(config.googleMode, GoogleMode.google);
      expect(config.webClientId, 'web.apps.example');
    });

    test('the local stand-in and off', () {
      for (final mode in GoogleMode.values) {
        final config = AuthConfig.fromJson({
          'password': true,
          'google': {'mode': mode.name, 'webClientId': null},
        });
        expect(config.googleMode, mode);
        expect(config.webClientId, isNull);
      }
    });

    test('a mode this app does not know switches Google off', () {
      final config = AuthConfig.fromJson({
        'password': false,
        'google': {'mode': 'apple', 'webClientId': null},
      });
      expect(config.googleMode, GoogleMode.off);
    });

    test('a broken payload fails loudly', () {
      expect(
        () => AuthConfig.fromJson({'password': true}),
        throwsA(isA<JsonShapeError>()),
      );
    });
  });

  group('GoogleSignInResult', () {
    test('signed in carries the session', () {
      final result = GoogleSignInResult.fromJson({
        'status': 'signed_in',
        'session': sessionJson(roles: ['owner']),
      });
      expect(result, isA<GoogleSignedIn>());
      expect((result as GoogleSignedIn).session.isOwner, isTrue);
    });

    test('phone required carries the link token and Google profile', () {
      final result = GoogleSignInResult.fromJson({
        'status': 'phone_required',
        'linkToken': 'link-token-0123456789abcdef',
        'email': 'asha@example.com',
        'name': null,
      });
      final pending = result as GooglePhoneRequired;
      expect(pending.linkToken, 'link-token-0123456789abcdef');
      expect(pending.email, 'asha@example.com');
      expect(pending.name, isNull);
    });

    test('an unknown status fails loudly', () {
      expect(
        () => GoogleSignInResult.fromJson({'status': 'maybe'}),
        throwsA(isA<JsonShapeError>()),
      );
    });
  });

  test('Account parses the sign-in methods from GET /me', () {
    final account = Account.fromJson(
      accountJson(hasPassword: true, googleLinked: true, email: 'r@x.in'),
    );
    expect(account.phone, '+919000000011');
    expect(account.name, 'Ramesh Kumar');
    expect(account.email, 'r@x.in');
    expect(account.hasPassword, isTrue);
    expect(account.googleLinked, isTrue);

    final plain = Account.fromJson(accountJson());
    expect(plain.email, isNull);
    expect(plain.hasPassword, isFalse);
    expect(plain.googleLinked, isFalse);
  });
}
