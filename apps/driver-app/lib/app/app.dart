import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/common/consent_screen.dart';
import '../core/api/models.dart';
import '../features/common/widgets.dart';
import '../features/login/login_screen.dart';
import '../features/owner/owner_shell.dart';
import '../features/trips/trips_screen.dart';
import '../l10n/app_localizations.dart';
import 'preferences.dart';
import 'providers.dart';
import 'sync_coordinator.dart';
import 'theme.dart';

class TaxcyDriverApp extends ConsumerWidget {
  const TaxcyDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: buildTheme(),
    // Null follows the phone's language (English when it isn't supported).
    locale: ref.watch(localeProvider),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const _Root(),
  );
}

/// Signed out → login. Signed in: owners and managers get owner mode, drivers
/// their trips (after the first-run location consent). An owner-driver (DCO)
/// switches between the two; the choice is remembered. Anyone else is told to
/// ask their fleet owner.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => const LoginScreen(),
      data: (session) {
        if (session == null) return const LoginScreen();
        final mode = screensFor(session, ref.watch(appModeProvider));
        return switch (mode) {
          // A DCO's trips keep syncing and recording GPS in owner mode.
          AppMode.owner when session.isDriver => const SyncCoordinator(
            child: SyncNoticeListener(child: OwnerShell()),
          ),
          AppMode.owner => const OwnerShell(),
          AppMode.driver => const _DriverHome(),
          null => const NoFleetScreen(),
        };
      },
    );
  }
}

/// Which screens a signed-in member gets: owner mode for staff, the driver
/// screens for drivers, and for someone with both (a DCO) their last choice,
/// starting on the driver screens. Null when they have neither role.
AppMode? screensFor(Session session, AppMode? chosen) {
  if (session.isStaff && session.isDriver) return chosen ?? AppMode.driver;
  if (session.isStaff) return AppMode.owner;
  if (session.isDriver) return AppMode.driver;
  return null;
}

/// The offline-first driver screens: location consent on first run, then the
/// driver's trips with background sync.
class _DriverHome extends ConsumerStatefulWidget {
  const _DriverHome();

  @override
  ConsumerState<_DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends ConsumerState<_DriverHome> {
  bool? _consented;

  @override
  void initState() {
    super.initState();
    if (!ref.read(backgroundWorkProvider)) {
      _consented = true;
      return;
    }
    hasLocationConsent().then((value) {
      if (mounted) setState(() => _consented = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_consented == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_consented == false) {
      return LocationConsentScreen(
        onDone: () => setState(() => _consented = true),
      );
    }
    return const SyncCoordinator(
      child: SyncNoticeListener(child: TripsScreen()),
    );
  }
}
