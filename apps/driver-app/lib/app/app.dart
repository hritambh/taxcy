import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/common/consent_screen.dart';
import '../features/common/widgets.dart';
import '../features/login/login_screen.dart';
import '../features/trips/trips_screen.dart';
import 'providers.dart';
import 'sync_coordinator.dart';

class TaxcyDriverApp extends StatelessWidget {
  const TaxcyDriverApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Taxcy Driver',
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF0F766E),
      useMaterial3: true,
    ),
    home: const _Root(),
  );
}

/// Signed out → login; signed in without a driver role → explanation;
/// first run → location consent; otherwise the driver's trips.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
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
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => const LoginScreen(),
      data: (session) {
        if (session == null) return const LoginScreen();
        if (!session.isDriver) return const NotADriverScreen();
        if (_consented == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_consented == false) {
          return LocationConsentScreen(
            onDone: () => setState(() => _consented = true),
          );
        }
        return const SyncCoordinator(
          child: SyncNoticeListener(child: TripsScreen()),
        );
      },
    );
  }
}
