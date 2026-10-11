import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import 'format.dart';

/// Lets the user pick the app's language (or follow the phone's); saved on the phone.
Future<void> showLanguagePicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(localeProvider)?.languageCode ?? '';
  final options = {'': context.l10n.languageDevice, ...languageNames};
  final picked = await showDialog<String>(
    context: context,
    builder: (dialog) => SimpleDialog(
      title: Text(dialog.l10n.language),
      children: [
        for (final entry in options.entries)
          ListTile(
            key: Key('language-${entry.key.isEmpty ? 'device' : entry.key}'),
            leading: Icon(
              entry.key == current
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(entry.value),
            onTap: () => Navigator.of(dialog).pop(entry.key),
          ),
      ],
    ),
  );
  if (picked == null) return;
  ref.read(localeProvider.notifier).set(picked.isEmpty ? null : Locale(picked));
}

/// A translate icon that opens [showLanguagePicker].
class LanguageButton extends ConsumerWidget {
  const LanguageButton({this.color, super.key});
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    key: const Key('language-button'),
    tooltip: context.l10n.language,
    color: color,
    icon: const Icon(Icons.translate),
    onPressed: () => showLanguagePicker(context, ref),
  );
}
