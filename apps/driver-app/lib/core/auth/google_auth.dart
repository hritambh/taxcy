import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart';

/// Google sign-in, reduced to what the login screen needs: an ID token for
/// `POST /auth/google`. Tests replace it with a fake.
abstract class GoogleAuth {
  /// Prepares Google sign-in with the server's web client id. Call (and await)
  /// before anything else; calling again is a no-op.
  Future<void> initialize(String webClientId);

  /// True where the app shows its own button and calls [authenticate] (Android,
  /// iOS); false on the web, where Google's own [button] must be used and its
  /// tokens arrive on [idTokens].
  bool get supportsAuthenticate;

  /// Opens Google's account picker; the ID token, or null if the user backed out.
  Future<String?> authenticate();

  /// ID tokens from Google's own [button] (web).
  Stream<String> get idTokens;

  /// Google's own sign-in button (web only; empty elsewhere).
  Widget button({String? locale});

  /// Forgets the Google account on this device (signing out of Taxcy).
  Future<void> signOut();
}

/// [GoogleAuth] with the `google_sign_in` plugin (v7).
///
/// Android: [initialize] passes the web client id as `serverClientId`, which is
/// the ID token's audience; the Android OAuth client (package name + SHA-1) must
/// exist in the same Google Cloud project. iOS: the iOS client id comes from
/// `GIDClientID` in Info.plist (plus its reversed id as a URL scheme). Web: the
/// web client id is the `clientId`. See docs/development.md.
class PluginGoogleAuth implements GoogleAuth {
  final _google = GoogleSignIn.instance;
  final _tokens = StreamController<String>.broadcast();
  Future<void>? _ready;

  @override
  Future<void> initialize(String webClientId) => _ready ??= () async {
    try {
      await _google.initialize(
        clientId: kIsWeb ? webClientId : null,
        serverClientId: kIsWeb ? null : webClientId,
      );
    } on Object {
      _ready = null;
      rethrow;
    }
    if (!kIsWeb) return;
    _google.authenticationEvents.listen((event) {
      if (event case GoogleSignInAuthenticationEventSignIn(:final user)) {
        final token = user.authentication.idToken;
        if (token != null) _tokens.add(token);
      }
    }, onError: _tokens.addError);
  }();

  @override
  bool get supportsAuthenticate => _google.supportsAuthenticate();

  @override
  Future<String?> authenticate() async {
    try {
      final account = await _google.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Stream<String> get idTokens => _tokens.stream;

  @override
  Widget button({String? locale}) => googleWebButton(locale: locale);

  @override
  Future<void> signOut() async {
    if (_ready == null) return;
    try {
      await _google.signOut();
    } on Object {
      // Not signed in to Google here, or the plugin isn't set up: nothing to do.
    }
  }
}
