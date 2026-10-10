import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/models.dart';
import '../../core/repositories/trips_repository.dart';
import '../common/errors.dart';
import '../common/format.dart';
import 'trip_detail_screen.dart';

const _tripTypes = ['one_way', 'round_trip', 'local_rental'];
const _durations = [1, 2, 4, 8, 12, 24];

/// A trip the driver books themselves (e.g. a walk-in customer). It's assigned
/// to them in the vehicle they pick, and works offline like everything else.
class NewTripScreen extends ConsumerStatefulWidget {
  const NewTripScreen({super.key});

  @override
  ConsumerState<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends ConsumerState<NewTripScreen> {
  final _form = GlobalKey<FormState>();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _fare = TextEditingController();
  final _includedKm = TextEditingController();
  final _customer = TextEditingController();
  final _phone = TextEditingController();
  String _tripType = 'one_way';
  DateTime _start = _roundUp(DateTime.now());
  int _hours = 4;
  String? _vehicleId;
  String? _error;
  bool _busy = false;

  static DateTime _roundUp(DateTime t) {
    final next = t.add(Duration(minutes: 5 - t.minute % 5));
    return DateTime(next.year, next.month, next.day, next.hour, next.minute);
  }

  @override
  void dispose() {
    for (final c in [_from, _to, _fare, _includedKm, _customer, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;
    setState(
      () => _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save(Vehicle vehicle) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    try {
      final trip = await ref
          .read(tripsRepositoryProvider)
          .create(
            tripType: _tripType,
            fromText: _from.text.trim(),
            toText: _to.text.trim(),
            scheduledStartAt: _start,
            scheduledEndAt: _start.add(Duration(hours: _hours)),
            quotedFarePaise: parseRupees(_fare.text)!,
            includedKm: int.tryParse(_includedKm.text.trim()),
            customerName: _customer.text.trim().isEmpty
                ? null
                : _customer.text.trim(),
            customerPhone: phone.length == 10 ? '+91$phone' : null,
            vehicle: vehicle,
          );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TripDetailScreen(tripId: trip.id),
        ),
      );
    } on LocalRejection catch (error) {
      setState(() => _error = rejectionText(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.newTrip)),
      body: vehicles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(errorText(l, error))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.noVehiclesOffline, textAlign: TextAlign.center),
              ),
            );
          }
          final vehicle = list.firstWhere(
            (v) => v.id == _vehicleId,
            orElse: () => list.first,
          );
          final local = _tripType == 'local_rental';
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: [
                    for (final type in _tripTypes)
                      ButtonSegment(
                        value: type,
                        label: Text(tripTypeLabel(l, type)),
                      ),
                  ],
                  selected: {_tripType},
                  onSelectionChanged: (s) =>
                      setState(() => _tripType = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('trip-from'),
                  controller: _from,
                  decoration: InputDecoration(
                    labelText: l.pickup,
                    prefixIcon: const Icon(Icons.trip_origin),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l.enterPickup : null,
                ),
                if (!local) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('trip-to'),
                    controller: _to,
                    decoration: InputDecoration(
                      labelText: l.drop,
                      prefixIcon: const Icon(Icons.place),
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l.enterDrop : null,
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickStart,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l.starts,
                      prefixIcon: const Icon(Icons.schedule),
                    ),
                    child: Text(context.fmt.dayTime(_start)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _hours,
                  decoration: InputDecoration(
                    labelText: l.expectedDuration,
                    prefixIcon: const Icon(Icons.timelapse),
                  ),
                  items: [
                    for (final h in _durations)
                      DropdownMenuItem(
                        value: h,
                        child: Text(l.hours(count: h)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _hours = v ?? _hours),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('trip-vehicle'),
                  initialValue: vehicle.id,
                  decoration: InputDecoration(
                    labelText: l.vehicle,
                    prefixIcon: const Icon(Icons.directions_car),
                  ),
                  items: [
                    for (final v in list)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.registrationNo} · ${v.model}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _vehicleId = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('trip-fare'),
                        controller: _fare,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l.fare,
                          prefixText: '₹ ',
                        ),
                        validator: (v) => validateFare(l, v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('trip-included-km'),
                        controller: _includedKm,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.includedKm,
                          helperText: l.optional,
                          suffixText: l.unitKm,
                        ),
                        validator: (v) => validateIncludedKm(l, v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customer,
                  decoration: InputDecoration(
                    labelText: l.customerNameOptional,
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: l.customerMobileOptional,
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('create-trip'),
                  onPressed: _busy ? null : () => _save(vehicle),
                  icon: const Icon(Icons.add),
                  label: Text(l.createTrip),
                ),
                const SizedBox(height: 8),
                Text(
                  l.newTripFootnote,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
