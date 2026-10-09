import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../auth/session_store.dart';
import 'api.dart';
import 'json.dart';
import 'models.dart';

/// [TaxcyApi] over HTTP. Adds the bearer token, refreshes it once on
/// TOKEN_EXPIRED, and turns failures into [ApiException]s from the error envelope.
class HttpTaxcyApi implements TaxcyApi {
  HttpTaxcyApi({
    required this.baseUrl,
    required this.sessions,
    http.Client? client,
    this.onSignedOut,
    this.timeout = const Duration(seconds: 20),
  }) : _http = client ?? http.Client();

  /// Server root, e.g. http://10.0.2.2:3000 (the `/v1` prefix is added here).
  final String baseUrl;
  final SessionStore sessions;
  final http.Client _http;
  final Duration timeout;

  /// Called when the refresh token is rejected: the driver must sign in again.
  final void Function()? onSignedOut;

  Future<String>? _refreshing;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/v1$path').replace(queryParameters: query);

  @override
  Future<void> requestOtp(String phone) =>
      _send('POST', '/auth/otp/request', body: {'phone': phone}, auth: false);

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
    required String deviceId,
    required String platform,
  }) async {
    final json = await _send(
      'POST',
      '/auth/otp/verify',
      body: {
        'phone': phone,
        'code': code,
        'deviceId': deviceId,
        'platform': platform,
      },
      auth: false,
    );
    return Session.fromJson(asJsonMap(json));
  }

  @override
  Future<void> logout(String refreshToken) => _send(
    'POST',
    '/auth/logout',
    body: {'refreshToken': refreshToken},
    auth: false,
  );

  @override
  Future<List<Trip>> myTrips({DateTime? since}) async {
    final json = await _send(
      'GET',
      '/me/trips',
      query: since == null ? null : {'since': since.toUtc().toIso8601String()},
    );
    return _list(json).map(Trip.fromJson).toList();
  }

  @override
  Future<List<Vehicle>> vehicles() async {
    final json = await _send('GET', '/vehicles', query: {'status': 'active'});
    return _list(json).map(Vehicle.fromJson).toList();
  }

  @override
  Future<UploadTicket> registerMedia(JsonMap body) async =>
      UploadTicket.fromJson(
        asJsonMap(await _send('POST', '/media', body: body)),
      );

  @override
  Future<void> uploadBytes(
    String url,
    Map<String, String> headers,
    Uint8List bytes,
  ) async {
    final http.Response res;
    try {
      res = await _http
          .put(Uri.parse(url), headers: headers, body: bytes)
          .timeout(timeout * 3);
    } on Object catch (error) {
      throw ApiException(status: 0, code: 'NETWORK', message: '$error');
    }
    if (res.statusCode >= 300) {
      throw ApiException(
        status: res.statusCode,
        code: 'UPLOAD_FAILED',
        message: 'Storage rejected the upload (${res.statusCode})',
      );
    }
  }

  @override
  Future<void> completeMedia(String mediaId) =>
      _send('POST', '/media/$mediaId/complete');

  @override
  Future<Trip> tripCommand(
    String tripId,
    String command,
    String idempotencyKey,
    JsonMap body,
  ) async => Trip.fromJson(
    asJsonMap(
      await _send(
        'POST',
        '/trips/$tripId/$command',
        body: body,
        headers: {'Idempotency-Key': idempotencyKey},
      ),
    ),
  );

  @override
  Future<Trip> addCharge(String tripId, JsonMap body) async => Trip.fromJson(
    asJsonMap(await _send('POST', '/trips/$tripId/charges', body: body)),
  );

  @override
  Future<Trip> addCollection(String tripId, JsonMap body) async =>
      Trip.fromJson(
        asJsonMap(
          await _send('POST', '/trips/$tripId/collections', body: body),
        ),
      );

  @override
  Future<void> recordFuelFill(JsonMap body) =>
      _send('POST', '/fuel-fills', body: body);

  @override
  Future<GpsBatchResult> uploadGps(String tripId, List<JsonMap> points) async =>
      GpsBatchResult.fromJson(
        asJsonMap(
          await _send(
            'POST',
            '/trips/$tripId/gps-batches',
            body: {'points': points},
          ),
        ),
      );

  List<JsonMap> _list(Object? json) {
    if (json is! List<Object?>) {
      throw JsonShapeError('Expected a list, got $json');
    }
    return json.map(asJsonMap).toList();
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String> headers = const {},
    bool auth = true,
  }) async {
    Future<http.Response> attempt() async {
      final token = auth ? (await sessions.load())?.accessToken : null;
      final request = http.Request(method, _uri(path, query))
        ..headers.addAll({
          'Accept': 'application/json',
          if (body != null) 'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...headers,
        });
      if (body != null) request.body = jsonEncode(body);
      try {
        return await http.Response.fromStream(
          await _http.send(request).timeout(timeout),
        );
      } on Object catch (error) {
        throw ApiException(status: 0, code: 'NETWORK', message: '$error');
      }
    }

    var res = await attempt();
    if (auth && res.statusCode == 401 && _code(res) == 'TOKEN_EXPIRED') {
      await _refresh();
      res = await attempt();
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    throw _error(res);
  }

  /// One refresh at a time; concurrent callers wait for the same result.
  Future<String> _refresh() => _refreshing ??= () async {
    try {
      final current = await sessions.load();
      if (current == null) {
        throw ApiException(
          status: 401,
          code: 'UNAUTHENTICATED',
          message: 'Not signed in',
        );
      }
      final res = await _http
          .post(
            _uri('/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': current.refreshToken}),
          )
          .timeout(timeout);
      if (res.statusCode != 200) {
        if (res.statusCode == 401) {
          await sessions.clear();
          onSignedOut?.call();
        }
        throw _error(res);
      }
      final session = Session.fromJson(asJsonMap(jsonDecode(res.body)));
      await sessions.save(session);
      return session.accessToken;
    } finally {
      _refreshing = null;
    }
  }();

  String? _code(http.Response res) {
    try {
      return asJsonMap(
        asJsonMap(jsonDecode(res.body))['error'],
      ).strOrNull('code');
    } on Object {
      return null;
    }
  }

  ApiException _error(http.Response res) {
    try {
      final error = asJsonMap(asJsonMap(jsonDecode(res.body))['error']);
      return ApiException(
        status: res.statusCode,
        code: error.str('code'),
        message: error.str('message'),
        details: error['details'],
        requestId: error.strOrNull('requestId'),
      );
    } on Object {
      return ApiException(
        status: res.statusCode,
        code: 'HTTP_${res.statusCode}',
        message: res.reasonPhrase ?? 'Request failed',
      );
    }
  }
}
