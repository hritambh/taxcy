import 'package:flutter/material.dart';

import '../../core/api/owner_models.dart';
import '../common/format.dart';
import 'owner_text.dart';

/// Edits a driver pay rule. Amounts are typed in rupees and kept in paise.
/// Read-only when [enabled] is false (managers can see but not change pay).
class PayRuleEditor extends StatefulWidget {
  const PayRuleEditor({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final PayRule value;
  final ValueChanged<PayRule> onChanged;
  final bool enabled;

  @override
  State<PayRuleEditor> createState() => _PayRuleEditorState();
}

class _PayRuleEditorState extends State<PayRuleEditor> {
  late final _amount = TextEditingController(text: _amountText(widget.value));
  late final _percent = TextEditingController(
    text: _plain(widget.value.percent ?? 20),
  );

  static String _plain(num n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  static String _amountText(PayRule rule) {
    final paise = rule.kind == 'per_km' ? rule.paisePerKm : rule.amountPaise;
    return paise == null ? '' : _plain(paise / 100);
  }

  @override
  void dispose() {
    _amount.dispose();
    _percent.dispose();
    super.dispose();
  }

  void _setKind(String kind) {
    final rule = PayRule.defaultsFor(
      kind,
      allowanceToDriver: widget.value.allowanceToDriver,
    );
    _amount.text = _amountText(rule);
    _percent.text = _plain(rule.percent ?? 20);
    widget.onChanged(rule);
  }

  void _setAmount(String text) {
    final paise = parseRupees(text);
    if (paise == null) return;
    widget.onChanged(
      widget.value.kind == 'per_km'
          ? widget.value.copyWith(paisePerKm: paise)
          : widget.value.copyWith(amountPaise: paise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rule = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('pay-rule-kind'),
          initialValue: rule.kind,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.payRuleHow),
          items: [
            for (final kind in PayRule.kinds)
              DropdownMenuItem(
                value: kind,
                child: Text(payRuleKindLabel(l, kind)),
              ),
          ],
          onChanged: widget.enabled
              ? (v) => v == null ? null : _setKind(v)
              : null,
        ),
        if (rule.kind == 'percent_of_fare') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('pay-rule-percent'),
                  controller: _percent,
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l.percent,
                    suffixText: '%',
                  ),
                  onChanged: (v) {
                    final p = double.tryParse(v.trim());
                    if (p != null) widget.onChanged(rule.copyWith(percent: p));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: rule.base ?? 'quoted',
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.ofBase),
                  items: [
                    DropdownMenuItem(
                      value: 'quoted',
                      child: Text(l.baseQuoted),
                    ),
                    DropdownMenuItem(
                      value: 'expected',
                      child: Text(l.baseExpected),
                    ),
                  ],
                  onChanged: widget.enabled
                      ? (v) => widget.onChanged(rule.copyWith(base: v))
                      : null,
                ),
              ),
            ],
          ),
        ],
        if (const [
          'per_trip',
          'per_km',
          'fixed_daily',
        ].contains(rule.kind)) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('pay-rule-amount'),
            controller: _amount,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: switch (rule.kind) {
                'per_km' => l.ratePerKm,
                'fixed_daily' => l.amountPerDay,
                _ => l.amountPerTrip,
              },
              prefixText: '₹ ',
            ),
            onChanged: _setAmount,
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.allowanceToDriver),
          subtitle: Text(l.allowanceHint),
          value: rule.allowanceToDriver,
          onChanged: widget.enabled
              ? (v) => widget.onChanged(rule.copyWith(allowanceToDriver: v))
              : null,
        ),
      ],
    );
  }
}
