import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

const _localeKey = 'locale_v1';
const _modeKey = 'app_mode_v1';

/// Preferences read once at startup (main() overrides this); null in tests,
/// which then start from the defaults.
final startupPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

Future<void> _write(
  Future<void> Function(SharedPreferences prefs) write,
) async {
  try {
    await write(await SharedPreferences.getInstance());
  } on Object catch (error) {
    debugPrint('Could not save a preference: $error');
  }
}

/// The language the user picked, or null to follow the phone's language.
final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.watch(startupPreferencesProvider)?.getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  void set(Locale? locale) {
    state = locale;
    unawaited(
      _write(
        (prefs) => locale == null
            ? prefs.remove(_localeKey)
            : prefs.setString(_localeKey, locale.languageCode),
      ),
    );
  }
}

/// Languages offered in the picker, each named in its own script.
Map<String, String> get languageNames => {
  for (final locale in AppLocalizations.supportedLocales)
    locale.languageCode: switch (locale.languageCode) {
      'en' => 'English',
      'hi' => 'हिन्दी',
      final other => other,
    },
};

/// Which screens a member with both staff and driver roles (an owner-driver,
/// DCO) is looking at.
enum AppMode { owner, driver }

final appModeProvider = NotifierProvider<AppModeController, AppMode?>(
  AppModeController.new,
);

class AppModeController extends Notifier<AppMode?> {
  @override
  AppMode? build() =>
      switch (ref.watch(startupPreferencesProvider)?.getString(_modeKey)) {
        'owner' => AppMode.owner,
        'driver' => AppMode.driver,
        _ => null,
      };

  void set(AppMode mode) {
    state = mode;
    unawaited(_write((prefs) => prefs.setString(_modeKey, mode.name)));
  }
}
