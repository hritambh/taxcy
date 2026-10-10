import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/location/gps.dart';
import 'format.dart';

const _consentKey = 'location_consent_v1';

Future<bool> hasLocationConsent() async =>
    (await SharedPreferences.getInstance()).getBool(_consentKey) ?? false;

/// First-use explanation of why and when location is collected (DPDP Act 2023),
/// shown before the OS permission prompt.
class LocationConsentScreen extends StatelessWidget {
  const LocationConsentScreen({required this.onDone, super.key});
  final VoidCallback onDone;

  Future<void> _accept() async {
    await ensureLocationPermission();
    await (await SharedPreferences.getInstance()).setBool(_consentKey, true);
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.location_on_outlined, size: 56),
            const SizedBox(height: 16),
            Text(l.consentTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(l.consentWhen),
            const SizedBox(height: 12),
            Text(l.consentWhy),
            const SizedBox(height: 12),
            Text(l.consentRetention),
            const SizedBox(height: 32),
            FilledButton(onPressed: _accept, child: Text(l.consentContinue)),
          ],
        ),
      ),
    );
  }
}
