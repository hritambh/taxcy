import 'auth_models.dart';
import 'http_api.dart';
import 'json.dart';
import 'models.dart';

/// The fields every sign-in sends so the server knows which device holds the
/// session.
typedef DeviceInfo = ({String deviceId, String platform});

/// Signing in, signing up and the account's sign-in methods. The login screens
/// and the account screen depend on this interface, so tests run against a fake.
abstract class AuthApi {
  /// Which sign-in methods the server offers.
  Future<AuthConfig> config();

  /// Sends an SMS code to [phone] (for SMS login, sign-up, reset and Google).
  Future<OtpTicket> requestOtp(String phone);

  /// SMS-code login; creates the user on first login.
  Future<Session> verifyOtp({
    required String phone,
    required String code,
    required DeviceInfo device,
  });

  /// Phone + password sign-up after an SMS code. ACCOUNT_EXISTS when the
  /// number already has a password.
  Future<Session> signUp({
    required String phone,
    required String code,
    required String password,
    required DeviceInfo device,
    String? name,
  });

  /// INVALID_CREDENTIALS for a wrong number or password alike.
  Future<Session> passwordLogin({
    required String phone,
    required String password,
    required DeviceInfo device,
  });

  /// A new password with an SMS code; signs out every other session.
  Future<Session> resetPassword({
    required String phone,
    required String code,
    required String password,
    required DeviceInfo device,
  });

  /// Sets a password, or changes it ([currentPassword] needed if one is set).
  Future<void> changePassword({
    required String newPassword,
    String? currentPassword,
  });

  Future<GoogleSignInResult> googleSignIn({
    required String idToken,
    required DeviceInfo device,
  });

  /// Finishes a first Google sign-in with a phone verified by SMS code.
  Future<Session> googleLink({
    required String linkToken,
    required String phone,
    required String code,
    required DeviceInfo device,
  });

  /// The signed-in user's account and sign-in methods.
  Future<Account> account();

  Future<void> logout(String refreshToken);
}

/// [AuthApi] over the shared HTTP client (same base URL and token refresh).
class HttpAuthApi implements AuthApi {
  HttpAuthApi(this._api);
  final HttpTaxcyApi _api;

  JsonMap _device(DeviceInfo d) => {
    'deviceId': d.deviceId,
    'platform': d.platform,
  };

  Future<JsonMap> _public(String method, String path, [JsonMap? body]) async =>
      asJsonMap(await _api.send(method, path, body: body, auth: false));

  Future<Session> _session(String path, JsonMap body) async =>
      Session.fromJson(await _public('POST', path, body));

  @override
  Future<AuthConfig> config() async =>
      AuthConfig.fromJson(await _public('GET', '/auth/config'));

  @override
  Future<OtpTicket> requestOtp(String phone) async => OtpTicket.fromJson(
    await _public('POST', '/auth/otp/request', {'phone': phone}),
  );

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
    required DeviceInfo device,
  }) => _session('/auth/otp/verify', {
    'phone': phone,
    'code': code,
    ..._device(device),
  });

  @override
  Future<Session> signUp({
    required String phone,
    required String code,
    required String password,
    required DeviceInfo device,
    String? name,
  }) => _session('/auth/signup', {
    'phone': phone,
    'code': code,
    'password': password,
    'name': ?name,
    ..._device(device),
  });

  @override
  Future<Session> passwordLogin({
    required String phone,
    required String password,
    required DeviceInfo device,
  }) => _session('/auth/password/login', {
    'phone': phone,
    'password': password,
    ..._device(device),
  });

  @override
  Future<Session> resetPassword({
    required String phone,
    required String code,
    required String password,
    required DeviceInfo device,
  }) => _session('/auth/password/reset', {
    'phone': phone,
    'code': code,
    'password': password,
    ..._device(device),
  });

  @override
  Future<void> changePassword({
    required String newPassword,
    String? currentPassword,
  }) => _api.send(
    'POST',
    '/me/password',
    body: {'currentPassword': ?currentPassword, 'newPassword': newPassword},
  );

  @override
  Future<GoogleSignInResult> googleSignIn({
    required String idToken,
    required DeviceInfo device,
  }) async => GoogleSignInResult.fromJson(
    await _public('POST', '/auth/google', {
      'idToken': idToken,
      ..._device(device),
    }),
  );

  @override
  Future<Session> googleLink({
    required String linkToken,
    required String phone,
    required String code,
    required DeviceInfo device,
  }) => _session('/auth/google/link', {
    'linkToken': linkToken,
    'phone': phone,
    'code': code,
    ..._device(device),
  });

  @override
  Future<Account> account() async =>
      Account.fromJson(asJsonMap(await _api.send('GET', '/me')));

  @override
  Future<void> logout(String refreshToken) => _api.send(
    'POST',
    '/auth/logout',
    body: {'refreshToken': refreshToken},
    auth: false,
  );
}
