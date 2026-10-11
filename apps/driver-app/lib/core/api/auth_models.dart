// Typed mirrors of the sign-in contracts (libs/contracts/src/routes/identity.ts):
// SMS codes, phone + password, Google, and the signed-in account.
import 'json.dart';
import 'models.dart';

/// An SMS code was sent (`POST /auth/otp/request`).
class OtpTicket {
  const OtpTicket({
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
  });

  factory OtpTicket.fromJson(JsonMap json) => OtpTicket(
    expiresInSeconds: json.integer('expiresInSeconds'),
    resendAfterSeconds: json.integer('resendAfterSeconds'),
  );

  final int expiresInSeconds;

  /// How long to wait before another code can be sent.
  final int resendAfterSeconds;
}

/// How Google sign-in works on this server: real Google accounts, a local
/// stand-in that takes any email (development and tests), or not at all.
enum GoogleMode { google, dev, off }

/// Which sign-in methods the server offers (`GET /auth/config`).
class AuthConfig {
  const AuthConfig({
    required this.password,
    required this.googleMode,
    required this.webClientId,
  });

  factory AuthConfig.fromJson(JsonMap json) {
    final google = json.obj('google');
    final mode = google.str('mode');
    return AuthConfig(
      password: json.boolean('password'),
      googleMode: GoogleMode.values.firstWhere(
        (m) => m.name == mode,
        // A mode this app doesn't know yet: don't offer Google.
        orElse: () => GoogleMode.off,
      ),
      webClientId: google.strOrNull('webClientId'),
    );
  }

  final bool password;
  final GoogleMode googleMode;

  /// The Google OAuth web client id: the web build's client id, and the
  /// `serverClientId` (ID token audience) on Android and iOS.
  final String? webClientId;
}

/// What `POST /auth/google` returns: signed in, or a first Google sign-in that
/// still needs a phone verified by SMS code.
sealed class GoogleSignInResult {
  const GoogleSignInResult();

  factory GoogleSignInResult.fromJson(JsonMap json) =>
      switch (json.str('status')) {
        'signed_in' => GoogleSignedIn(Session.fromJson(json.obj('session'))),
        'phone_required' => GooglePhoneRequired(
          linkToken: json.str('linkToken'),
          email: json.strOrNull('email'),
          name: json.strOrNull('name'),
        ),
        final other => throw JsonShapeError('Unknown Google status $other'),
      };
}

class GoogleSignedIn extends GoogleSignInResult {
  const GoogleSignedIn(this.session);
  final Session session;
}

/// Send [linkToken] (valid 10 minutes) with a verified phone to
/// `POST /auth/google/link`.
class GooglePhoneRequired extends GoogleSignInResult {
  const GooglePhoneRequired({
    required this.linkToken,
    required this.email,
    required this.name,
  });

  final String linkToken;
  final String? email;
  final String? name;
}

/// The signed-in user's account and sign-in methods (`GET /me`).
class Account {
  const Account({
    required this.id,
    required this.phone,
    required this.name,
    required this.email,
    required this.hasPassword,
    required this.googleLinked,
  });

  factory Account.fromJson(JsonMap json) {
    final user = json.obj('user');
    return Account(
      id: user.str('id'),
      phone: user.str('phone'),
      name: user.strOrNull('name'),
      email: user.strOrNull('email'),
      hasPassword: user.boolean('hasPassword'),
      googleLinked: user.boolean('googleLinked'),
    );
  }

  final String id;
  final String phone;
  final String? name;

  /// The linked Google account's email, if any.
  final String? email;
  final bool hasPassword;
  final bool googleLinked;
}
