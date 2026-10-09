import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/location/gps.dart';

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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.location_on_outlined, size: 56),
            const SizedBox(height: 16),
            Text('Location during trips', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text(
              'Taxcy records your phone\'s location only while a trip is running '
              '(between "Start trip" and "End trip"). A notification is shown the '
              'whole time it is recording.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Your fleet owner uses it to see the route and to check the distance '
              'against the odometer. It is also attached to odometer and receipt '
              'photos. It is not collected when you are off duty.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Route data is kept for up to 12 months and then deleted.',
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _accept,
              child: const Text('I understand, continue'),
            ),
          ],
        ),
      ),
    );
  }
}
