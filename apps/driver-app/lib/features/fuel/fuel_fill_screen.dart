import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/models.dart';
import '../../core/media/captured_photo.dart';
import '../../core/repositories/fuel_repository.dart';
import '../../core/repositories/trips_repository.dart';
import '../common/errors.dart';
import '../common/format.dart';
import '../common/widgets.dart';
import 'fuel_vehicle.dart';

/// Receipt photo, odometer photo + km, quantity, amount, full-tank toggle, who paid.
///
/// The vehicle comes from the driver's trips, never from the whole fleet: opened
/// from a trip, it's that trip's vehicle; otherwise see [fuelVehicleOptions].
class FuelFillScreen extends ConsumerStatefulWidget {
  const FuelFillScreen({this.tripId, this.vehicleId, super.key});
  final String? tripId;

  /// The trip's vehicle, when opened from a trip; the driver can't change it.
  final String? vehicleId;

  @override
  ConsumerState<FuelFillScreen> createState() => _FuelFillScreenState();
}

class _FuelFillScreenState extends ConsumerState<FuelFillScreen> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  final _km = TextEditingController();
  String? _vehicleId;
  String? _fuel;
  bool _fullTank = true;
  String _paidBy = 'driver_cash';
  CapturedPhoto? _receipt;
  CapturedPhoto? _odometer;
  bool _showPhotoErrors = false;

  @override
  void initState() {
    super.initState();
    _vehicleId = widget.vehicleId;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _amount.dispose();
    _km.dispose();
    super.dispose();
  }

  Future<void> _save(Vehicle vehicle, String? tripId) async {
    final valid = _form.currentState!.validate();
    setState(() => _showPhotoErrors = true);
    if (!valid || _receipt == null || _odometer == null) return;
    final fuel = _fuel ?? vehicle.allowedFuels.first;
    await ref
        .read(fuelRepositoryProvider)
        .record(
          FuelFillInput(
            vehicle: vehicle,
            fuel: fuel,
            quantityMilli: (double.parse(_quantity.text.trim()) * 1000).round(),
            costPaise: parseRupees(_amount.text)!,
            isFullTank: _fullTank,
            paidBy: _paidBy,
            odometerKm: int.parse(_km.text.trim()),
            odometerPhoto: _odometer!,
            receipt: _receipt!,
            tripId: tripId,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.fuelSaved)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.logFuel)),
      body: _body(),
    );
  }

  Widget _body() {
    final vehicles = ref.watch(vehiclesProvider);
    final trips = ref.watch(tripsProvider);
    if (vehicles.isLoading || trips.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final l = context.l10n;
    final error = vehicles.error ?? trips.error;
    if (error != null) return Center(child: Text(errorText(l, error)));

    final fixedId = widget.vehicleId;
    final options = fixedId != null
        ? null
        : fuelVehicleOptions([
            for (final t in trips.value ?? const <TripView>[]) t.trip,
          ], DateTime.now());
    if (options != null && options.isEmpty) {
      return _Message(l.noVehicleAssigned);
    }
    final selectedId = fixedId ?? _vehicleId ?? options!.first.vehicle.id;
    final option = options?.firstWhere((o) => o.vehicle.id == selectedId);
    // A fill made during a running trip belongs to it.
    final tripId =
        widget.tripId ??
        (option?.trip.status == 'started' ? option!.trip.id : null);

    final vehicle = (vehicles.value ?? const <Vehicle>[])
        .where((v) => v.id == selectedId)
        .firstOrNull;
    if (vehicle == null) {
      return _Message(l.vehicleNotDownloaded);
    }
    final fuel = vehicle.allowedFuels.contains(_fuel)
        ? _fuel!
        : vehicle.allowedFuels.first;
    final unit = context.fmt.unitFor(fuel);
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (options == null || options.length == 1)
            InputDecorator(
              key: const Key('fuel-vehicle'),
              decoration: InputDecoration(
                labelText: l.vehicle,
                helperText: option == null
                    ? l.vehicleOnThisTrip
                    : l.fromYourTrip(route: option.trip.routeLabel),
                border: const OutlineInputBorder(),
              ),
              child: Text('${vehicle.registrationNo} · ${vehicle.model}'),
            )
          else
            DropdownButtonFormField<String>(
              key: const Key('fuel-vehicle'),
              initialValue: selectedId,
              decoration: InputDecoration(
                labelText: l.vehicle,
                helperText: l.vehiclesOnYourTrips,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final o in options)
                  DropdownMenuItem(
                    value: o.vehicle.id,
                    child: Text(
                      '${o.vehicle.registrationNo} · ${o.trip.routeLabel}',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() {
                _vehicleId = v;
                _fuel = null;
              }),
            ),
          const SizedBox(height: 12),
          if (vehicle.allowedFuels.length > 1)
            SegmentedButton<String>(
              segments: [
                for (final f in vehicle.allowedFuels)
                  ButtonSegment(value: f, label: Text(fuelName(l, f))),
              ],
              selected: {fuel},
              onSelectionChanged: (s) => setState(() => _fuel = s.first),
            )
          else
            Text(l.fuelKind(fuel: fuelName(l, fuel))),
          const SizedBox(height: 12),
          PhotoField(
            kind: 'fuel_receipt',
            label: l.receiptPhoto,
            photo: _receipt,
            errorText: _showPhotoErrors && _receipt == null
                ? l.takeReceiptPhoto
                : null,
            onChanged: (p) => setState(() => _receipt = p),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l.quantity,
                    suffixText: unit,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final q = double.tryParse((v ?? '').trim());
                    if (q == null || q <= 0 || q > 200) {
                      return l.enterQuantity(unit: unit);
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l.amount,
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => validateRupees(l, v),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.fullTank),
            subtitle: Text(l.fullTankHint),
            value: _fullTank,
            onChanged: (v) => setState(() => _fullTank = v),
          ),
          Text(l.whoPaid),
          const SizedBox(height: 4),
          SegmentedButton<String>(
            segments: [
              for (final e in paidByChoices(l).entries)
                ButtonSegment(value: e.key, label: Text(e.value)),
            ],
            selected: {_paidBy},
            onSelectionChanged: (s) => setState(() => _paidBy = s.first),
          ),
          const SizedBox(height: 16),
          PhotoField(
            kind: 'odometer',
            label: l.odometerPhoto,
            photo: _odometer,
            errorText: _showPhotoErrors && _odometer == null
                ? l.takeOdometerPhoto
                : null,
            onChanged: (p) => setState(() => _odometer = p),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _km,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l.odometerReading,
              suffixText: l.unitKm,
              border: const OutlineInputBorder(),
            ),
            validator: (v) => validateKm(l, v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _save(vehicle, tripId),
            child: Text(l.saveFuelFill),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
