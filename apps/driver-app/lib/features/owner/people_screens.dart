import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/owner_models.dart';
import '../common/format.dart';
import 'documents_screen.dart';
import 'owner_providers.dart';
import 'owner_text.dart';
import 'owner_widgets.dart';
import 'pay_rule_editor.dart';

/// The fleet's drivers with their pay; invite by phone.
class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final drivers = ref.watch(driversProvider);
    final defaultRule = ref.watch(defaultPayRuleProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.drivers)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('invite-driver'),
        icon: const Icon(Icons.person_add),
        label: Text(l.inviteDriver),
        onPressed: () => _invite(context, ref, manager: false),
      ),
      body: RefreshPage(
        onRefresh: () => ref.refresh(driversProvider.future),
        children: [
          AsyncView(
            value: drivers,
            onRetry: () => ref.invalidate(driversProvider),
            builder: (list) => list.isEmpty
                ? EmptyState(l.noDriversYet)
                : Column(
                    children: [
                      for (final d in list)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            key: ValueKey('driver-${d.id}'),
                            leading: const Icon(Icons.person),
                            title: Text(d.name),
                            subtitle: Text(
                              [
                                formatPhone(d.phone),
                                if (d.payRule != null)
                                  payRuleText(fmt, d.payRule!)
                                else if (defaultRule != null)
                                  l.payDefault(
                                    rule: payRuleText(fmt, defaultRule),
                                  ),
                              ].join(' · '),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              direction: Axis.vertical,
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                ToneChip(
                                  d.isActive ? l.active : l.inactive,
                                  tone: d.isActive
                                      ? Tone.success
                                      : Tone.neutral,
                                ),
                                if (d.membershipStatus == 'invited')
                                  ToneChip(l.notSignedInYet, tone: Tone.brand),
                              ],
                            ),
                            onTap: () => openScreen<void>(
                              context,
                              DriverScreen(driver: d),
                            ),
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

/// Invites a driver, or (owner only) a manager, by name and mobile number.
Future<void> _invite(
  BuildContext context,
  WidgetRef ref, {
  required bool manager,
}) => showDialog<void>(
  context: context,
  builder: (_) => InviteDialog(manager: manager),
);

class InviteDialog extends ConsumerStatefulWidget {
  const InviteDialog({required this.manager, super.key});
  final bool manager;

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _nameError;
  String? _phoneError;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = context.l10n;
    final name = _name.text.trim();
    final phone = normalizeIndianMobile(_phone.text);
    setState(() {
      _nameError = name.isEmpty ? l.required : null;
      _phoneError = phone == null ? l.enterIndianMobile : null;
    });
    if (name.isEmpty || phone == null) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final ok = await runAction(context, () async {
      final api = ref.read(ownerApiProvider);
      if (widget.manager) {
        await api.inviteManager(name: name, phone: phone);
      } else {
        await api.inviteDriver(name: name, phone: phone);
      }
      refreshAfter(ref, {OwnerArea.fleet});
    });
    if (ok) {
      navigator.pop();
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.manager ? l.inviteManager : l.inviteDriver),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.manager ? l.inviteManagerIntro : l.inviteDriverIntro),
            const SizedBox(height: 12),
            TextField(
              key: const Key('invite-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.name,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('invite-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.mobileNumber,
                hintText: '98123 45678',
                errorText: _phoneError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('invite-send'),
          onPressed: _busy ? null : _send,
          child: Text(l.sendInvite),
        ),
      ],
    );
  }
}

/// One driver: name and status, pay (owner only), and their documents.
class DriverScreen extends ConsumerStatefulWidget {
  const DriverScreen({required this.driver, super.key});
  final Driver driver;

  @override
  ConsumerState<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends ConsumerState<DriverScreen> {
  late final _name = TextEditingController(text: widget.driver.name);
  late String _status = widget.driver.status;
  late bool _override = widget.driver.payRule != null;
  late PayRule? _rule = widget.driver.payRule;
  String? _problem;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final isOwner = ref.read(isOwnerProvider);
    final rule = _override ? _rule : null;
    if (isOwner && rule != null && !rule.isValid) {
      setState(() => _problem = l.checkPayRule);
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _problem = l.required);
      return;
    }
    setState(() {
      _problem = null;
      _busy = true;
    });
    final d = widget.driver;
    final navigator = Navigator.of(context);
    final ok = await runAction(context, () async {
      final api = ref.read(ownerApiProvider);
      await api.updateDriver(d.id, name: _name.text.trim(), status: _status);
      // Managers can't change pay (403 FORBIDDEN_ROLE), so only owners send it.
      if (isOwner && rule != d.payRule) {
        await api.setDriverPayRule(d.id, rule);
      }
      refreshAfter(ref, {OwnerArea.fleet, OwnerArea.settlements});
    });
    if (ok) {
      navigator.pop();
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final isOwner = ref.watch(isOwnerProvider);
    final defaultRule = ref.watch(defaultPayRuleProvider).value;
    final d = widget.driver;
    final query = (vehicleId: null, driverId: d.id, expiringWithinDays: null);
    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          PageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(labelText: l.name),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: const Key('driver-status'),
                        isExpanded: true,
                        initialValue: _status,
                        decoration: InputDecoration(labelText: l.status),
                        items: [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(l.active),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text(l.inactiveDriverOption),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatPhone(d.phone),
                          style: const TextStyle(color: TaxcyColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  key: const Key('driver-pay'),
                  title: l.pay,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isOwner)
                        Text(
                          l.onlyOwnerPay,
                          key: const Key('only-owner-pay'),
                          style: const TextStyle(color: TaxcyColors.muted),
                        ),
                      CheckboxListTile(
                        key: const Key('pay-override'),
                        contentPadding: EdgeInsets.zero,
                        value: _override,
                        title: Text(l.payDifferently),
                        subtitle: defaultRule == null
                            ? null
                            : Text(
                                l.payDefault(
                                  rule: payRuleText(fmt, defaultRule),
                                ),
                              ),
                        onChanged: isOwner
                            ? (v) => setState(() {
                                _override = v ?? false;
                                if (_override && _rule == null) {
                                  _rule =
                                      defaultRule ??
                                      PayRule.defaultsFor(
                                        'percent_of_fare',
                                        allowanceToDriver: false,
                                      );
                                }
                              })
                            : null,
                      ),
                      if (_override && _rule != null)
                        PayRuleEditor(
                          value: _rule!,
                          enabled: isOwner,
                          onChanged: (r) => setState(() => _rule = r),
                        ),
                    ],
                  ),
                ),
                if (_problem != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _problem!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton(
                  key: const Key('driver-save'),
                  onPressed: _busy ? null : _save,
                  child: Text(l.save),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: l.documents,
                  actions: [
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l.addDocument),
                      onPressed: () => openScreen<void>(
                        context,
                        DocumentFormScreen(driverId: d.id),
                      ),
                    ),
                  ],
                  child: DocumentsList(query: query),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Everyone with access to the org. Owners invite and remove managers.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isOwner = ref.watch(isOwnerProvider);
    final me = ref.watch(authProvider).value?.userId;
    final members = ref.watch(membersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.members)),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              key: const Key('invite-manager'),
              icon: const Icon(Icons.person_add),
              label: Text(l.inviteManager),
              onPressed: () => _invite(context, ref, manager: true),
            )
          : null,
      body: RefreshPage(
        onRefresh: () => ref.refresh(membersProvider.future),
        children: [
          Text(l.membersIntro, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          AsyncView(
            value: members,
            onRetry: () => ref.invalidate(membersProvider),
            builder: (list) => Column(
              children: [
                for (final m in list)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      key: ValueKey('member-${m.id}'),
                      title: Text(m.name ?? formatPhone(m.phone)),
                      subtitle: Text(
                        [
                          formatPhone(m.phone),
                          m.roles.map((r) => roleLabel(l, r)).join(', '),
                          memberStatusLabel(l, m.status),
                        ].join(' · '),
                      ),
                      trailing:
                          isOwner &&
                              m.isManager &&
                              m.status != 'suspended' &&
                              m.userId != me
                          ? IconButton(
                              key: ValueKey('remove-manager-${m.id}'),
                              tooltip: l.removeManager,
                              icon: const Icon(Icons.person_remove),
                              onPressed: () async {
                                final yes = await confirmAction(
                                  context,
                                  title: l.removeManager,
                                  message: l.removeManagerConfirm(
                                    name: m.name ?? formatPhone(m.phone),
                                  ),
                                  confirm: l.remove,
                                );
                                if (!yes || !context.mounted) return;
                                await runAction(context, () async {
                                  await ref
                                      .read(ownerApiProvider)
                                      .removeManager(m.id);
                                  refreshAfter(ref, {OwnerArea.fleet});
                                });
                              },
                            )
                          : null,
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
