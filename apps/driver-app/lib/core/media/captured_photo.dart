import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';

/// A photo taken with the in-app camera, with the evidence captured alongside it.
class CapturedPhoto {
  const CapturedPhoto({
    required this.id,
    required this.kind,
    required this.path,
    required this.sha256,
    required this.byteSize,
    required this.capturedAt,
    this.contentType = 'image/jpeg',
    this.lat,
    this.lng,
    this.accuracyM,
    this.isMock = false,
  });

  final String id;

  /// odometer or fuel_receipt.
  final String kind;
  final String path;
  final String sha256;
  final int byteSize;
  final String contentType;
  final DateTime capturedAt;
  final double? lat;
  final double? lng;
  final double? accuracyM;

  /// The OS reported the location as mocked (a fake-GPS app); the server flags it.
  final bool isMock;

  static String hash(Uint8List bytes) => sha256Of(bytes);
}

String sha256Of(Uint8List bytes) => sha256.convert(bytes).toString();

/// Persists a captured photo so it survives restarts until it's uploaded.
Future<void> savePhoto(AppDatabase db, CapturedPhoto photo) => db
    .into(db.photos)
    .insertOnConflictUpdate(
      PhotosCompanion.insert(
        id: photo.id,
        kind: photo.kind,
        path: photo.path,
        sha256: photo.sha256,
        byteSize: photo.byteSize,
        contentType: photo.contentType,
        capturedAt: photo.capturedAt,
        lat: Value(photo.lat),
        lng: Value(photo.lng),
        accuracyM: Value(photo.accuracyM),
        isMock: Value(photo.isMock),
      ),
    );
