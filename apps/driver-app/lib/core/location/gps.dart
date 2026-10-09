import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Great-circle distance in km (for the live "distance so far"; the server's
/// authoritative distance uses PostGIS on cleaned points).
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthKm = 6371.0088;
  double rad(double deg) => deg * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final h =
      pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * earthKm * asin(min(1, sqrt(h)));
}

/// Distance along recorded points, skipping inaccurate ones (> 100 m, as the server does).
double trackKm(List<GpsPoint> points) {
  final good =
      points.where((p) => (p.accuracyM ?? 0) <= 100 && !p.isMock).toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  var total = 0.0;
  for (var i = 1; i < good.length; i++) {
    total += haversineKm(
      good[i - 1].lat,
      good[i - 1].lng,
      good[i].lat,
      good[i].lng,
    );
  }
  return total;
}

/// Best-effort current position for photo evidence; null if unavailable within 5 s.
Future<Position?> currentPosition() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      ),
    );
  } on Object {
    return null;
  }
}

/// Asks for location access; true when the app may record trips.
Future<bool> ensureLocationPermission() async {
  if (!await Geolocator.isLocationServiceEnabled()) return false;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

/// Records the route while a trip is started. On Android it runs as a foreground
/// service with a persistent notification, so the OS doesn't kill it mid-trip;
/// on iOS it uses background location updates.
class GpsRecorder {
  GpsRecorder(this.db);

  final AppDatabase db;
  StreamSubscription<Position>? _subscription;
  String? _tripId;

  String? get recordingTripId => _tripId;

  Future<void> start(String tripId) async {
    if (_tripId == tripId) return;
    await stop();
    if (!await ensureLocationPermission()) return;
    _tripId = tripId;
    _subscription = Geolocator.getPositionStream(locationSettings: _settings())
        .listen(
          (position) => unawaited(_store(tripId, position)),
          onError: (Object error) => debugPrint('GPS error: $error'),
        );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _tripId = null;
  }

  Future<void> _store(String tripId, Position p) => db
      .into(db.gpsPoints)
      .insert(
        GpsPointsCompanion.insert(
          id: const Uuid().v4(),
          tripId: tripId,
          recordedAt: p.timestamp.toUtc(),
          lat: p.latitude,
          lng: p.longitude,
          accuracyM: Value(p.accuracy),
          speedMps: Value(p.speed >= 0 ? p.speed : null),
          heading: Value(p.heading >= 0 ? p.heading : null),
          isMock: Value(p.isMocked),
        ),
      );

  LocationSettings _settings() {
    if (!kIsWeb && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        intervalDuration: const Duration(seconds: 15),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Trip in progress',
          notificationText: 'Taxcy is recording your route for this trip.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (!kIsWeb && Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );
  }
}
