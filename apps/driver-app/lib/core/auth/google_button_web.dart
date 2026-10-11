import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Google's own sign-in button: on the web, Google Identity Services only signs
/// in from a button it renders itself. [locale] is the app's language code.
Widget googleWebButton({String? locale}) => web.renderButton(
  configuration: web.GSIButtonConfiguration(
    type: web.GSIButtonType.standard,
    theme: web.GSIButtonTheme.outline,
    size: web.GSIButtonSize.large,
    text: web.GSIButtonText.continueWith,
    shape: web.GSIButtonShape.pill,
    locale: locale,
  ),
);
