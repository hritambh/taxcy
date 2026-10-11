import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api.dart';
import '../core/api/auth_api.dart';
import '../core/api/auth_models.dart';
import '../core/api/http_api.dart';
import '../core/api/models.dart';
import '../core/api/owner_api.dart';
import '../core/auth/google_auth.dart';
import '../core/auth/session_store.dart';
import '../core/db/database.dart';
import '../core/location/gps.dart';
import '../core/media/camera_capture.dart';
import '../core/media/photo_store.dart';
import '../core/media/photo_store_platform.dart';
import '../core/repositories/fuel_repository.dart';
import '../core/repositories/trips_repository.dart';
import '../core/sync/sync_engine.dart';

/// API server root, set at build time with `--dart-define=API_URL=...`. Defaults to
/// the local API as seen from an Android emulator, or from the browser on the web.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000',
);

/// Sent at login so the server knows which kind of device holds the session.
String get devicePlatform => kIsWeb
    ? 'web'
    : defaultTargetPlatform == TargetPlatform.iOS
    ? 'ios'
    : 'android';

/// Overridden in main() with the on-device database, and in tests with an in-memory one.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

final httpApiProvider = Provider<HttpTaxcyApi>(
  (ref) => HttpTaxcyApi(
    baseUrl: apiUrl,
    sessions: ref.watch(sessionStoreProvider),
    onSignedOut: () => ref.invalidate(authProvider),
  ),
);

/// The driver endpoints (sync engine, repositories); tests replace it with a fake.
final apiProvider = Provider<TaxcyApi>((ref) => ref.watch(httpApiProvider));

/// Signing in and the account's sign-in methods; tests replace it with a fake.
final authApiProvider = Provider<AuthApi>(
  (ref) => HttpAuthApi(ref.watch(httpApiProvider)),
);

/// Google's sign-in SDK; tests replace it with a fake.
final googleAuthProvider = Provider<GoogleAuth>((ref) => PluginGoogleAuth());

/// How the login screen offers Google.
enum GoogleOption {
  /// Not at all: switched off on the server, not configured, or the server
  /// can't be reached (password and SMS code still work).
  hidden,

  /// The server's local stand-in: an email instead of a Google account.
  dev,

  /// Real Google sign-in, ready to use.
  google,
}

/// Asks the server which sign-in methods it offers, and gets Google ready when
/// it's on. Re-checked each time the login screen opens.
final googleOptionProvider = FutureProvider.autoDispose<GoogleOption>((
  ref,
) async {
  try {
    final config = await ref.watch(authApiProvider).config();
    final clientId = config.webClientId;
    switch (config.googleMode) {
      case GoogleMode.dev:
        return GoogleOption.dev;
      case GoogleMode.google when clientId != null:
        await ref.watch(googleAuthProvider).initialize(clientId);
        return GoogleOption.google;
      case _:
        return GoogleOption.hidden;
    }
  } on Object catch (error) {
    debugPrint('Google sign-in unavailable: $error');
    return GoogleOption.hidden;
  }
});

/// The signed-in user's account: sign-in methods, Google email.
final accountProvider = FutureProvider.autoDispose<Account>(
  (ref) => ref.watch(authApiProvider).account(),
);

/// The owner/manager endpoints (owner mode); tests replace it with a fake.
final ownerApiProvider = Provider<OwnerApi>(
  (ref) => HttpOwnerApi(ref.watch(httpApiProvider)),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.watch(databaseProvider),
    api: ref.watch(apiProvider),
    readPhoto: ref.watch(photoStoreProvider).read,
    deviceId: ref.watch(sessionStoreProvider).deviceId,
  );
  ref.onDispose(engine.dispose);
  return engine;
});

final tripsRepositoryProvider = Provider<TripsRepository>(
  (ref) => TripsRepository(
    ref.watch(databaseProvider),
    ref.watch(syncEngineProvider),
  ),
);

final fuelRepositoryProvider = Provider<FuelRepository>(
  (ref) => FuelRepository(ref.watch(databaseProvider), ref.watch(apiProvider)),
);

/// The fleet's vehicles, refreshed when online and cached for offline use.
final vehiclesProvider = FutureProvider<List<Vehicle>>(
  (ref) => ref.watch(fuelRepositoryProvider).vehicles(),
);

/// Where photos wait until they're uploaded: files on phones, the local database
/// in the browser.
final photoStoreProvider = Provider<PhotoStore>(
  (ref) => platformPhotoStore(ref.watch(databaseProvider)),
);

/// How photos are taken; tests replace it with a fake.
final photoCaptureProvider = Provider<PhotoCapture>((ref) {
  final store = ref.watch(photoStoreProvider);
  return (context, kind) => captureWithCamera(context, kind, store);
});

/// Whether to run background sync and GPS (off in widget tests).
final backgroundWorkProvider = Provider<bool>((ref) => true);

final gpsRecorderProvider = Provider<GpsRecorder>((ref) {
  final recorder = GpsRecorder(ref.watch(databaseProvider));
  ref.onDispose(recorder.stop);
  return recorder;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final engine = ref.watch(syncEngineProvider);
  yield engine.current;
  yield* engine.status;
});

final tripsProvider = StreamProvider<List<TripView>>(
  (ref) => ref.watch(tripsRepositoryProvider).watchTrips(),
);

final tripProvider = StreamProvider.family<TripView?, String>(
  (ref, id) => ref.watch(tripsRepositoryProvider).watchTrip(id),
);

final tripDistanceProvider = StreamProvider.family<double, String>((
  ref,
  tripId,
) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.gpsPoints,
  )..where((p) => p.tripId.equals(tripId))).watch().map(trackKm);
});

/// The signed-in session (null when signed out).
final authProvider = AsyncNotifierProvider<AuthController, Session?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() => ref.watch(sessionStoreProvider).load();

  DeviceInfo? _deviceInfo;

  Future<DeviceInfo> _device() async => _deviceInfo ??= (
    deviceId: await ref.read(sessionStoreProvider).deviceId(),
    platform: devicePlatform,
  );

  AuthApi get _api => ref.read(authApiProvider);

  Future<void> _signedIn(Session session) async {
    await ref.read(sessionStoreProvider).save(session);
    state = AsyncData(session);
  }

  /// Sends an SMS code (login, sign-up, password reset, Google link).
  Future<OtpTicket> requestOtp(String phone) => _api.requestOtp(phone);

  /// SMS-code login.
  Future<void> verify(String phone, String code) async => _signedIn(
    await _api.verifyOtp(phone: phone, code: code, device: await _device()),
  );

  Future<void> passwordLogin(String phone, String password) async => _signedIn(
    await _api.passwordLogin(
      phone: phone,
      password: password,
      device: await _device(),
    ),
  );

  Future<void> signUp({
    required String phone,
    required String code,
    required String password,
    String? name,
  }) async => _signedIn(
    await _api.signUp(
      phone: phone,
      code: code,
      password: password,
      name: name,
      device: await _device(),
    ),
  );

  Future<void> resetPassword({
    required String phone,
    required String code,
    required String password,
  }) async => _signedIn(
    await _api.resetPassword(
      phone: phone,
      code: code,
      password: password,
      device: await _device(),
    ),
  );

  /// Signs in with a Google ID token. Returns the pending link when this Google
  /// account still needs a phone verified ([googleLink]); null once signed in.
  Future<GooglePhoneRequired?> googleSignIn(String idToken) async {
    final result = await _api.googleSignIn(
      idToken: idToken,
      device: await _device(),
    );
    switch (result) {
      case GoogleSignedIn(:final session):
        await _signedIn(session);
        return null;
      case GooglePhoneRequired():
        return result;
    }
  }

  Future<void> googleLink({
    required String linkToken,
    required String phone,
    required String code,
  }) async => _signedIn(
    await _api.googleLink(
      linkToken: linkToken,
      phone: phone,
      code: code,
      device: await _device(),
    ),
  );

  Future<void> signOut() async {
    final store = ref.read(sessionStoreProvider);
    final session = await store.load();
    if (session != null) {
      try {
        await _api.logout(session.refreshToken);
      } on ApiException {
        // Signing out locally still matters when offline.
      }
    }
    await ref.read(gpsRecorderProvider).stop();
    await ref.read(googleAuthProvider).signOut();
    await store.clear();
    await ref.read(databaseProvider).clearAll();
    state = const AsyncData(null);
  }
}
