import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:taxcy_driver/core/api/api.dart';
import 'package:taxcy_driver/core/api/auth_api.dart';
import 'package:taxcy_driver/core/api/auth_models.dart';
import 'package:taxcy_driver/core/api/json.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/auth/google_auth.dart';

import 'fakes.dart';

/// GET /me as the API returns it.
JsonMap accountJson({
  bool hasPassword = false,
  bool googleLinked = false,
  String? email,
}) => {
  'user': {
    'id': '0199c7a2-0000-7000-8000-0000000000f1',
    'phone': '+919000000011',
    'name': 'Ramesh Kumar',
    'email': email,
    'hasPassword': hasPassword,
    'googleLinked': googleLinked,
  },
  'activeOrgId': '0199c7a2-0000-7000-8000-000000000999',
  'roles': ['driver'],
  'memberships': <Object?>[],
};

/// Records every sign-in call. `failNext` scripts failures for a call name;
/// [roles] decides who the signed-in session belongs to.
class FakeAuthApi implements AuthApi {
  final calls = <ApiCall>[];
  final _failures = <String, List<Object>>{};

  /// GET /auth/config; null makes it fail like an unreachable server.
  JsonMap? configJson = {
    'password': true,
    'google': {'mode': 'dev', 'webClientId': null},
  };
  List<String> roles = const ['driver'];
  int resendAfterSeconds = 30;

  /// What POST /auth/google answers.
  JsonMap Function(String idToken) google = (_) => {
    'status': 'phone_required',
    'linkToken': 'link-token-0123456789abcdef',
    'email': 'ramesh@example.com',
    'name': 'Ramesh Kumar',
  };
  JsonMap accountData = accountJson();

  void failNext(String call, Object error, {int times = 1}) =>
      (_failures[call] ??= []).addAll(List.filled(times, error));

  static ApiException error(String code, {int status = 400}) =>
      ApiException(status: status, code: code, message: code);

  List<String> get names => calls.map((c) => c.name).toList();

  void _record(String name, [JsonMap args = const {}]) {
    calls.add(ApiCall(name, args));
    final queue = _failures[name];
    if (queue != null && queue.isNotEmpty) throw queue.removeAt(0);
  }

  Session _session() => Session.fromJson(sessionJson(roles: roles));

  @override
  Future<AuthConfig> config() async {
    _record('config');
    final json = configJson;
    if (json == null) throw FakeApi.network();
    return AuthConfig.fromJson(json);
  }

  @override
  Future<OtpTicket> requestOtp(String phone) async {
    _record('requestOtp', {'phone': phone});
    return OtpTicket(
      expiresInSeconds: 300,
      resendAfterSeconds: resendAfterSeconds,
    );
  }

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
    required DeviceInfo device,
  }) async {
    _record('verifyOtp', {'phone': phone, 'code': code});
    return _session();
  }

  @override
  Future<Session> signUp({
    required String phone,
    required String code,
    required String password,
    required DeviceInfo device,
    String? name,
  }) async {
    _record('signUp', {
      'phone': phone,
      'code': code,
      'password': password,
      'name': name,
      'platform': device.platform,
    });
    return _session();
  }

  @override
  Future<Session> passwordLogin({
    required String phone,
    required String password,
    required DeviceInfo device,
  }) async {
    _record('passwordLogin', {'phone': phone, 'password': password});
    return _session();
  }

  @override
  Future<Session> resetPassword({
    required String phone,
    required String code,
    required String password,
    required DeviceInfo device,
  }) async {
    _record('resetPassword', {
      'phone': phone,
      'code': code,
      'password': password,
    });
    return _session();
  }

  @override
  Future<void> changePassword({
    required String newPassword,
    String? currentPassword,
  }) async => _record('changePassword', {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  });

  @override
  Future<GoogleSignInResult> googleSignIn({
    required String idToken,
    required DeviceInfo device,
  }) async {
    _record('googleSignIn', {'idToken': idToken});
    final json = google(idToken);
    if (json['status'] == 'signed_in') {
      return GoogleSignedIn(_session());
    }
    return GoogleSignInResult.fromJson(json);
  }

  @override
  Future<Session> googleLink({
    required String linkToken,
    required String phone,
    required String code,
    required DeviceInfo device,
  }) async {
    _record('googleLink', {
      'linkToken': linkToken,
      'phone': phone,
      'code': code,
    });
    return _session();
  }

  @override
  Future<Account> account() async {
    _record('account');
    return Account.fromJson(accountData);
  }

  @override
  Future<void> logout(String refreshToken) async => _record('logout');
}

/// Google's SDK stand-in: [authenticate] returns [nextToken]; [emit] plays
/// Google's web button.
class FakeGoogleAuth implements GoogleAuth {
  final _tokens = StreamController<String>.broadcast();
  String? initializedWith;
  bool supports = true;
  String? nextToken = 'google-id-token-0123456789';
  int signOuts = 0;

  void emit(String token) => _tokens.add(token);

  @override
  Future<void> initialize(String webClientId) async =>
      initializedWith = webClientId;

  @override
  bool get supportsAuthenticate => supports;

  @override
  Future<String?> authenticate() async => nextToken;

  @override
  Stream<String> get idTokens => _tokens.stream;

  @override
  Widget button({String? locale}) =>
      const SizedBox(key: Key('google-web-button'), height: 40);

  @override
  Future<void> signOut() async => signOuts++;
}
