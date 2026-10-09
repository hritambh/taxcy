import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api.dart';
import '../core/api/http_api.dart';
import '../core/api/models.dart';
import '../core/auth/session_store.dart';
import '../core/db/database.dart';
import '../core/location/gps.dart';
import '../core/media/camera_capture.dart';
import '../core/repositories/fuel_repository.dart';
import '../core/repositories/trips_repository.dart';
import '../core/sync/sync_engine.dart';

/// API server root, set at build time:
/// `flutter run --dart-define=API_URL=http://10.0.2.2:3000` (Android emulator default).
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

/// Overridden in main() with the on-device database, and in tests with an in-memory one.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

final apiProvider = Provider<TaxcyApi>(
  (ref) => HttpTaxcyApi(
    baseUrl: apiUrl,
    sessions: ref.watch(sessionStoreProvider),
    onSignedOut: () => ref.invalidate(authProvider),
  ),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.watch(databaseProvider),
    api: ref.watch(apiProvider),
    readPhoto: (path) => File(path).readAsBytes(),
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

/// How photos are taken; tests replace it with a fake.
final photoCaptureProvider = Provider<PhotoCapture>((ref) => captureWithCamera);

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

  Future<void> requestOtp(String phone) =>
      ref.read(apiProvider).requestOtp(phone);

  Future<void> verify(String phone, String code) async {
    final store = ref.read(sessionStoreProvider);
    final session = await ref
        .read(apiProvider)
        .verifyOtp(
          phone: phone,
          code: code,
          deviceId: await store.deviceId(),
          platform: Platform.isIOS ? 'ios' : 'android',
        );
    await store.save(session);
    state = AsyncData(session);
  }

  Future<void> signOut() async {
    final store = ref.read(sessionStoreProvider);
    final session = await store.load();
    if (session != null) {
      try {
        await ref.read(apiProvider).logout(session.refreshToken);
      } on ApiException {
        // Signing out locally still matters when offline.
      }
    }
    await ref.read(gpsRecorderProvider).stop();
    await store.clear();
    await ref.read(databaseProvider).clearAll();
    state = const AsyncData(null);
  }
}
