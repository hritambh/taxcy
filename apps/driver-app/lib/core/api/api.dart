import 'dart:typed_data';

import 'json.dart';
import 'models.dart';

/// A failed API call, carrying the server's error envelope
/// `{error: {code, message, details, requestId}}` when there is one.
class ApiException implements Exception {
  ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.details,
    this.requestId,
  });

  /// HTTP status; 0 when the request never reached the server.
  final int status;
  final String code;
  final String message;
  final Object? details;
  final String? requestId;

  /// No response at all (offline, DNS, timeout): always worth retrying.
  bool get isNetwork => status == 0;

  /// Server-side or transient: retry with backoff.
  bool get isRetryable =>
      isNetwork || status >= 500 || status == 429 || status == 408;

  @override
  String toString() =>
      'ApiException($status $code: $message${requestId == null ? '' : ' [$requestId]'})';
}

/// The endpoints the driver app uses. The sync engine and repositories depend on
/// this interface, so tests run against a fake.
abstract class TaxcyApi {
  Future<void> requestOtp(String phone);
  Future<Session> verifyOtp({
    required String phone,
    required String code,
    required String deviceId,
    required String platform,
  });
  Future<void> logout(String refreshToken);

  Future<List<Trip>> myTrips({DateTime? since});
  Future<List<Vehicle>> vehicles();

  Future<UploadTicket> registerMedia(JsonMap body);
  Future<void> uploadBytes(
    String url,
    Map<String, String> headers,
    Uint8List bytes,
  );
  Future<void> completeMedia(String mediaId);

  /// Creates a trip assigned to the signed-in driver; idempotent on body.id.
  Future<Trip> createTrip(JsonMap body);

  /// A trip command (start, end, cancellation-requests) with an Idempotency-Key.
  Future<Trip> tripCommand(
    String tripId,
    String command,
    String idempotencyKey,
    JsonMap body,
  );
  Future<Trip> addCharge(String tripId, JsonMap body);
  Future<Trip> addCollection(String tripId, JsonMap body);
  Future<void> recordFuelFill(JsonMap body);
  Future<GpsBatchResult> uploadGps(String tripId, List<JsonMap> points);
}
