import 'dart:typed_data';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:taxcy_driver/core/api/api.dart';
import 'package:taxcy_driver/core/api/json.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/db/database.dart';
import 'package:taxcy_driver/core/media/captured_photo.dart';

/// In-memory database for tests. Streams close synchronously so widget tests don't
/// end with drift's stream-closing timer still pending.
AppDatabase memoryDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// A trip as the API returns it (shape of libs/contracts Trip).
JsonMap tripJson({
  String id = '0199c7a2-0000-7000-8000-000000000001',
  String status = 'assigned',
  DateTime? scheduledStartAt,
  bool cancellationPending = false,
  List<String>? allowed,
}) {
  final start =
      scheduledStartAt ?? DateTime.now().add(const Duration(hours: 1));
  return {
    'id': id,
    'tripType': 'one_way',
    'status': status,
    'channel': 'direct',
    'customer': {'name': 'Anita Desai', 'phone': '+919822222222'},
    'from': {
      'text': 'Pune Station',
      'point': {'lat': 18.5286, 'lng': 73.8743},
    },
    'to': {'text': 'Mumbai Airport T2', 'point': null},
    'scheduledStartAt': start.toUtc().toIso8601String(),
    'scheduledEndAt': start
        .add(const Duration(hours: 4))
        .toUtc()
        .toIso8601String(),
    'vehicle': {
      'id': '0199c7a2-0000-7000-8000-0000000000aa',
      'registrationNo': 'MH12AB1234',
      'model': 'Innova Crysta',
    },
    'driver': {
      'id': '0199c7a2-0000-7000-8000-0000000000dd',
      'name': 'Ramesh Kumar',
    },
    'quotedFarePaise': 350000,
    'cancellationFarePaise': null,
    'startOdometer': status == 'started'
        ? {
            'id': '0199c7a2-0000-7000-8000-0000000000b1',
            'typedKm': 48210,
            'ocrKm': null,
            'mediaId': '0199c7a2-0000-7000-8000-0000000000c1',
            'capturedAt': '2026-10-09T03:00:00.000Z',
          }
        : null,
    'endOdometer': null,
    'startedAt': status == 'started' ? '2026-10-09T03:00:00.000Z' : null,
    'endedAt': null,
    'cancelledAt': null,
    'cancelReason': null,
    'cancellationRequest': cancellationPending
        ? {
            'id': '0199c7a2-0000-7000-8000-0000000000e1',
            'status': 'pending',
            'reason': 'Customer got off early',
            'requestedBy': '0199c7a2-0000-7000-8000-0000000000f1',
            'requestedRole': 'driver',
            'endOdometer': null,
            'decidedBy': null,
            'decidedAt': null,
            'decisionNote': null,
            'createdAt': '2026-10-09T04:00:00.000Z',
          }
        : null,
    'charges': <Object?>[],
    'collections': <Object?>[],
    'allowedCommands':
        allowed ??
        switch (status) {
          'assigned' => ['reassign', 'unassign', 'start', 'cancel'],
          'started' => ['end', 'requestCancel'],
          _ => <String>[],
        },
    'version': 2,
    'createdAt': '2026-10-08T10:00:00.000Z',
    'updatedAt': '2026-10-09T03:00:00.000Z',
  };
}

JsonMap sessionJson({List<String> roles = const ['driver']}) => {
  'accessToken': 'access-token',
  'accessTokenExpiresAt': '2026-10-09T10:15:00.000Z',
  'refreshToken': 'refresh-token-0123456789abcdef',
  'refreshTokenExpiresAt': '2026-11-08T10:00:00.000Z',
  'user': {
    'id': '0199c7a2-0000-7000-8000-0000000000f1',
    'phone': '+919000000011',
    'name': 'Ramesh Kumar',
  },
  'activeOrgId': '0199c7a2-0000-7000-8000-000000000999',
  'memberships': [
    {
      'orgId': '0199c7a2-0000-7000-8000-000000000999',
      'orgName': 'Sharma Travels',
      'orgKind': 'fleet',
      'roles': roles,
    },
  ],
};

CapturedPhoto fakePhoto(String id, {String kind = 'odometer'}) => CapturedPhoto(
  id: id,
  kind: kind,
  path: '/photos/$id.jpg',
  sha256: 'a' * 64,
  byteSize: 3,
  capturedAt: DateTime.utc(2026, 10, 9, 3),
  lat: 18.52,
  lng: 73.85,
  accuracyM: 8,
);

class ApiCall {
  ApiCall(this.name, [this.args = const {}]);
  final String name;
  final JsonMap args;
  @override
  String toString() => '$name $args';
}

/// Records every call. `failNext` lets a test script failures for a call name.
class FakeApi implements TaxcyApi {
  final calls = <ApiCall>[];
  final _failures = <String, List<ApiException>>{};
  final trips = <String, JsonMap>{};
  bool offline = false;
  List<Vehicle> vehicleList = const [];

  void failNext(String call, ApiException error, {int times = 1}) =>
      (_failures[call] ??= []).addAll(List.filled(times, error));

  static ApiException network() =>
      ApiException(status: 0, code: 'NETWORK', message: 'offline');
  static ApiException conflict(String code) =>
      ApiException(status: 409, code: code, message: code);

  void _record(String name, [JsonMap args = const {}]) {
    calls.add(ApiCall(name, args));
    if (offline) throw network();
    final queue = _failures[name];
    if (queue != null && queue.isNotEmpty) throw queue.removeAt(0);
  }

  List<String> get names => calls.map((c) => c.name).toList();

  @override
  Future<void> requestOtp(String phone) async =>
      _record('requestOtp', {'phone': phone});

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
    required String deviceId,
    required String platform,
  }) async {
    _record('verifyOtp', {'phone': phone, 'code': code});
    return Session.fromJson(sessionJson());
  }

  @override
  Future<void> logout(String refreshToken) async => _record('logout');

  @override
  Future<List<Trip>> myTrips({DateTime? since}) async {
    _record('myTrips');
    return trips.values.map(Trip.fromJson).toList();
  }

  @override
  Future<List<Vehicle>> vehicles() async {
    _record('vehicles');
    return vehicleList;
  }

  @override
  Future<UploadTicket> registerMedia(JsonMap body) async {
    _record('registerMedia', body);
    return UploadTicket.fromJson({
      'id': body['id'],
      'status': 'pending',
      'uploadUrl': 'http://s3.local/upload/${body['id']}',
      'uploadHeaders': {'Content-Type': 'image/jpeg'},
    });
  }

  @override
  Future<void> uploadBytes(
    String url,
    Map<String, String> headers,
    Uint8List bytes,
  ) async => _record('uploadBytes', {'url': url});

  @override
  Future<void> completeMedia(String mediaId) async =>
      _record('completeMedia', {'id': mediaId});

  @override
  Future<Trip> tripCommand(
    String tripId,
    String command,
    String idempotencyKey,
    JsonMap body,
  ) async {
    _record('trip.$command', {
      'tripId': tripId,
      'key': idempotencyKey,
      'body': body,
    });
    final status = switch (command) {
      'start' => 'started',
      'end' => 'ended',
      _ => 'started',
    };
    return Trip.fromJson(tripJson(id: tripId, status: status));
  }

  @override
  Future<Trip> addCharge(String tripId, JsonMap body) async {
    _record('addCharge', {'tripId': tripId, 'body': body});
    return Trip.fromJson(tripJson(id: tripId, status: 'started'));
  }

  @override
  Future<Trip> addCollection(String tripId, JsonMap body) async {
    _record('addCollection', {'tripId': tripId, 'body': body});
    return Trip.fromJson(tripJson(id: tripId, status: 'ended'));
  }

  @override
  Future<void> recordFuelFill(JsonMap body) async =>
      _record('recordFuelFill', body);

  @override
  Future<GpsBatchResult> uploadGps(String tripId, List<JsonMap> points) async {
    _record('uploadGps', {'tripId': tripId, 'count': points.length});
    return GpsBatchResult(
      accepted: points.length,
      duplicates: 0,
      outOfWindow: 0,
    );
  }
}
