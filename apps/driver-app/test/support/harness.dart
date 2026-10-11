import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxcy_driver/app/preferences.dart';
import 'package:taxcy_driver/app/providers.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/auth/session_store.dart';
import 'package:taxcy_driver/core/sync/sync_engine.dart';
import 'package:taxcy_driver/features/owner/trips/route_map.dart';
import 'package:taxcy_driver/l10n/app_localizations.dart';

import 'fakes.dart';
import 'owner_fakes.dart';

/// Everything a widget test needs: in-memory database, fake API, a session and
/// saved preferences (English unless a test asks for another language).
class Harness {
  Harness._(this.sessions, this.prefs);

  static Future<Harness> create({
    Session? session,
    String language = 'en',
    Map<String, Object> preferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'locale_v1': language,
      ...preferences,
    });
    return Harness._(
      InMemorySessionStore(session),
      await SharedPreferences.getInstance(),
    );
  }

  final db = memoryDb();
  final api = FakeApi();
  final owner = FakeOwnerApi();
  final InMemorySessionStore sessions;
  final SharedPreferences prefs;
  late final engine = SyncEngine(
    db: db,
    api: api,
    readPhoto: (_) async => Uint8List(0),
    deviceId: sessions.deviceId,
  );

  Locale get locale => Locale(prefs.getString('locale_v1') ?? 'en');

  Widget wrap(Widget child) => ProviderScope(
    retry: (_, _) => null,
    overrides: [
      databaseProvider.overrideWithValue(db),
      apiProvider.overrideWithValue(api),
      ownerApiProvider.overrideWithValue(owner),
      mapTilesProvider.overrideWithValue(false),
      sessionStoreProvider.overrideWithValue(sessions),
      syncEngineProvider.overrideWithValue(engine),
      backgroundWorkProvider.overrideWithValue(false),
      startupPreferencesProvider.overrideWithValue(prefs),
      photoStoreProvider.overrideWithValue(MemoryPhotoStore()),
      photoCaptureProvider.overrideWithValue(
        (context, kind) async => fakePhoto('captured-$kind', kind: kind),
      ),
    ],
    child: child,
  );

  /// One screen inside a localized MaterialApp.
  Widget screen(Widget home) => wrap(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  Future<void> dispose() => db.close();
}

/// Lets real async work (drift queries, stream emissions) run, then rebuilds.
/// pumpAndSettle alone can't: drift completes outside the test's fake clock, and
/// screens show a spinner (an endless animation) until it does.
Future<void> settle(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}
