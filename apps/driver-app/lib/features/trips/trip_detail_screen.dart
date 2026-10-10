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
    if (view == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Trip not found on this phone')),
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
                      formatInr(t.quotedFarePaise),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Line(
                  Icons.schedule,
                  '${formatDay(t.scheduledStartAt)}, '
                  '${formatTime(t.scheduledStartAt)} – ${formatTime(t.scheduledEndAt)}',
                ),
                _Line(Icons.trip_origin, t.fromText),
                if (t.toText != null) _Line(Icons.place, t.toText!),
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
                    'Start odometer: ${t.startOdometer!.typedKm} km',
                  ),
                if (t.endOdometer != null)
                  _Line(
                    Icons.speed,
                    'End odometer: ${t.endOdometer!.typedKm} km',
                  ),
                if (t.status == 'started' && !blocked) _LiveTrip(trip: t),
                if (t.cancellationPending)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.hourglass_top),
                      title: Text('Cancellation requested'),
                      subtitle: Text(
                        'Waiting for your owner to approve or reject it.',
                      ),
                    ),
                  ),
                if (t.charges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Charges',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final c in t.charges.where((c) => !c.voided))
                    ListTile(
                      dense: true,
                      title: Text(chargeKindLabels[c.kind] ?? c.kind),
                      subtitle: c.paidByDriver
                          ? const Text('Paid by you')
                          : null,
                      trailing: Text(formatInr(c.amountPaise)),
                    ),
                ],
                if (t.fuelFills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Fuel', style: Theme.of(context).textTheme.titleSmall),
                  for (final f in t.fuelFills)
                    ListTile(
                      dense: true,
                      title: Text(fuelFillLabel(f)),
                      subtitle: Text(paidByLabels[f.paidBy] ?? f.paidBy),
                      trailing: Text(formatInr(f.costPaise)),
                    ),
                ],
                if (t.collections.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Collected',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final c in t.collections)
                    ListTile(
                      dense: true,
                      title: Text(c.method.toUpperCase()),
                      trailing: Text(formatInr(c.amountPaise)),
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
                        label: const Text('Start trip'),
                        onPressed: () =>
                            _push(context, StartTripScreen(trip: t)),
                      ),
                    if (t.status == 'started') ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.local_gas_station),
                        label: const Text('Fuel'),
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
                        label: const Text('Charge'),
                        onPressed: () => showChargeSheet(context, t),
                      ),
                    ],
                    if (can.contains('requestCancel'))
                      OutlinedButton(
                        onPressed: () =>
                            _push(context, CancelRequestScreen(trip: t)),
                        child: const Text('Request cancellation'),
                      ),
                    if (can.contains('end'))
                      FilledButton.icon(
                        key: const Key('end-trip'),
                        icon: const Icon(Icons.flag),
                        label: const Text('End trip'),
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
            ? 'This trip was cancelled by the owner'
            : 'This trip has been reassigned to another driver',
      ),
      subtitle: const Text(
        'Anything you recorded offline for it was not applied. '
        'Your photos were still sent to the owner.',
      ),
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  formatDuration(DateTime.now().difference(started)),
                  style: theme.headlineSmall,
                ),
                const Text('elapsed'),
              ],
            ),
            Column(
              children: [
                Text(km.toStringAsFixed(1), style: theme.headlineSmall),
                const Text('km by GPS'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
