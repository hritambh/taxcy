import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/api.dart';
import '../../core/api/auth_models.dart';
import '../common/errors.dart';
import '../common/format.dart';
import '../common/language_picker.dart';
import '../owner/owner_widgets.dart' show askText;
import 'auth_forms.dart';

/// Signing in: mobile number + password by default, or an SMS code, sign-up,
/// forgot password, and Google when the server offers it. Every step lives in
/// the same card, so a successful sign-in just replaces this screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Shared by every step, so the number typed once carries over.
  final _phone = TextEditingController();
  LoginFlow _flow = LoginFlow.password;
  GooglePhoneRequired? _link;

  bool _googleBusy = false;
  String? _googleError;
  StreamSubscription<String>? _googleTokens;

  @override
  void initState() {
    super.initState();
    // On the web, Google's own button reports its sign-ins as a stream.
    _googleTokens = ref
        .read(googleAuthProvider)
        .idTokens
        .listen(
          (token) => _google(() async => token),
          onError: (Object _) => _showGoogleError(null),
        );
  }

  @override
  void dispose() {
    _googleTokens?.cancel();
    _phone.dispose();
    super.dispose();
  }

  void _open(LoginFlow flow) => setState(() {
    _flow = flow;
    _googleError = null;
  });

  void _showGoogleError(Object? error) {
    if (!mounted) return;
    setState(
      () => _googleError = error is ApiException
          ? errorText(context.l10n, error)
          : context.l10n.googleUnavailable,
    );
  }

  /// Signs in with the ID token [getToken] produces (null: the user backed out).
  /// A first Google sign-in moves on to verifying a phone.
  Future<void> _google(Future<String?> Function() getToken) async {
    if (_googleBusy) return;
    setState(() {
      _googleBusy = true;
      _googleError = null;
    });
    try {
      final token = await getToken();
      if (token == null) return;
      final link = await ref.read(authProvider.notifier).googleSignIn(token);
      if (link != null && mounted) {
        setState(() {
          _link = link;
          _flow = LoginFlow.googleLink;
        });
      }
    } on Object catch (error) {
      debugPrint('Google sign-in failed: $error');
      _showGoogleError(error);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  /// The server's local stand-in for Google: any email signs in as that
  /// "Google account".
  Future<void> _googleDev() async {
    final l = context.l10n;
    final email = await askText(
      context,
      title: l.googleLocalTest,
      intro: l.googleLocalTestIntro,
      label: l.email,
      confirm: l.continueAction,
      keyboard: TextInputType.emailAddress,
      validate: (value) =>
          RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(value) ? null : l.enterEmail,
    );
    if (email == null) return;
    await _google(() async => 'dev-google:$email');
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
                        children: [
                          _form(),
                          if (_flow == LoginFlow.password ||
                              _flow == LoginFlow.sms)
                            _googleSection(),
                        ],
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

  Widget _form() => switch (_flow) {
    LoginFlow.password => PasswordLoginForm(
      key: const ValueKey(LoginFlow.password),
      phone: _phone,
      onOpen: _open,
    ),
    LoginFlow.sms => SmsLoginForm(
      key: const ValueKey(LoginFlow.sms),
      phone: _phone,
      onOpen: _open,
    ),
    LoginFlow.signUp => SignUpForm(
      key: const ValueKey(LoginFlow.signUp),
      phone: _phone,
      onOpen: _open,
    ),
    LoginFlow.reset => ResetPasswordForm(
      key: const ValueKey(LoginFlow.reset),
      phone: _phone,
      onOpen: _open,
    ),
    LoginFlow.googleLink => GoogleLinkForm(
      key: ValueKey(_link!.linkToken),
      phone: _phone,
      link: _link!,
      onCancel: () => setState(() {
        _link = null;
        _flow = LoginFlow.password;
      }),
    ),
  };

  /// "or" and the Google button, when the server offers Google. Hidden while
  /// the server can't be reached: password and SMS code still work.
  Widget _googleSection() {
    final option = ref.watch(googleOptionProvider).value ?? GoogleOption.hidden;
    if (option == GoogleOption.hidden) return const SizedBox.shrink();
    final l = context.l10n;
    final google = ref.watch(googleAuthProvider);
    final Widget button;
    if (option == GoogleOption.dev) {
      button = OutlinedButton.icon(
        key: const Key('google-dev'),
        onPressed: _googleBusy ? null : _googleDev,
        icon: const Icon(Icons.science_outlined),
        label: Text(l.googleLocalTest),
      );
    } else if (google.supportsAuthenticate) {
      button = OutlinedButton.icon(
        key: const Key('google-sign-in'),
        onPressed: _googleBusy ? null : () => _google(google.authenticate),
        icon: const _GoogleMark(),
        label: Text(l.continueWithGoogle),
      );
    } else {
      button = Center(
        child: google.button(
          locale: Localizations.localeOf(context).languageCode,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l.orDivider,
                style: const TextStyle(color: TaxcyColors.muted),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        if (_googleBusy)
          const Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          button,
        if (_googleError != null) ...[
          const SizedBox(height: 12),
          Text(
            _googleError!,
            key: const Key('google-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

/// A plain "G" for the Google button (no brand artwork is bundled).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: TaxcyColors.blue700,
    ),
  );
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
