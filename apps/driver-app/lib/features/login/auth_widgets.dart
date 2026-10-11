import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api.dart';
import '../../l10n/app_localizations.dart';
import '../common/errors.dart';
import '../common/format.dart';

/// The API's password rule (libs/contracts Password).
const minPasswordLength = 8;
const maxPasswordLength = 128;

/// "9876543210" → "+919876543210".
String indianE164(String tenDigits) => '+91${tenDigits.trim()}';

String? mobileError(AppLocalizations l, String digits) =>
    RegExp(r'^[6-9]\d{9}$').hasMatch(digits.trim())
    ? null
    : l.enterTenDigitMobile;

String? codeError(AppLocalizations l, String code) =>
    RegExp(r'^\d{6}$').hasMatch(code.trim()) ? null : l.enterSixDigitCode;

/// A new password: 8–128 characters, typed the same twice.
String? newPasswordError(AppLocalizations l, String password, String again) {
  if (password.length < minPasswordLength) return l.passwordTooShort;
  if (password.length > maxPasswordLength) return l.passwordTooLong;
  if (password != again) return l.passwordsDontMatch;
  return null;
}

/// Keeps the 10-digit national number when autofill or a paste brings a
/// country code ("+91 98765 43210") or a trunk zero ("098765 43210").
class IndianMobileFormatter extends TextInputFormatter {
  const IndianMobileFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length > 10 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class PhoneField extends StatelessWidget {
  const PhoneField({
    required this.controller,
    this.enabled = true,
    this.autofocus = false,
    super.key = const Key('phone-field'),
  });

  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    autofocus: autofocus,
    keyboardType: TextInputType.phone,
    textInputAction: TextInputAction.next,
    autofillHints: const [AutofillHints.telephoneNumber],
    inputFormatters: const [IndianMobileFormatter()],
    decoration: InputDecoration(
      labelText: context.l10n.mobileNumber,
      prefixText: '+91 ',
      border: const OutlineInputBorder(),
    ),
  );
}

class CodeField extends StatelessWidget {
  const CodeField({
    required this.controller,
    this.enabled = true,
    this.autofocus = true,
    this.onSubmitted,
    super.key = const Key('code-field'),
  });

  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    autofocus: autofocus,
    keyboardType: TextInputType.number,
    autofillHints: const [AutofillHints.oneTimeCode],
    textInputAction: onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    decoration: InputDecoration(
      labelText: context.l10n.sixDigitCode,
      border: const OutlineInputBorder(),
    ),
  );
}

/// A password box with a show/hide toggle. [isNew] tells password managers to
/// suggest and save a new password rather than fill the saved one.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    this.isNew = false,
    this.enabled = true,
    this.helper,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool isNew;
  final bool enabled;
  final String? helper;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: [
        widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
      ],
      inputFormatters: [LengthLimitingTextInputFormatter(maxPasswordLength)],
      textInputAction: widget.onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      onSubmitted: widget.onSubmitted == null
          ? null
          : (_) => widget.onSubmitted!(),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _visible ? l.hidePassword : l.showPassword,
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

/// The form's main button, with a spinner while it works.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    super.key = const Key('login-submit'),
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label, textAlign: TextAlign.center),
  );
}

class FormError extends StatelessWidget {
  const FormError(this.text, {super.key = const Key('login-error')});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

/// Busy state and translated errors for a sign-in form, plus sending SMS codes
/// with the server's resend countdown.
mixin AuthFormState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  String? error;

  /// The API error code behind [error], for forms that offer a way out
  /// (ACCOUNT_EXISTS, an expired Google link).
  String? errorCode;

  bool codeSent = false;

  /// Seconds until another code can be sent.
  int resendIn = 0;
  Timer? _ticker;

  AuthController get auth => ref.read(authProvider.notifier);

  void showError(String message) => setState(() {
    error = message;
    errorCode = null;
  });

  /// Runs [action] with the spinner on; shows any failure in the user's language.
  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
      errorCode = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          errorCode = e.code;
          error = describe(e);
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => error = errorText(context.l10n, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// How an API error reads in this form; override to reword a code.
  String describe(ApiException e) => e.code == 'VALIDATION_FAILED'
      ? context.l10n.loginCheckNumber
      : errorText(context.l10n, e);

  /// Sends a code to [digits] (10-digit mobile) after checking it.
  Future<void> sendCode(String digits, {bool resend = false}) async {
    final invalid = mobileError(context.l10n, digits);
    if (invalid != null) return showError(invalid);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final sent = context.l10n.codeResent;
    await run(() async {
      final ticket = await auth.requestOtp(indianE164(digits));
      if (!mounted) return;
      setState(() => codeSent = true);
      _countdown(ticket.resendAfterSeconds);
      if (resend) messenger?.showSnackBar(SnackBar(content: Text(sent)));
    });
  }

  /// Back to entering the number.
  void changeNumber() {
    _ticker?.cancel();
    setState(() {
      codeSent = false;
      resendIn = 0;
      error = null;
      errorCode = null;
    });
  }

  void _countdown(int seconds) {
    _ticker?.cancel();
    setState(() => resendIn = seconds);
    if (seconds <= 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => resendIn--);
      if (resendIn <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// "Resend code" once the server allows it, with the seconds left until then.
class ResendCodeButton extends StatelessWidget {
  const ResendCodeButton({
    required this.secondsLeft,
    required this.onPressed,
    super.key = const Key('resend-code'),
  });

  final int secondsLeft;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: secondsLeft > 0 ? null : onPressed,
    child: Text(
      secondsLeft > 0
          ? context.l10n.resendCodeIn(seconds: '$secondsLeft')
          : context.l10n.resendCode,
      textAlign: TextAlign.center,
    ),
  );
}

/// A low-key link under a form ("Forgot password?", "Sign up").
class FormLink extends StatelessWidget {
  const FormLink({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: Text(label, textAlign: TextAlign.center),
  );
}
