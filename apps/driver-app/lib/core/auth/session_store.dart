import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../api/json.dart';
import '../api/models.dart';

/// Where the session (access + refresh token) and this install's device id live.
abstract class SessionStore {
  Future<Session?> load();
  Future<void> save(Session session);
  Future<void> clear();

  /// A UUID generated once per install; sent at login and with every photo.
  Future<String> deviceId();
}

/// Keychain / Android Keystore-backed storage.
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'session_v1';
  static const _deviceKey = 'device_id_v1';
  final FlutterSecureStorage _storage;
  Session? _cached;

  @override
  Future<Session?> load() async {
    if (_cached != null) return _cached;
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    try {
      return _cached = Session.fromJson(asJsonMap(jsonDecode(raw)));
    } on Object {
      await _storage.delete(key: _sessionKey);
      return null;
    }
  }

  @override
  Future<void> save(Session session) async {
    _cached = session;
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _sessionKey);
  }

  @override
  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await _storage.write(key: _deviceKey, value: id);
    return id;
  }
}

/// For tests and previews.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this._session]);
  Session? _session;
  final String _deviceId = const Uuid().v4();

  @override
  Future<Session?> load() async => _session;
  @override
  Future<void> save(Session session) async => _session = session;
  @override
  Future<void> clear() async => _session = null;
  @override
  Future<String> deviceId() async => _deviceId;
}
