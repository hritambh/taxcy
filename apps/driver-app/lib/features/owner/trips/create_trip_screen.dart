import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/api/json.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/format.dart';
import '../owner_providers.dart';
import '../owner_widgets.dart';
import 'owner_trip_detail_screen.dart';

/// What the create-trip form collected.
class NewTripInput {
  const NewTripInput({
    required this.tripType,
    required this.fromText,
    required this.toText,
    required this.start,
    required this.end,
    required this.fare,
    this.includedKm = '',
    this.customerName = '',
    this.customerPhone = '',
    this.vehicleId,
    this.driverId,
  });

  final String tripType;
  final String fromText;
  final String toText;
  final DateTime start;
  final DateTime end;

  /// As typed: rupees, km and phone digits.
  final String fare;
  final String includedKm;
  final String customerName;
  final String customerPhone;
  final String? vehicleId;
  final String? driverId;
}

/// The POST /trips body for [input], or the first problem with it (in the
/// user's language). Mirrors the admin web's checks.
({JsonMap? body, String? problem}) newTripBody(
  AppLocalizations l,
  NewTripInput input, {
  required String id,
}) {
  final fare = parseRupees(input.fare);
  final kmText = input.includedKm.trim();
  final km = kmText.isEmpty ? null : int.tryParse(kmText);
  final local = input.tripType == 'local_rental';
  final String? problem;
  if (input.fromText.trim().isEmpty) {
    problem = l.enterPickup;
  } else if (!local && input.toText.trim().isEmpty) {
    problem = l.enterDrop;
  } else if (fare == null) {
    problem = l.enterFare;
  } else if (kmText.isNotEmpty && (km == null || km < 1 || km > 20000)) {
    problem = l.includedKmInvalid;
  } else if (!input.end.isAfter(input.start)) {
    problem = l.rejectEndBeforeStart;
  } else if ((input.vehicleId == null) != (input.driverId == null)) {
    problem = l.pickBothOrNeither;
  } else {
    problem = null;
  }
  if (problem != null) return (body: null, problem: problem);
  final digits = input.customerPhone.replaceAll(RegExp(r'\D'), '');
  final name = input.customerName.trim();
  return (
    body: {
      'id': id,
      'tripType': input.tripType,
      'from': {'text': input.fromText.trim()},
      if (!local) 'to': {'text': input.toText.trim()},
      'scheduledStartAt': input.start.toUtc().toIso8601String(),
      'scheduledEndAt': input.end.toUtc().toIso8601String(),
      'quotedFarePaise': fare,
      'includedKm': ?km,
      if (name.isNotEmpty)
        'customer': {
          'name': name,
          if (digits.length >= 10)
            'phone': '+91${digits.substring(digits.length - 10)}',
        },
      if (input.vehicleId != null) ...{
        'vehicleId': input.vehicleId,
        'driverId': input.driverId,
      },
    },
    problem: null,
  );
}

/// Owner/manager creates a trip, optionally assigning a vehicle and driver.
class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  // One id per form, so a retried submit can't create the trip twice.
  final _id = const Uuid().v4();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _fare = TextEditingController();
  final _km = TextEditingController();
  final _customer = TextEditingController();
  final _phone = TextEditingController();
  String _tripType = 'one_way';
  late DateTime _start = _nextHour(DateTime.now());
  late DateTime _end = _start.add(const Duration(hours: 4));
  String? _vehicleId;
  String? _driverId;
  String? _problem;
  bool _busy = false;

  static DateTime _nextHour(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour + 1);

  @override
  void dispose() {
    for (final c in [_from, _to, _fare, _km, _customer, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final result = newTripBody(
      context.l10n,
      NewTripInput(
        tripType: _tripType,
        fromText: _from.text,
        toText: _to.text,
        start: _start,
        end: _end,
        fare: _fare.text,
        includedKm: _km.text,
        customerName: _customer.text,
        customerPhone: _phone.text,
        vehicleId: _vehicleId,
        driverId: _driverId,
      ),
      id: _id,
    );
    setState(() => _problem = result.problem);
    final body = result.body;
    if (body == null) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final ok = await runAction(context, () async {
      final trip = await ref.read(ownerApiProvider).createTrip(body);
      refreshAfter(ref, {OwnerArea.trips});
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OwnerTripDetailScreen(tripId: trip.id),
        ),
      );
    });
    if (!ok && mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final local = _tripType == 'local_rental';
    return Scaffold(
      appBar: AppBar(title: Text(l.newTrip)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: [
                    for (final t in const [
                      'one_way',
                      'round_trip',
                      'local_rental',
                    ])
                      ButtonSegment(value: t, label: Text(tripTypeLabel(l, t))),
                  ],
                  selected: {_tripType},
                  onSelectionChanged: (s) =>
                      setState(() => _tripType = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('owner-trip-from'),
                  controller: _from,
                  decoration: InputDecoration(
                    labelText: l.pickup,
                    prefixIcon: const Icon(Icons.trip_origin),
                  ),
                ),
                if (!local) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('owner-trip-to'),
                    controller: _to,
                    decoration: InputDecoration(
                      labelText: l.drop,
                      prefixIcon: const Icon(Icons.place),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: l.starts,
                        text: fmt.dayTime(_start),
                        onTap: () async {
                          final picked = await _pick(_start);
                          if (picked == null) return;
                          setState(() {
                            final length = _end.difference(_start);
                            _start = picked;
                            _end = picked.add(length);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: l.ends,
                        text: fmt.dayTime(_end),
                        onTap: () async {
                          final picked = await _pick(_end);
                          if (picked != null) setState(() => _end = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('owner-trip-fare'),
                        controller: _fare,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l.quotedFare,
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: const Key('owner-trip-km'),
                        controller: _km,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.includedKm,
                          helperText: l.includedKmHint,
                          helperMaxLines: 2,
                          suffixText: l.unitKm,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customer,
                  decoration: InputDecoration(
                    labelText: l.customerNameOptional,
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l.customerMobileOptional,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                VehiclePicker(
                  value: _vehicleId,
                  label: l.vehicleOptional,
                  noneLabel: l.assignLater,
                  onChanged: (v) => setState(() => _vehicleId = v),
                ),
                const SizedBox(height: 12),
                DriverPicker(
                  value: _driverId,
                  label: l.driverOptional,
                  noneLabel: l.assignLater,
                  onChanged: (v) => setState(() => _driverId = v),
                ),
                if (_problem != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _problem!,
                    key: const Key('owner-trip-problem'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('owner-create-trip'),
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.add),
                  label: Text(l.createTrip),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.text,
    required this.onTap,
  });

  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.schedule),
      ),
      child: Text(text),
    ),
  );
}
