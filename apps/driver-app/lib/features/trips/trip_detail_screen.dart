import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/models.dart';
import '../../core/repositories/trips_repository.dart';
import '../common/format.dart';
import '../common/widgets.dart';
import '../fuel/fuel_fill_screen.dart';
import 'charge_sheet.dart';
import 'trip_forms.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({required this.tripId, super.key});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(tripProvider(tripId)).value;
    final l = context.l10n;
    final fmt = context.fmt;
    if (view == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.tripNotFoundOnPhone)),
      );
    }
    final t = view.trip;
    final can = t.allowedCommands.toSet();
    final blocked = view.conflict != null;
    return Scaffold(
      appBar: AppBar(title: Text(t.routeLabel)),
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (blocked) _ConflictBanner(view),
                Row(
                  children: [
                    StatusChip(t.status),
                    const Spacer(),
                    Text(
                      fmt.inr(t.quotedFarePaise),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Line(
                  Icons.schedule,
                  '${fmt.dayTime(t.scheduledStartAt)} – ${fmt.time(t.scheduledEndAt)}',
                ),
                _Line(Icons.trip_origin, t.fromText),
                if (t.toText != null) _Line(Icons.place, t.toText!),
                if (t.includedKm != null)
                  _Line(
                    Icons.route,
                    l.includesKm(km: fmt.number(t.includedKm!)),
                  ),
                if (t.vehicle != null)
                  _Line(
                    Icons.directions_car,
                    '${t.vehicle!.registrationNo} · ${t.vehicle!.model}',
                  ),
                if (t.customerName != null)
                  _Line(
                    Icons.person,
                    [
                      t.customerName,
                      t.customerPhone,
                    ].whereType<String>().join(' · '),
                  ),
                if (t.startOdometer != null)
                  _Line(
                    Icons.speed,
                    l.startOdometerKm(km: fmt.number(t.startOdometer!.typedKm)),
                  ),
                if (t.endOdometer != null)
                  _Line(
                    Icons.speed,
                    l.endOdometerKm(km: fmt.number(t.endOdometer!.typedKm)),
                  ),
                if (t.status == 'started' && !blocked) _LiveTrip(trip: t),
                if (t.cancellationPending)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.hourglass_top),
                      title: Text(l.cancellationRequested),
                      subtitle: Text(l.cancellationWaiting),
                    ),
                  ),
                if (t.charges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l.charges,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final c in t.charges.where((c) => !c.voided))
                    ListTile(
                      dense: true,
                      title: Text(chargeKindLabel(l, c.kind)),
                      subtitle: Text(chargeNote(l, c)),
                      trailing: Text(fmt.inr(c.amountPaise)),
                    ),
                ],
                if (t.fuelFills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l.fuel, style: Theme.of(context).textTheme.titleSmall),
                  for (final f in t.fuelFills)
                    ListTile(
                      dense: true,
                      title: Text(fuelFillLabel(fmt, f)),
                      subtitle: Text(paidByLabel(l, f.paidBy)),
                      trailing: Text(fmt.inr(f.costPaise)),
                    ),
                ],
                if (t.collections.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.collected,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final c in t.collections)
                    ListTile(
                      dense: true,
                      title: Text(methodLabel(l, c.method)),
                      trailing: Text(fmt.inr(c.amountPaise)),
                    ),
                ],
              ],
            ),
          ),
          if (!blocked)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (can.contains('start'))
                      FilledButton.icon(
                        key: const Key('start-trip'),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l.startTrip),
                        onPressed: () =>
                            _push(context, StartTripScreen(trip: t)),
                      ),
                    if (t.status == 'started') ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.local_gas_station),
                        label: Text(l.fuel),
                        onPressed: () => _push(
                          context,
                          FuelFillScreen(
                            tripId: t.id,
                            vehicleId: t.vehicle?.id,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(l.chargeButton),
                        onPressed: () => showChargeSheet(context, t),
                      ),
                    ],
                    if (can.contains('requestCancel'))
                      OutlinedButton(
                        onPressed: () =>
                            _push(context, CancelRequestScreen(trip: t)),
                        child: Text(l.requestCancellation),
                      ),
                    if (can.contains('end'))
                      FilledButton.icon(
                        key: const Key('end-trip'),
                        icon: const Icon(Icons.flag),
                        label: Text(l.endTrip),
                        onPressed: () => _push(context, EndTripScreen(trip: t)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) => unawaited(
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen)),
  );
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner(this.view);
  final TripView view;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(
        view.conflict == 'TRIP_CANCELLED'
            ? context.l10n.conflictCancelledBanner
            : context.l10n.conflictReassignedBanner,
      ),
      subtitle: Text(context.l10n.conflictBannerDetail),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Elapsed time and GPS distance while the trip is running.
class _LiveTrip extends ConsumerStatefulWidget {
  const _LiveTrip({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_LiveTrip> createState() => _LiveTripState();
}

class _LiveTripState extends ConsumerState<_LiveTrip> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final started = widget.trip.startedAt ?? DateTime.now();
    final km = ref.watch(tripDistanceProvider(widget.trip.id)).value ?? 0;
    final theme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (final (value, label) in [
              (
                formatDuration(DateTime.now().difference(started)),
                context.l10n.elapsed,
              ),
              (context.fmt.number(km, decimals: 1), context.l10n.kmByGps),
            ])
              Expanded(
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value, style: theme.headlineSmall),
                    ),
                    Text(label, textAlign: TextAlign.center),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
