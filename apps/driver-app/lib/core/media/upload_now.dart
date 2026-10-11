import 'dart:typed_data';

import '../api/api.dart';
import 'captured_photo.dart';

/// Uploads a photo straight away (register → PUT → confirm) and returns its
/// media id. Owner mode is online-first, so unlike the driver's photos this
/// doesn't go through the outbox; a failure is shown and the user retries.
Future<String> uploadPhotoNow(
  TaxcyApi api,
  CapturedPhoto photo, {
  required Future<Uint8List> Function(String path) readBytes,
  required String deviceId,
}) async {
  final ticket = await api.registerMedia({
    'id': photo.id,
    'kind': photo.kind,
    'contentType': photo.contentType,
    'sha256': photo.sha256,
    'byteSize': photo.byteSize,
    'capturedAt': photo.capturedAt.toUtc().toIso8601String(),
    if (photo.lat != null && photo.lng != null)
      'location': {
        'lat': photo.lat,
        'lng': photo.lng,
        if (photo.accuracyM != null) 'accuracyM': photo.accuracyM,
      },
    'isMockLocation': photo.isMock,
    'deviceId': deviceId,
  });
  final url = ticket.uploadUrl;
  if (ticket.status == 'pending' && url != null) {
    await api.uploadBytes(
      url,
      ticket.uploadHeaders,
      await readBytes(photo.path),
    );
  }
  if (ticket.status != 'uploaded') await api.completeMedia(photo.id);
  return photo.id;
}
