import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/auth_models.dart';
import '../common/format.dart';
import 'auth_widgets.dart';

/// The login screen's steps. Each is a form inside the same card, so signing in
/// from any of them simply replaces the login screen.
enum LoginFlow { password, sms, signUp, reset, googleLink }

typedef OpenFlow = void Function(LoginFlow flow);

const _gap = SizedBox(height: 16);

Widget _intro(BuildContext context, String text, {String? title}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (title != null) ...[
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
    ],
    Text(text, style: Theme.of(context).textTheme.bodyLarge),
    const SizedBox(height: 24),
  ],
);

/// Mobile number + password: the default way in.
class PasswordLoginForm extends ConsumerStatefulWidget {
  const PasswordLoginForm({
    required this.phone,
    required this.onOpen,
    super.key,
  });

  final TextEditingController phone;
  final OpenFlow onOpen;

  @override
  ConsumerState<PasswordLoginForm> createState() => _PasswordLoginFormState();
}

class _PasswordLoginFormState extends ConsumerState<PasswordLoginForm>
    with AuthFormState {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final invalid = mobileError(l, widget.phone.text);
    if (invalid != null) return showError(invalid);
    if (_password.text.isEmpty) return showError(l.enterPassword);
    await run(
      () => auth.passwordLogin(indianE164(widget.phone.text), _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _intro(context, l.loginIntro),
          PhoneField(controller: widget.phone, enabled: !busy),
          _gap,
          PasswordField(
            key: const Key('password-field'),
            controller: _password,
            label: l.password,
            enabled: !busy,
            onSubmitted: _submit,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FormLink(
              key: const Key('go-forgot'),
              label: l.forgotPassword,
              onPressed: busy ? null : () => widget.onOpen(LoginFlow.reset),
            ),
          ),
          if (error != null) FormError(error!),
          const SizedBox(height: 8),
          SubmitButton(label: l.logIn, busy: busy, onPressed: _submit),
          const SizedBox(height: 8),
          FormLink(
            key: const Key('use-sms'),
            label: l.useSmsCodeInstead,
            onPressed: busy ? null : () => widget.onOpen(LoginFlow.sms),
          ),
          FormLink(
            key: const Key('go-sign-up'),
            label: l.newHereSignUp,
            onPressed: busy ? null : () => widget.onOpen(LoginFlow.signUp),
          ),
        ],
      ),
    );
  }
}

/// Mobile number → SMS code → signed in (creates the user on first login).
class SmsLoginForm extends ConsumerStatefulWidget {
  const SmsLoginForm({required this.phone, required this.onOpen, super.key});

  final TextEditingController phone;
  final OpenFlow onOpen;

  @override
  ConsumerState<SmsLoginForm> createState() => _SmsLoginFormState();
}

class _SmsLoginFormState extends ConsumerState<SmsLoginForm>
    with AuthFormState {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final invalid = codeError(context.l10n, _code.text);
    if (invalid != null) return showError(invalid);
    await run(
      () => auth.verify(indianE164(widget.phone.text), _code.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _intro(
            context,
            codeSent
                ? l.loginCodeSent(phone: '+91 ${widget.phone.text.trim()}')
                : l.loginIntro,
          ),
          PhoneField(controller: widget.phone, enabled: !codeSent && !busy),
          if (codeSent) ...[
            _gap,
            CodeField(controller: _code, enabled: !busy, onSubmitted: _verify),
          ],
          if (error != null) FormError(error!),
          const SizedBox(height: 24),
          SubmitButton(
            label: codeSent ? l.verifyAndSignIn : l.sendCode,
            busy: busy,
            onPressed: codeSent ? _verify : () => sendCode(widget.phone.text),
          ),
          if (codeSent) ...[
            ResendCodeButton(
              secondsLeft: resendIn,
              onPressed: busy
                  ? null
                  : () => sendCode(widget.phone.text, resend: true),
            ),
            FormLink(
              label: l.useDifferentNumber,
              onPressed: busy
                  ? null
                  : () {
                      _code.clear();
                      changeNumber();
                    },
            ),
          ],
          FormLink(
            key: const Key('use-password'),
            label: l.usePasswordInstead,
            onPressed: busy ? null : () => widget.onOpen(LoginFlow.password),
          ),
        ],
      ),
    );
  }
}

/// The part shared by sign-up, reset and Google link: once the number is
/// entered, a code is sent; then the code (and whatever else the form needs).
mixin _CodeStepForm<T extends ConsumerStatefulWidget> on AuthFormState<T> {
  final code = TextEditingController();

  TextEditingController get phoneField;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  /// The number field, then (once a code is sent) the code field and [extra].
  List<Widget> codeStep(List<Widget> extra) => [
    PhoneField(controller: phoneField, enabled: !codeSent && !busy),
    if (codeSent) ...[_gap, CodeField(controller: code, enabled: !busy)],
    if (codeSent) ...extra,
  ];

  /// "Resend code" and "Use a different number", once a code is sent.
  List<Widget> codeLinks() => [
    if (codeSent) ...[
      ResendCodeButton(
        secondsLeft: resendIn,
        onPressed: busy ? null : () => sendCode(phoneField.text, resend: true),
      ),
      FormLink(
        label: context.l10n.useDifferentNumber,
        onPressed: busy
            ? null
            : () {
                code.clear();
                changeNumber();
              },
      ),
    ],
  ];
}

/// New password and its confirmation.
List<Widget> _newPasswordFields(
  BuildContext context, {
  required TextEditingController password,
  required TextEditingController again,
  required bool enabled,
  required VoidCallback onSubmitted,
}) => [
  _gap,
  PasswordField(
    key: const Key('new-password-field'),
    controller: password,
    label: context.l10n.newPassword,
    helper: context.l10n.passwordHint,
    isNew: true,
    enabled: enabled,
  ),
  _gap,
  PasswordField(
    key: const Key('confirm-password-field'),
    controller: again,
    label: context.l10n.confirmPassword,
    isNew: true,
    enabled: enabled,
    onSubmitted: onSubmitted,
  ),
];

/// Mobile number → SMS code + name + password → signed in.
class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({required this.phone, required this.onOpen, super.key});

  final TextEditingController phone;
  final OpenFlow onOpen;

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm>
    with AuthFormState, _CodeStepForm {
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();

  @override
  TextEditingController get phoneField => widget.phone;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final invalid =
        codeError(l, code.text) ??
        newPasswordError(l, _password.text, _again.text);
    if (invalid != null) return showError(invalid);
    final name = _name.text.trim();
    await run(
      () => auth.signUp(
        phone: indianE164(widget.phone.text),
        code: code.text.trim(),
        password: _password.text,
        name: name.isEmpty ? null : name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _intro(
            context,
            codeSent
                ? l.loginCodeSent(phone: '+91 ${widget.phone.text.trim()}')
                : l.signUpIntro,
            title: l.signUpTitle,
          ),
          ...codeStep([
            _gap,
            TextField(
              key: const Key('name-field'),
              controller: _name,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                labelText: l.yourNameOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            ..._newPasswordFields(
              context,
              password: _password,
              again: _again,
              enabled: !busy,
              onSubmitted: _submit,
            ),
          ]),
          if (error != null) FormError(error!),
          if (errorCode == 'ACCOUNT_EXISTS') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('account-exists-log-in'),
                  onPressed: () => widget.onOpen(LoginFlow.password),
                  child: Text(l.logIn),
                ),
                OutlinedButton(
                  key: const Key('account-exists-reset'),
                  onPressed: () => widget.onOpen(LoginFlow.reset),
                  child: Text(l.resetPassword),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SubmitButton(
            label: codeSent ? l.createAccount : l.sendCode,
            busy: busy,
            onPressed: codeSent ? _submit : () => sendCode(widget.phone.text),
          ),
          ...codeLinks(),
          FormLink(
            key: const Key('go-log-in'),
            label: l.haveAccountLogIn,
            onPressed: busy ? null : () => widget.onOpen(LoginFlow.password),
          ),
        ],
      ),
    );
  }
}

/// Forgot password: mobile number → SMS code + new password → signed in.
class ResetPasswordForm extends ConsumerStatefulWidget {
  const ResetPasswordForm({
    required this.phone,
    required this.onOpen,
    super.key,
  });

  final TextEditingController phone;
  final OpenFlow onOpen;

  @override
  ConsumerState<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends ConsumerState<ResetPasswordForm>
    with AuthFormState, _CodeStepForm {
  final _password = TextEditingController();
  final _again = TextEditingController();

  @override
  TextEditingController get phoneField => widget.phone;

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final invalid =
        codeError(l, code.text) ??
        newPasswordError(l, _password.text, _again.text);
    if (invalid != null) return showError(invalid);
    await run(
      () => auth.resetPassword(
        phone: indianE164(widget.phone.text),
        code: code.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _intro(
            context,
            codeSent
                ? l.loginCodeSent(phone: '+91 ${widget.phone.text.trim()}')
                : l.resetPasswordIntro,
            title: l.resetPasswordTitle,
          ),
          ...codeStep(
            _newPasswordFields(
              context,
              password: _password,
              again: _again,
              enabled: !busy,
              onSubmitted: _submit,
            ),
          ),
          if (error != null) FormError(error!),
          const SizedBox(height: 24),
          SubmitButton(
            label: codeSent ? l.saveAndLogIn : l.sendCode,
            busy: busy,
            onPressed: codeSent ? _submit : () => sendCode(widget.phone.text),
          ),
          ...codeLinks(),
          FormLink(
            key: const Key('go-log-in'),
            label: l.backToLogIn,
            onPressed: busy ? null : () => widget.onOpen(LoginFlow.password),
          ),
        ],
      ),
    );
  }
}

/// A first Google sign-in: verify a mobile number by SMS code, and the Google
/// account is linked to it (the number is how fleets know their people).
class GoogleLinkForm extends ConsumerStatefulWidget {
  const GoogleLinkForm({
    required this.phone,
    required this.link,
    required this.onCancel,
    super.key,
  });

  final TextEditingController phone;
  final GooglePhoneRequired link;

  /// Back to the login screen (also when the link has expired).
  final VoidCallback onCancel;

  @override
  ConsumerState<GoogleLinkForm> createState() => _GoogleLinkFormState();
}

class _GoogleLinkFormState extends ConsumerState<GoogleLinkForm>
    with AuthFormState, _CodeStepForm {
  @override
  TextEditingController get phoneField => widget.phone;

  /// The link token is gone (expired, or used up by a conflict): only a new
  /// Google sign-in helps.
  bool get _mustStartAgain =>
      errorCode == 'GOOGLE_TOKEN_INVALID' ||
      errorCode == 'GOOGLE_ACCOUNT_CONFLICT';

  Future<void> _verify() async {
    final invalid = codeError(context.l10n, code.text);
    if (invalid != null) return showError(invalid);
    await run(
      () => auth.googleLink(
        linkToken: widget.link.linkToken,
        phone: indianE164(widget.phone.text),
        code: code.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final account = [
      widget.link.name,
      widget.link.email,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _intro(
            context,
            l.verifyPhoneIntro(account: account.isEmpty ? 'Google' : account),
            title: l.verifyPhoneTitle,
          ),
          if (codeSent) ...[
            Text(l.loginCodeSent(phone: '+91 ${widget.phone.text.trim()}')),
            _gap,
          ],
          ...codeStep(const []),
          if (error != null) FormError(error!),
          const SizedBox(height: 24),
          if (_mustStartAgain)
            FilledButton(
              key: const Key('google-start-again'),
              onPressed: widget.onCancel,
              child: Text(l.startAgain),
            )
          else
            SubmitButton(
              label: codeSent ? l.verifyAndSignIn : l.sendCode,
              busy: busy,
              onPressed: codeSent ? _verify : () => sendCode(widget.phone.text),
            ),
          if (!_mustStartAgain) ...codeLinks(),
          FormLink(
            key: const Key('go-log-in'),
            label: l.backToLogIn,
            onPressed: busy ? null : widget.onCancel,
          ),
        ],
      ),
    );
  }
}
