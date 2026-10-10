import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/models.dart';
import '../common/errors.dart';
import '../common/format.dart';
import 'owner_providers.dart';
import 'owner_text.dart';

/// Content width on wide screens (the web build at desktop size).
const ownerMaxWidth = 960.0;

/// Centres [child] and caps its width, so lists don't stretch across a desktop.
class PageWidth extends StatelessWidget {
  const PageWidth({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: ownerMaxWidth),
      child: child,
    ),
  );
}

/// Loading spinner, an error with a retry button, or the data. Owner mode is
/// online-first, so every screen goes through this.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.value,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => switch (value) {
    AsyncData(:final value) => builder(value),
    AsyncError(:final error) => ErrorPanel(error: error, onRetry: onRetry),
    _ => const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    ),
  };
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({required this.error, required this.onRetry, super.key});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 8),
        Text(context.l10n.loadFailed, textAlign: TextAlign.center),
        Text(
          errorText(context.l10n, error),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.retry),
        ),
      ],
    ),
  );
}

/// A scrollable page with pull-to-refresh.
class RefreshPage extends StatelessWidget {
  const RefreshPage({
    required this.onRefresh,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 96),
    super.key,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [for (final child in children) PageWidth(child: child)],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: TaxcyColors.muted),
    ),
  );
}

/// A titled white card with optional actions on the right of the title.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.title,
    this.actions = const [],
    super.key,
  });

  final String? title;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  else
                    const Spacer(),
                  ...actions,
                ],
              ),
            ),
          child,
        ],
      ),
    ),
  );
}

/// A small label above a value, for summary grids.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.hint,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final String? hint;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: TaxcyColors.muted, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: valueColor,
          ),
        ),
        if (hint != null)
          Text(
            hint!,
            style: const TextStyle(color: TaxcyColors.muted, fontSize: 12),
          ),
      ],
    ),
  );
}

class StatGrid extends StatelessWidget {
  const StatGrid(this.children, {super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 12, runSpacing: 12, children: children);
}

/// A coloured pill: green for good, amber for attention, red for bad, blue otherwise.
class ToneChip extends StatelessWidget {
  const ToneChip(this.text, {this.tone = Tone.neutral, super.key});
  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      Tone.success => (Colors.green.shade50, Colors.green.shade800),
      Tone.warning => (Colors.amber.shade50, Colors.amber.shade900),
      Tone.danger => (Colors.red.shade50, Colors.red.shade800),
      Tone.brand => (TaxcyColors.blue100, TaxcyColors.blue900),
      Tone.neutral => (TaxcyColors.blue50, TaxcyColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum Tone { success, warning, danger, brand, neutral }

Tone severityTone(String severity) => switch (severity) {
  'critical' => Tone.danger,
  'warning' => Tone.warning,
  _ => Tone.brand,
};

class SeverityChip extends StatelessWidget {
  const SeverityChip(this.severity, {super.key});
  final String severity;

  @override
  Widget build(BuildContext context) => ToneChip(
    severityLabel(context.l10n, severity),
    tone: severityTone(severity),
  );
}

/// Runs an owner action: shows the error (translated) in a snackbar if it
/// fails, and [done] if given when it succeeds. Returns whether it worked.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  try {
    await action();
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on Object catch (error) {
    messenger.showSnackBar(
      SnackBar(
        key: const Key('action-error'),
        content: Text(errorText(l, error)),
      ),
    );
    return false;
  }
}

/// Pushes [screen] on the root navigator.
Future<T?> openScreen<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

/// A dialog asking for one line (or paragraph) of text; null when cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirm,
  String? intro,
  String? hint,
  String initial = '',
  bool required = true,
  bool destructive = false,
  TextInputType keyboard = TextInputType.text,
  String? Function(String value)? validate,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextDialog(
    title: title,
    label: label,
    confirm: confirm,
    intro: intro,
    hint: hint,
    initial: initial,
    required: required,
    destructive: destructive,
    keyboard: keyboard,
    validate: validate,
  ),
);

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.confirm,
    required this.initial,
    required this.required,
    required this.destructive,
    required this.keyboard,
    this.intro,
    this.hint,
    this.validate,
  });

  final String title;
  final String label;
  final String confirm;
  final String? intro;
  final String? hint;
  final String initial;
  final bool required;
  final bool destructive;
  final TextInputType keyboard;
  final String? Function(String value)? validate;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _text.text.trim();
    final error = widget.required && value.isEmpty
        ? context.l10n.required
        : widget.validate?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.intro != null) ...[
            Text(widget.intro!),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const Key('dialog-text'),
            controller: _text,
            autofocus: true,
            keyboardType: widget.keyboard,
            maxLines: widget.keyboard == TextInputType.text ? 3 : 1,
            minLines: 1,
            decoration: InputDecoration(
              labelText: widget.label,
              helperText: widget.hint,
              errorText: _error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.back),
      ),
      FilledButton(
        key: const Key('dialog-confirm'),
        style: widget.destructive
            ? FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              )
            : null,
        onPressed: _submit,
        child: Text(widget.confirm),
      ),
    ],
  );
}

/// Yes/no confirmation; true when confirmed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(dialog.l10n.back),
          ),
          FilledButton(
            key: const Key('confirm-yes'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;

/// A photo stored on the server, fetched through a short-lived signed URL.
class MediaPhoto extends ConsumerWidget {
  const MediaPhoto(this.mediaId, {this.height = 160, super.key});
  final String mediaId;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(mediaUrlProvider(mediaId));
    final notUploaded = Container(
      height: 56,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: TaxcyColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_not_supported_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.photoNotUploaded,
              style: const TextStyle(fontSize: 12, color: TaxcyColors.muted),
            ),
          ),
        ],
      ),
    );
    return switch (url) {
      AsyncData(:final value) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          value.url,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => notUploaded,
        ),
      ),
      AsyncError() => notUploaded,
      _ => SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// Picks one of the fleet's active vehicles ('' for none, when [noneLabel] is set).
class VehiclePicker extends ConsumerWidget {
  const VehiclePicker({
    required this.value,
    required this.onChanged,
    required this.label,
    this.noneLabel,
    this.activeOnly = true,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? noneLabel;
  final bool activeOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(fleetVehiclesProvider).value ?? const [];
    final list = activeOnly
        ? vehicles.where((v) => v.isActive || v.id == value).toList()
        : vehicles;
    return DropdownButtonFormField<String?>(
      key: ValueKey('vehicle-picker-$label-${list.length}'),
      initialValue: list.any((v) => v.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (noneLabel != null)
          DropdownMenuItem<String?>(child: Text(noneLabel!)),
        for (final Vehicle v in list)
          DropdownMenuItem<String?>(
            value: v.id,
            child: Text(
              '${formatRegistration(v.registrationNo)} · ${v.model}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Picks one of the fleet's active drivers ('' for none, when [noneLabel] is set).
class DriverPicker extends ConsumerWidget {
  const DriverPicker({
    required this.value,
    required this.onChanged,
    required this.label,
    this.noneLabel,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? noneLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = (ref.watch(driversProvider).value ?? const [])
        .where((d) => d.isActive || d.id == value)
        .toList();
    return DropdownButtonFormField<String?>(
      key: ValueKey('driver-picker-$label-${drivers.length}'),
      initialValue: drivers.any((d) => d.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (noneLabel != null)
          DropdownMenuItem<String?>(child: Text(noneLabel!)),
        for (final d in drivers)
          DropdownMenuItem<String?>(value: d.id, child: Text(d.name)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Picks a calendar date; [value] and the result are YYYY-MM-DD.
Future<String?> pickIsoDate(
  BuildContext context, {
  String? value,
  DateTime? first,
  DateTime? last,
}) async {
  final now = DateTime.now();
  final initial = value == null ? now : DateTime.parse(value);
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(now.year - 5),
    lastDate: last ?? DateTime(now.year + 10),
  );
  if (picked == null) return null;
  return '${picked.year.toString().padLeft(4, '0')}-'
      '${picked.month.toString().padLeft(2, '0')}-'
      '${picked.day.toString().padLeft(2, '0')}';
}

/// Unawaited navigation and refreshes, for onTap handlers.
void fire(Future<void> future) => unawaited(future);

/// Whether the signed-in member is the owner (managers can't change settings
/// or pay; the server enforces it too).
final isOwnerProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).value?.isOwner ?? false,
);
