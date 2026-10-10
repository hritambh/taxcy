import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/models.dart';
import '../../../core/api/owner_api.dart';
import '../../common/format.dart';
import '../owner_providers.dart';
import '../owner_text.dart';
import '../owner_widgets.dart';
import 'create_trip_screen.dart';
import 'owner_trip_detail_screen.dart';

const tripStatuses = [
  'created',
  'assigned',
  'started',
  'ended',
  'settled',
  'cancelled',
];

/// Every trip in the fleet, filtered by status, IST day, driver and vehicle.
class OwnerTripsScreen extends ConsumerStatefulWidget {
  const OwnerTripsScreen({super.key});

  @override
  ConsumerState<OwnerTripsScreen> createState() => _OwnerTripsScreenState();
}

class _OwnerTripsScreenState extends ConsumerState<OwnerTripsScreen> {
  String? _status;
  String? _date;
  String? _driverId;
  String? _vehicleId;

  TripFilter get _filter {
    final range = _date == null ? null : istDayRange(_date!);
    return TripFilter(
      status: _status,
      driverId: _driverId,
      vehicleId: _vehicleId,
      from: range?.$1,
      to: range?.$2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final trips = ref.watch(ownerTripsProvider(_filter));
    return Scaffold(
      appBar: AppBar(title: Text(l.navTrips)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('owner-new-trip'),
        onPressed: () => openScreen<void>(context, const CreateTripScreen()),
        icon: const Icon(Icons.add),
        label: Text(l.newTrip),
      ),
      body: RefreshPage(
        onRefresh: () => ref.refresh(ownerTripsProvider(_filter).future),
        children: [
          _filters(context),
          AsyncView(
            value: trips,
            onRetry: () => ref.invalidate(ownerTripsProvider(_filter)),
            builder: (list) => list.isEmpty
                ? EmptyState(l.noTripsMatch)
                : Column(children: [for (final t in list) OwnerTripTile(t)]),
          ),
        ],
      ),
    );
  }

  Widget _filters(BuildContext context) {
    final l = context.l10n;
    Widget box(Widget child) => SizedBox(width: 200, child: child);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          box(
            DropdownButtonFormField<String?>(
              key: const Key('trip-status-filter'),
              initialValue: _status,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.status, isDense: true),
              items: [
                DropdownMenuItem<String?>(child: Text(l.allStatuses)),
                for (final s in tripStatuses)
                  DropdownMenuItem<String?>(
                    value: s,
                    child: Text(statusLabel(l, s)),
                  ),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
          ),
          box(
            InputDecorator(
              decoration: InputDecoration(
                labelText: l.pickDate,
                isDense: true,
                suffixIcon: _date == null
                    ? const Icon(Icons.calendar_today, size: 18)
                    : IconButton(
                        tooltip: l.anyDate,
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _date = null),
                      ),
              ),
              child: InkWell(
                onTap: () async {
                  final picked = await pickIsoDate(
                    context,
                    value: _date,
                    last: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Text(
                  _date == null ? l.anyDate : context.fmt.calendarDate(_date!),
                ),
              ),
            ),
          ),
          box(
            DriverPicker(
              value: _driverId,
              label: l.driver,
              noneLabel: l.allDrivers,
              onChanged: (v) => setState(() => _driverId = v),
            ),
          ),
          box(
            VehiclePicker(
              value: _vehicleId,
              label: l.vehicle,
              noneLabel: l.allVehicles,
              activeOnly: false,
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
          ),
        ],
      ),
    );
  }
}

/// A trip in owner lists: route, when, vehicle and driver, fare, status.
class OwnerTripTile extends StatelessWidget {
  const OwnerTripTile(this.trip, {super.key});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final t = trip;
    final who = t.vehicle == null
        ? l.unassigned
        : [
            formatRegistration(t.vehicle!.registrationNo),
            ?t.driverName,
          ].join(' · ');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        key: ValueKey('owner-trip-${t.id}'),
        leading: CircleAvatar(
          backgroundColor: TaxcyColors.blue50,
          foregroundColor: TaxcyColors.blue700,
          child: Icon(
            t.status == 'started' ? Icons.local_taxi : Icons.route,
            size: 20,
          ),
        ),
        title: Text(
          t.toText == null ? l.localTrip(from: t.fromText) : t.routeLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            fmt.dayTime(t.scheduledStartAt),
            who,
            if (t.customerName != null) t.customerName!,
          ].join(' · '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(fmt.inr(t.quotedFarePaise)),
            if (t.cancellationPending)
              const Icon(Icons.hourglass_top, size: 16, color: Colors.amber)
            else
              Text(
                statusLabel(l, t.status),
                style: const TextStyle(fontSize: 12, color: TaxcyColors.muted),
              ),
          ],
        ),
        onTap: () =>
            openScreen<void>(context, OwnerTripDetailScreen(tripId: t.id)),
      ),
    );
  }
}
