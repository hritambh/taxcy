import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api.dart';

/// Phone number → OTP → signed in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  String get _e164 => '+91${_phone.text.trim()}';

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (error) {
      setState(() => _error = _friendly(error));
    } on Object catch (error) {
      setState(() => _error = 'Something went wrong: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(ApiException error) => switch (error.code) {
    'NETWORK' => 'No connection. Check your internet and try again.',
    'RATE_LIMITED' => 'Too many attempts. Wait a few minutes and try again.',
    'OTP_INVALID' => 'That code is not right. Check the SMS and try again.',
    'OTP_EXPIRED' => 'The code expired. Request a new one.',
    'VALIDATION_FAILED' => 'Check the number and try again.',
    _ => error.message,
  };

  Future<void> _sendCode() async {
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text.trim())) {
      setState(() => _error = 'Enter your 10-digit mobile number');
      return;
    }
    await _run(() async {
      await ref.read(authProvider.notifier).requestOtp(_e164);
      setState(() => _codeSent = true);
    });
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    await _run(
      () => ref.read(authProvider.notifier).verify(_e164, _code.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Text('Taxcy Driver', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? 'Enter the code we sent to +91 ${_phone.text.trim()}'
                  : 'Sign in with the mobile number your fleet owner registered.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            TextField(
              key: const Key('phone-field'),
              controller: _phone,
              enabled: !_codeSent && !_busy,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+91 ',
                border: OutlineInputBorder(),
              ),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextField(
                key: const Key('code-field'),
                controller: _code,
                enabled: !_busy,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: '6-digit code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                key: const Key('login-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('login-submit'),
              onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_codeSent ? 'Verify and sign in' : 'Send code'),
            ),
            if (_codeSent)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _codeSent = false;
                        _code.clear();
                        _error = null;
                      }),
                child: const Text('Use a different number'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Signed in, but this account isn't a driver in the active organization.
class NotADriverScreen extends ConsumerWidget {
  const NotADriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'This app is for drivers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your number is not registered as a driver in any fleet yet. '
              'Ask your fleet owner to add you as a driver, or use the Taxcy admin '
              'website if you manage the fleet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}
