import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/owner_models.dart';
import '../account/account_security_screen.dart';
import '../common/format.dart';
import '../common/language_picker.dart';
import 'owner_providers.dart';
import 'owner_widgets.dart';
import 'pay_rule_editor.dart';

/// Language, audit thresholds and the default driver pay. Only the owner can
/// change the last two; managers see them read-only.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isOwner = ref.watch(isOwnerProvider);
    final audit = ref.watch(auditSettingsProvider);
    final pay = ref.watch(defaultPayRuleProvider);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: RefreshPage(
        onRefresh: () async {
          ref
            ..invalidate(auditSettingsProvider)
            ..invalidate(defaultPayRuleProvider);
          await ref.read(auditSettingsProvider.future);
        },
        children: [
          Card(
            child: ListTile(
              key: const Key('settings-language'),
              leading: const Icon(Icons.translate),
              title: Text(l.language),
              subtitle: Text(
                locale == null
                    ? l.languageDevice
                    : languageNames[locale.languageCode] ?? locale.languageCode,
              ),
              onTap: () => showLanguagePicker(context, ref),
            ),
          ),
          Card(
            child: ListTile(
              key: const Key('settings-account-security'),
              leading: const Icon(Icons.lock_outline),
              title: Text(l.accountSecurity),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  openScreen<void>(context, const AccountSecurityScreen()),
            ),
          ),
          if (!isOwner)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l.settingsOwnerOnly,
                key: const Key('settings-owner-only'),
                style: const TextStyle(color: TaxcyColors.muted),
              ),
            ),
          SectionCard(
            title: l.auditThresholds,
            child: AsyncView(
              value: audit,
              onRetry: () => ref.invalidate(auditSettingsProvider),
              builder: (a) => _AuditForm(initial: a, editable: isOwner),
            ),
          ),
          SectionCard(
            title: l.defaultDriverPay,
            child: AsyncView(
              value: pay,
              onRetry: () => ref.invalidate(defaultPayRuleProvider),
              builder: (p) => _PayForm(initial: p, editable: isOwner),
            ),
          ),
        ],
      ),
    );
  }
}

/// "30, 7, 1" → [30, 7, 1]; null when any part isn't a whole number.
List<int>? parseDayList(String text) {
  final parts = text.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty);
  final days = [for (final p in parts) int.tryParse(p)];
  return days.contains(null) ? null : days.whereType<int>().toList();
}

class _AuditForm extends ConsumerStatefulWidget {
  const _AuditForm({required this.initial, required this.editable});
  final AuditSettings initial;
  final bool editable;

  @override
  ConsumerState<_AuditForm> createState() => _AuditFormState();
}

class _AuditFormState extends ConsumerState<_AuditForm> {
  late final _fields = {
    'k': TextEditingController(text: '${widget.initial.fuelKSigma}'),
    'min': TextEditingController(text: '${widget.initial.fuelMinCycles}'),
    'pct': TextEditingController(text: '${widget.initial.fuelPctThreshold}'),
    'alpha': TextEditingController(text: '${widget.initial.fuelEwmaAlpha}'),
    'odo': TextEditingController(text: '${widget.initial.odoGpsTolerancePct}'),
    'days': TextEditingController(text: widget.initial.docAlertDays.join(', ')),
  };
  String? _message;
  bool _ok = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    double? n(String key) => double.tryParse(_fields[key]!.text.trim());
    final min = int.tryParse(_fields['min']!.text.trim());
    final days = parseDayList(_fields['days']!.text);
    final values = [n('k'), n('pct'), n('alpha'), n('odo')];
    final settings = values.contains(null) || min == null || days == null
        ? null
        : AuditSettings(
            fuelKSigma: values[0]!,
            fuelMinCycles: min,
            fuelPctThreshold: values[1]!,
            fuelEwmaAlpha: values[2]!,
            odoGpsTolerancePct: values[3]!,
            docAlertDays: days,
          );
    if (settings == null || !settings.isValid) {
      setState(() {
        _message = l.checkThresholds;
        _ok = false;
      });
      return;
    }
    final saved = await runAction(context, () async {
      await ref.read(ownerApiProvider).updateAuditSettings(settings);
      refreshAfter(ref, {OwnerArea.fuel});
    });
    if (mounted && saved) {
      setState(() {
        _message = l.savedThresholds;
        _ok = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = [
      ('k', l.fuelKSigma, l.fuelKSigmaHint),
      ('min', l.fuelMinCycles, l.fuelMinCyclesHint),
      ('pct', l.fuelPct, l.fuelPctHint),
      ('alpha', l.fuelAlpha, l.fuelAlphaHint),
      ('odo', l.odoTolerance, l.odoToleranceHint),
      ('days', l.docAlertDays, l.docAlertDaysHint),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (key, label, hint) in rows) ...[
          TextField(
            key: Key('audit-$key'),
            controller: _fields[key],
            enabled: widget.editable,
            keyboardType: key == 'days'
                ? TextInputType.text
                : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              helperText: hint,
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_message != null)
          Text(
            _message!,
            style: TextStyle(
              color: _ok
                  ? Colors.green.shade800
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        if (widget.editable)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('save-thresholds'),
              onPressed: _save,
              child: Text(l.saveThresholds),
            ),
          ),
      ],
    );
  }
}

class _PayForm extends ConsumerStatefulWidget {
  const _PayForm({required this.initial, required this.editable});
  final PayRule initial;
  final bool editable;

  @override
  ConsumerState<_PayForm> createState() => _PayFormState();
}

class _PayFormState extends ConsumerState<_PayForm> {
  late PayRule _rule = widget.initial;
  String? _message;
  bool _ok = false;

  Future<void> _save() async {
    final l = context.l10n;
    if (!_rule.isValid) {
      setState(() {
        _message = l.checkPayRule;
        _ok = false;
      });
      return;
    }
    final saved = await runAction(context, () async {
      await ref.read(ownerApiProvider).updateDefaultPayRule(_rule);
      refreshAfter(ref, {OwnerArea.settings, OwnerArea.settlements});
    });
    if (mounted && saved) {
      setState(() {
        _message = l.savedPay;
        _ok = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.defaultPayIntro, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        PayRuleEditor(
          value: _rule,
          enabled: widget.editable,
          onChanged: (r) => setState(() => _rule = r),
        ),
        if (_message != null)
          Text(
            _message!,
            style: TextStyle(
              color: _ok
                  ? Colors.green.shade800
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        if (widget.editable)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('save-default-pay'),
              onPressed: _save,
              child: Text(l.saveDefaultPay),
            ),
          ),
      ],
    );
  }
}
