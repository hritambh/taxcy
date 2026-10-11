import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/api/models.dart';
import '../../../core/api/owner_models.dart';
import '../../common/format.dart';
import '../../common/widgets.dart';
import '../owner_providers.dart';
import '../owner_text.dart';
import '../owner_widgets.dart';
import 'route_map.dart';

const _uuid = Uuid();

/// Everything about one trip for the owner: details, actions, cancellation
/// decision, evidence, route and distance check, money, and the timeline.
class OwnerTripDetailScreen extends ConsumerWidget {
  const OwnerTripDetailScreen({required this.tripId, super.key});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(ownerTripProvider(tripId));
    final title = trip.value?.routeLabel ?? context.l10n.tripDetails;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: trip,
        onRetry: () => ref.invalidate(ownerTripProvider(tripId)),
        builder: (t) => RefreshPage(
          onRefresh: () async {
            ref
              ..invalidate(tripEventsProvider(tripId))
              ..invalidate(distanceCheckProvider(tripId))
              ..invalidate(tripRouteProvider(tripId))
              ..invalidate(ownerTripProvider(tripId));
            await ref.read(ownerTripProvider(tripId).future);
          },
          children: [
            _Header(t),
            if (t.cancellationRequest != null) _CancellationCard(t),
            _DetailsCard(t),
            _OdometerCard(t),
            _RouteCard(t),
            _CollectionsCard(t),
            _ChargesCard(t),
            _TimelineCard(t.id),
          ],
        ),
      ),
    );
  }
}

/// Reloads the trip and whatever its change touches (lists, alerts, settlements).
void _refreshTrip(WidgetRef ref) => refreshAfter(ref, {
  OwnerArea.trips,
  OwnerArea.alerts,
  OwnerArea.settlements,
});

class _Header extends ConsumerWidget {
  const _Header(this.trip);
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final can = trip.allowedCommands.toSet();
    final api = ref.read(ownerApiProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              StatusChip(trip.status),
              Text(
                '${tripTypeLabel(l, trip.tripType)} · '
                '${fmt.dayTime(trip.scheduledStartAt)} – ${fmt.dayTime(trip.scheduledEndAt)}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (can.contains('assign') || can.contains('reassign'))
                FilledButton.icon(
                  key: const Key('trip-assign'),
                  icon: const Icon(Icons.person_add_alt),
                  label: Text(can.contains('assign') ? l.assign : l.reassign),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AssignDialog(trip: trip),
                  ),
                ),
              if (can.contains('unassign'))
                OutlinedButton(
                  key: const Key('trip-unassign'),
                  onPressed: () => runAction(context, () async {
                    await api.unassign(trip.id, idempotencyKey: _uuid.v4());
                    _refreshTrip(ref);
                  }),
                  child: Text(l.unassign),
                ),
              if (can.contains('cancel'))
                OutlinedButton(
                  key: const Key('trip-cancel'),
                  onPressed: () async {
                    final reason = await askText(
                      context,
                      title: l.cancelTripTitle,
                      label: l.reason,
                      confirm: l.cancelTrip,
                      destructive: true,
                    );
                    if (reason == null || !context.mounted) return;
                    await runAction(context, () async {
                      await api.cancelTrip(
                        trip.id,
                        reason: reason,
                        idempotencyKey: _uuid.v4(),
                      );
                      _refreshTrip(ref);
                    });
                  },
                  child: Text(l.cancelTrip),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pick a vehicle and a driver for the trip.
class AssignDialog extends ConsumerStatefulWidget {
  const AssignDialog({required this.trip, super.key});
  final Trip trip;

  @override
  ConsumerState<AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<AssignDialog> {
  final _key = _uuid.v4();
  late String? _vehicleId = widget.trip.vehicle?.id;
  late String? _driverId = widget.trip.driverId;
  bool _busy = false;

  Future<void> _assign() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final ok = await runAction(context, () async {
      await ref
          .read(ownerApiProvider)
          .assign(
            widget.trip.id,
            vehicleId: _vehicleId!,
            driverId: _driverId!,
            idempotencyKey: _key,
          );
      _refreshTrip(ref);
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
    final reassign = widget.trip.vehicle != null;
    return AlertDialog(
      title: Text(reassign ? l.reassignTripTitle : l.assignTripTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VehiclePicker(
              value: _vehicleId,
              label: l.vehicle,
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
            const SizedBox(height: 12),
            DriverPicker(
              value: _driverId,
              label: l.driver,
              onChanged: (v) => setState(() => _driverId = v),
            ),
            const SizedBox(height: 12),
            Text(l.overlapNote, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('assign-confirm'),
          onPressed: _busy || _vehicleId == null || _driverId == null
              ? null
              : _assign,
          child: Text(reassign ? l.reassign : l.assign),
        ),
      ],
    );
  }
}

class _CancellationCard extends ConsumerWidget {
  const _CancellationCard(this.trip);
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final request = trip.cancellationRequest!;
    final pending = request.status == 'pending';
    final api = ref.read(ownerApiProvider);
    return SectionCard(
      key: const Key('cancellation-card'),
      title: l.cancellationRequestTitle,
      actions: [
        ToneChip(
          requestStatusLabel(l, request.status),
          tone: pending
              ? Tone.warning
              : request.status == 'approved'
              ? Tone.danger
              : Tone.neutral,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“${request.reason}”',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (request.createdAt != null)
            Text(
              [
                l.requestedBy(
                  role: roleLabel(l, request.requestedRole ?? 'driver'),
                  when: fmt.dayTime(request.createdAt!),
                ),
                if (request.endOdometer != null)
                  l.odometerAtKm(km: fmt.km(request.endOdometer!.typedKm)),
              ].join(' · '),
              style: const TextStyle(color: TaxcyColors.muted),
            ),
          if (request.decisionNote != null)
            Text(l.decisionNote(note: request.decisionNote!)),
          if (request.endOdometer != null) ...[
            const SizedBox(height: 8),
            MediaPhoto(request.endOdometer!.mediaId, height: 120),
          ],
          if (pending) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: const Key('approve-cancellation'),
                  onPressed: () async {
                    final fare = await askText(
                      context,
                      title: l.approveCancellation,
                      intro: l.approveIntro,
                      label: l.cancellationFare,
                      hint: l.cancellationFareHint,
                      initial: '0',
                      confirm: l.approve,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validate: (v) => validateRupees(l, v, allowZero: true),
                    );
                    if (fare == null || !context.mounted) return;
                    await runAction(context, () async {
                      await api.approveCancellation(
                        request.id,
                        cancellationFarePaise: parseRupees(fare)!,
                        idempotencyKey: _uuid.v4(),
                      );
                      _refreshTrip(ref);
                    });
                  },
                  child: Text(l.approveCancellation),
                ),
                OutlinedButton(
                  key: const Key('reject-cancellation'),
                  onPressed: () async {
                    final note = await askText(
                      context,
                      title: l.rejectTitle,
                      label: l.noteForDriver,
                      confirm: l.rejectConfirm,
                      destructive: true,
                    );
                    if (note == null || !context.mounted) return;
                    await runAction(context, () async {
                      await api.rejectCancellation(
                        request.id,
                        note: note,
                        idempotencyKey: _uuid.v4(),
                      );
                      _refreshTrip(ref);
                    });
                  },
                  child: Text(l.reject),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard(this.trip);
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final t = trip;
    final driven = t.drivenKm;
    final over = t.kmOverIncluded;
    return SectionCard(
      title: l.tripDetails,
      child: StatGrid([
        StatTile(
          label: l.customer,
          value: t.customerName ?? l.noValue,
          hint: t.customerPhone == null ? null : formatPhone(t.customerPhone!),
        ),
        StatTile(
          label: l.vehicle,
          value: t.vehicle == null
              ? l.unassigned
              : formatRegistration(t.vehicle!.registrationNo),
          hint: t.vehicle?.model,
        ),
        StatTile(label: l.driver, value: t.driverName ?? l.unassigned),
        StatTile(label: l.quotedFare, value: fmt.inr(t.quotedFarePaise)),
        StatTile(
          key: const Key('included-km'),
          label: l.includedKm,
          value: t.includedKm == null ? l.notSet : fmt.km(t.includedKm!),
          valueColor: over == null ? null : Colors.amber.shade900,
          hint: driven == null || t.includedKm == null
              ? null
              : over != null
              ? l.kmOverDriven(
                  over: fmt.number(over),
                  driven: fmt.number(driven),
                )
              : l.drivenKm(km: fmt.number(driven)),
        ),
        if (t.cancellationFarePaise != null)
          StatTile(
            label: l.cancellationFare,
            value: fmt.inr(t.cancellationFarePaise!),
          ),
        StatTile(
          label: l.startedAt,
          value: t.startedAt == null ? l.noValue : fmt.dayTime(t.startedAt!),
        ),
        StatTile(
          label: l.endedAt,
          value: t.endedAt == null ? l.noValue : fmt.dayTime(t.endedAt!),
        ),
        if (t.cancelledAt != null)
          StatTile(
            label: l.cancelledAt,
            value: fmt.dayTime(t.cancelledAt!),
            hint: t.cancelReason,
          ),
        if (driven != null)
          StatTile(label: l.odometerDistance, value: fmt.km(driven)),
      ]),
    );
  }
}

class _OdometerCard extends StatelessWidget {
  const _OdometerCard(this.trip);
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionCard(
      title: l.odometerEvidence,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _OdometerCell(label: l.startLabel, reading: trip.startOdometer),
          _OdometerCell(label: l.endLabel, reading: trip.endOdometer),
        ],
      ),
    );
  }
}

class _OdometerCell extends StatelessWidget {
  const _OdometerCell({required this.label, required this.reading});
  final String label;
  final OdometerReading? reading;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final r = reading;
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          if (r == null)
            Text(
              l.notRecordedYet,
              style: const TextStyle(color: TaxcyColors.muted),
            )
          else ...[
            const SizedBox(height: 4),
            MediaPhoto(r.mediaId, height: 140),
            const SizedBox(height: 4),
            StatGrid([
              StatTile(label: l.typed, value: fmt.km(r.typedKm)),
              StatTile(
                label: l.readFromPhoto,
                value: r.ocrKm == null ? l.noValue : fmt.km(r.ocrKm!),
                valueColor: _mismatch(r) ? Colors.amber.shade900 : null,
                hint: _mismatch(r) ? l.differsSentToReview : null,
              ),
            ]),
            Text(
              l.capturedAt(when: fmt.dayTime(r.capturedAt)),
              style: const TextStyle(fontSize: 12, color: TaxcyColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  static bool _mismatch(OdometerReading r) =>
      r.ocrKm != null && (r.ocrKm! - r.typedKm).abs() > 1;
}

class _RouteCard extends ConsumerWidget {
  const _RouteCard(this.trip);
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final started = trip.startedAt != null;
    final closed =
        trip.endedAt != null || (trip.cancelledAt != null && started);
    if (!started) {
      return SectionCard(
        title: l.routeTitle,
        child: EmptyState(l.routeAfterStart),
      );
    }
    final route = ref.watch(tripRouteProvider(trip.id));
    final check = closed ? ref.watch(distanceCheckProvider(trip.id)) : null;
    final mismatchAlert = closed
        ? ref
              .watch(
                alertsProvider((
                  status: null,
                  kind: 'odo_gps_mismatch',
                  tripId: trip.id,
                )),
              )
              .value
              ?.firstOrNull
        : null;
    return SectionCard(
      title: l.routeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AsyncView(
            value: route,
            onRetry: () => ref.invalidate(tripRouteProvider(trip.id)),
            builder: (r) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RouteMap(
                  points: [for (final p in r.points) (p.lat, p.lng)],
                  from: trip.fromPoint,
                  to: trip.toPoint,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    l.gpsPointsShown(count: r.points.length),
                    if (r.droppedInaccurate +
                            r.droppedMock +
                            r.droppedImpossibleSpeed >
                        0)
                      l.pointsRemoved(
                        inaccurate: '${r.droppedInaccurate}',
                        mock: '${r.droppedMock}',
                        impossible: '${r.droppedImpossibleSpeed}',
                      ),
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: TaxcyColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (check case AsyncData(value: final c?)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ToneChip(
                  switch (c.result) {
                    'ok' => l.verdictOkLabel,
                    'flagged' => l.verdictFlaggedLabel,
                    _ => l.verdictInconclusiveLabel,
                  },
                  tone: switch (c.result) {
                    'ok' => Tone.success,
                    'flagged' => Tone.danger,
                    _ => Tone.neutral,
                  },
                ),

                Text(
                  l.checkedAt(when: fmt.dayTime(c.computedAt)),
                  style: const TextStyle(
                    fontSize: 12,
                    color: TaxcyColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatGrid([
              StatTile(label: l.odometer, value: fmt.km(c.odometerKm)),
              StatTile(
                label: l.gps,
                value: c.gpsKm == null ? l.noValue : fmt.km(c.gpsKm!.round()),
              ),
              StatTile(
                label: l.gpsCoverage,
                value: c.coverageRatio == null
                    ? l.noValue
                    : l.percentValue(
                        value: fmt.number((c.coverageRatio! * 100).round()),
                      ),
              ),
              StatTile(
                label: l.longestGap,
                value: c.maxGapSeconds == null
                    ? l.noValue
                    : l.minutesShort(count: (c.maxGapSeconds! / 60).round()),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              mismatchAlert != null
                  ? alertBody(fmt, mismatchAlert)
                  : switch (c.result) {
                      'ok' => l.verdictOkText,
                      'flagged' => l.verdictFlaggedText,
                      _ => l.verdictInconclusiveText,
                    },
            ),
          ] else if (check case AsyncData(value: null))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.distanceCheckPending,
                style: const TextStyle(color: TaxcyColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionsCard extends ConsumerWidget {
  const _CollectionsCard(this.trip);
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final total = trip.collections.fold<int>(0, (s, c) => s + c.amountPaise);
    return SectionCard(
      title: l.paymentsCollected,
      actions: [
        if (trip.startedAt != null)
          TextButton.icon(
            key: const Key('record-payment'),
            icon: const Icon(Icons.add),
            label: Text(l.recordPayment),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => _PaymentSheet(trip: trip),
            ),
          ),
      ],
      child: trip.collections.isEmpty
          ? Text(
              l.nothingRecorded,
              style: const TextStyle(color: TaxcyColors.muted),
            )
          : Column(
              children: [
                for (final c in trip.collections)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(methodLabel(l, c.method)),
                    subtitle: Text(
                      [
                        if (c.collectedAt != null) fmt.dayTime(c.collectedAt!),
                        ?c.reference,
                      ].join(' · '),
                    ),
                    trailing: Text(fmt.inr(c.amountPaise)),
                  ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l.total,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    fmt.inr(total),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final _id = _uuid.v4();
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  String _method = 'cash';

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final ok = await runAction(context, () async {
      await ref.read(ownerApiProvider).addCollection(widget.trip.id, {
        'id': _id,
        'method': _method,
        'amountPaise': parseRupees(_amount.text),
        if (_reference.text.trim().isNotEmpty)
          'reference': _reference.text.trim(),
      });
      _refreshTrip(ref);
    });
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Sheet(
      title: l.recordPayment,
      form: _form,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _method,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.method),
          items: [
            DropdownMenuItem(value: 'cash', child: Text(l.methodCashOption)),
            DropdownMenuItem(value: 'upi', child: Text(l.methodUpiOption)),
            DropdownMenuItem(value: 'card', child: Text(l.methodCardOption)),
          ],
          onChanged: (v) => setState(() => _method = v ?? _method),
        ),
        TextFormField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.amount, prefixText: '₹ '),
          validator: (v) => validateRupees(l, v),
        ),
        TextFormField(
          controller: _reference,
          decoration: InputDecoration(
            labelText: l.referenceOptional,
            helperText: l.referenceHint,
          ),
        ),
        FilledButton(onPressed: _save, child: Text(l.record)),
      ],
    );
  }
}

class _ChargesCard extends ConsumerWidget {
  const _ChargesCard(this.trip);
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final editable =
        trip.status != 'settled' &&
        !(trip.status == 'cancelled' && trip.startedAt == null);
    return SectionCard(
      title: l.charges,
      actions: [
        if (editable)
          TextButton.icon(
            key: const Key('owner-add-charge'),
            icon: const Icon(Icons.add),
            label: Text(l.addCharge),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => OwnerChargeSheet(trip: trip),
            ),
          ),
      ],
      child: trip.charges.isEmpty
          ? Text(l.noCharges, style: const TextStyle(color: TaxcyColors.muted))
          : Column(
              children: [
                for (final c in trip.charges)
                  ListTile(
                    key: ValueKey('charge-${c.id}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      chargeKindLabel(l, c.kind),
                      style: TextStyle(
                        decoration: c.voided
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(_chargeNote(context, c)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fmt.inr(c.amountPaise),
                          style: TextStyle(
                            decoration: c.voided
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (editable && !c.voided)
                          TextButton(
                            onPressed: () => runAction(context, () async {
                              await ref
                                  .read(ownerApiProvider)
                                  .voidCharge(trip.id, c.id);
                              _refreshTrip(ref);
                            }),
                            child: Text(l.voidAction),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  static String _chargeNote(BuildContext context, TripCharge c) {
    final l = context.l10n;
    final who = isExtraFare(c.kind)
        ? l.extraFare
        : c.paidByDriver
        ? l.driverPaid
        : l.billedOnly;
    final text = c.enteredRole == null
        ? who
        : l.byRole(text: who, role: roleLabel(l, c.enteredRole!));
    return c.note == null ? text : '$text · ${c.note}';
  }
}

/// Owner adds a charge. Night charge, extra km and driver allowance are extra
/// fare the customer pays, so they never get a "driver paid" choice.
class OwnerChargeSheet extends ConsumerStatefulWidget {
  const OwnerChargeSheet({required this.trip, super.key});
  final Trip trip;

  @override
  ConsumerState<OwnerChargeSheet> createState() => _OwnerChargeSheetState();
}

class _OwnerChargeSheetState extends ConsumerState<OwnerChargeSheet> {
  final _id = _uuid.v4();
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _kind = 'toll';
  bool _paidByDriver = true;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final ok = await runAction(context, () async {
      await ref.read(ownerApiProvider).addCharge(widget.trip.id, {
        'id': _id,
        'kind': _kind,
        'amountPaise': parseRupees(_amount.text),
        'paidByDriver': !isExtraFare(_kind) && _paidByDriver,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      });
      _refreshTrip(ref);
    });
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Sheet(
      title: l.addChargeTitle,
      form: _form,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('owner-charge-kind'),
          initialValue: _kind,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.chargeType),
          items: [
            for (final kind in chargeKinds)
              DropdownMenuItem(
                value: kind,
                child: Text(chargeKindLabel(l, kind)),
              ),
          ],
          onChanged: (v) => setState(() => _kind = v ?? _kind),
        ),
        TextFormField(
          key: const Key('owner-charge-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.amount, prefixText: '₹ '),
          validator: (v) => validateRupees(l, v),
        ),
        if (isExtraFare(_kind))
          Container(
            key: const Key('owner-extra-fare-info'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TaxcyColors.blue50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l.extraFareInfo),
          )
        else
          CheckboxListTile(
            key: const Key('owner-charge-driver-paid'),
            contentPadding: EdgeInsets.zero,
            value: _paidByDriver,
            title: Text(l.driverPaidCheckbox),
            onChanged: (v) => setState(() => _paidByDriver = v ?? true),
          ),
        TextFormField(
          controller: _note,
          decoration: InputDecoration(labelText: l.note),
        ),
        FilledButton(
          key: const Key('owner-charge-save'),
          onPressed: _save,
          child: Text(l.addCharge),
        ),
      ],
    );
  }
}

/// A bottom-sheet form with a title, spaced fields and room for the keyboard.
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.form,
    required this.children,
  });

  final String title;
  final GlobalKey<FormState> form;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            for (final child in children) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    ),
  );
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard(this.tripId);
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final events = ref.watch(tripEventsProvider(tripId));
    return SectionCard(
      title: l.timeline,
      child: AsyncView(
        value: events,
        onRetry: () => ref.invalidate(tripEventsProvider(tripId)),
        builder: (list) => list.isEmpty
            ? EmptyState(l.noEvents)
            : Column(
                children: [for (final e in list) _EventRow(event: e, fmt: fmt)],
              ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.fmt});
  final TripEvent event;
  final Fmt fmt;

  @override
  Widget build(BuildContext context) {
    final l = fmt.l;
    final e = event;
    final name = eventLabel(l, e.eventType);
    final lag = e.recordedAt.difference(e.occurredAt).inMinutes;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 8, color: TaxcyColors.blue600),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.actorRole == null
                      ? l.eventBySystem(event: name)
                      : l.eventBy(
                          event: name,
                          role: roleLabel(l, e.actorRole!),
                        ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  [
                    l.onDevice(when: fmt.dayTime(e.occurredAt)),
                    if (lag >= 2)
                      l.syncedLater(
                        when: fmt.dayTime(e.recordedAt),
                        count: lag,
                      ),
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: TaxcyColors.muted,
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
