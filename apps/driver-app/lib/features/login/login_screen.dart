import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/api.dart';
import '../common/errors.dart';
import '../common/format.dart';
import '../common/language_picker.dart';

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
      setState(() => _error = errorText(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(ApiException error) => error.code == 'VALIDATION_FAILED'
      ? context.l10n.loginCheckNumber
      : errorText(context.l10n, error);

  Future<void> _sendCode() async {
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text.trim())) {
      setState(() => _error = context.l10n.enterTenDigitMobile);
      return;
    }
    await _run(() async {
      await ref.read(authProvider.notifier).requestOtp(_e164);
      setState(() => _codeSent = true);
    });
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _error = context.l10n.enterSixDigitCode);
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TaxcyColors.blue700, TaxcyColors.blue950],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_taxi,
                          color: TaxcyColors.blue700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.appTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const LanguageButton(color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _form(theme),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _form(ThemeData theme) => [
    Text(
      _codeSent
          ? context.l10n.loginCodeSent(phone: '+91 ${_phone.text.trim()}')
          : context.l10n.loginIntro,
      style: theme.textTheme.bodyLarge,
    ),
    const SizedBox(height: 24),
    TextField(
      key: const Key('phone-field'),
      controller: _phone,
      enabled: !_codeSent && !_busy,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: context.l10n.mobileNumber,
        prefixText: '+91 ',
        border: const OutlineInputBorder(),
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
        decoration: InputDecoration(
          labelText: context.l10n.sixDigitCode,
          border: const OutlineInputBorder(),
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
          : Text(
              _codeSent ? context.l10n.verifyAndSignIn : context.l10n.sendCode,
            ),
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
        child: Text(context.l10n.useDifferentNumber),
      ),
  ];
}

/// Signed in, but this number has no driver, owner or manager role in the
/// active organization.
class NoFleetScreen extends ConsumerWidget {
  const NoFleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(actions: const [LanguageButton()]),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              context.l10n.noFleetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.noFleetBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              child: Text(context.l10n.signOut),
            ),
          ],
        ),
      ),
    ),
  );
}
