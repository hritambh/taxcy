import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/api.dart';
import '../../core/api/auth_models.dart';
import '../common/errors.dart';
import '../common/format.dart';
import '../login/auth_widgets.dart';
import '../owner/owner_text.dart' show formatPhone;
import '../owner/owner_widgets.dart';

/// How the signed-in user signs in: their number (SMS code), a password (set or
/// change it here) and a linked Google account. Needs a connection.
class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final account = ref.watch(accountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.accountSecurity)),
      body: RefreshPage(
        onRefresh: () => ref.refresh(accountProvider.future),
        children: [
          AsyncView(
            value: account,
            onRetry: () => ref.invalidate(accountProvider),
            builder: (a) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(title: l.signInMethods, child: _Methods(a)),
                SectionCard(
                  title: a.hasPassword ? l.changePassword : l.setPassword,
                  child: _PasswordForm(
                    key: ValueKey(a.hasPassword),
                    hasPassword: a.hasPassword,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Methods extends StatelessWidget {
  const _Methods(this.account);
  final Account account;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final email = account.email;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone_android),
          title: Text(l.mobileNumber),
          subtitle: Text('${formatPhone(account.phone)}\n${l.smsCodeAlways}'),
          isThreeLine: true,
        ),
        ListTile(
          key: const Key('security-password'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.password),
          title: Text(l.password),
          subtitle: Text(
            account.hasPassword ? l.passwordIsSet : l.passwordNotSet,
          ),
        ),
        ListTile(
          key: const Key('security-google'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: const Text('Google'),
          subtitle: Text(
            !account.googleLinked
                ? l.googleNotLinked
                : email == null
                ? l.googleLinked
                : l.googleLinkedTo(email: email),
          ),
        ),
      ],
    );
  }
}

/// Set a first password, or change it (the current one is needed then).
class _PasswordForm extends ConsumerStatefulWidget {
  const _PasswordForm({required this.hasPassword, super.key});
  final bool hasPassword;

  @override
  ConsumerState<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends ConsumerState<_PasswordForm> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final invalid = widget.hasPassword && _current.text.isEmpty
        ? l.enterPassword
        : newPasswordError(l, _password.text, _again.text);
    setState(() => _error = invalid);
    if (invalid != null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(authApiProvider)
          .changePassword(
            currentPassword: widget.hasPassword ? _current.text : null,
            newPassword: _password.text,
          );
      for (final c in [_current, _password, _again]) {
        c.clear();
      }
      messenger.showSnackBar(SnackBar(content: Text(l.passwordSaved)));
      ref.invalidate(accountProvider);
    } on ApiException catch (e) {
      setState(
        () => _error = e.code == 'INVALID_CREDENTIALS'
            ? l.currentPasswordWrong
            : errorText(l, e),
      );
    } on Object catch (e) {
      setState(() => _error = errorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const gap = SizedBox(height: 16);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.hasPassword) ...[
            Text(
              l.setPasswordIntro,
              style: const TextStyle(color: TaxcyColors.muted),
            ),
            gap,
          ],
          if (widget.hasPassword) ...[
            PasswordField(
              key: const Key('current-password-field'),
              controller: _current,
              label: l.currentPassword,
              enabled: !_busy,
            ),
            gap,
          ],
          PasswordField(
            key: const Key('new-password-field'),
            controller: _password,
            label: l.newPassword,
            helper: l.passwordHint,
            isNew: true,
            enabled: !_busy,
          ),
          gap,
          PasswordField(
            key: const Key('confirm-password-field'),
            controller: _again,
            label: l.confirmPassword,
            isNew: true,
            enabled: !_busy,
            onSubmitted: _save,
          ),
          if (_error != null)
            FormError(_error!, key: const Key('password-error')),
          gap,
          SubmitButton(
            key: const Key('save-password'),
            label: l.savePassword,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
