import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/api/models.dart';
import '../../core/media/captured_photo.dart';
import '../../core/repositories/trips_repository.dart';
import '../common/format.dart';
import '../common/widgets.dart';

const _uuid = Uuid();

final _kmFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(7),
];

Future<void> _submit(
  BuildContext context,
  Future<void> Function() action,
  void Function(String) onError,
) async {
  try {
    await action();
    if (context.mounted) Navigator.of(context).pop();
  } on LocalRejection catch (error) {
    onError(error.message);
  }
}

/// Odometer photo + typed km. Works offline: queued and synced later.
class StartTripScreen extends ConsumerStatefulWidget {
  const StartTripScreen({required this.trip, super.key});
  final Trip trip;

  @override
  ConsumerState<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends ConsumerState<StartTripScreen> {
  final _form = GlobalKey<FormState>();
  final _km = TextEditingController();
  CapturedPhoto? _photo;
  bool _photoMissing = false;
  String? _error;

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final valid = _form.currentState!.validate();
    setState(() => _photoMissing = _photo == null);
    if (!valid || _photo == null) return;
    await _submit(
      context,
      () => ref
          .read(tripsRepositoryProvider)
          .start(widget.trip, photo: _photo!, km: int.parse(_km.text.trim())),
      (message) => setState(() => _error = message),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Start trip')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.trip.routeLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          PhotoField(
            key: const Key('odometer-photo'),
            kind: 'odometer',
            label: 'Odometer photo',
            photo: _photo,
            errorText: _photoMissing ? 'Take a photo of the odometer' : null,
            onChanged: (p) => setState(() {
              _photo = p;
              _photoMissing = false;
            }),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('odometer-km'),
            controller: _km,
            keyboardType: TextInputType.number,
            inputFormatters: _kmFormatters,
            decoration: const InputDecoration(
              labelText: 'Odometer reading',
              suffixText: 'km',
              helperText: 'Type it exactly as shown',
              border: OutlineInputBorder(),
            ),
            validator: validateKm,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('confirm-start'),
            onPressed: _start,
            child: const Text('Start trip'),
          ),
        ],
      ),
    ),
  );
}

class _CollectionRow {
  _CollectionRow(this.method);
  String method;
  final amount = TextEditingController();
}

class _ChargeRow {
  String kind = 'toll';
  bool paidByDriver = true;
  final amount = TextEditingController();
}

/// End odometer, what the customer paid, and charges.
class EndTripScreen extends ConsumerStatefulWidget {
  const EndTripScreen({required this.trip, super.key});
  final Trip trip;

  @override
  ConsumerState<EndTripScreen> createState() => _EndTripScreenState();
}

class _EndTripScreenState extends ConsumerState<EndTripScreen> {
  final _form = GlobalKey<FormState>();
  final _km = TextEditingController();
  final _collections = [_CollectionRow('cash')];
  final _charges = <_ChargeRow>[];
  CapturedPhoto? _photo;
  bool _photoMissing = false;
  String? _error;

  @override
  void dispose() {
    _km.dispose();
    for (final c in _collections) {
      c.amount.dispose();
    }
    for (final c in _charges) {
      c.amount.dispose();
    }
    super.dispose();
  }

  /// Charges added earlier on this trip (the Charge button), already saved.
  List<TripCharge> get _addedCharges =>
      widget.trip.charges.where((c) => !c.voided).toList();

  /// Quoted fare plus every charge, as the server computes the expected fare.
  int get _expected =>
      widget.trip.quotedFarePaise +
      _addedCharges.fold<int>(0, (sum, c) => sum + c.amountPaise) +
      _charges.fold(0, (sum, c) => sum + (parseRupees(c.amount.text) ?? 0));

  /// "Fare ₹3,500 + extra fare ₹900 + expenses ₹200".
  String get _fareBreakdown {
    var extra = 0;
    var expenses = 0;
    for (final (kind, paise) in [
      for (final c in _addedCharges) (c.kind, c.amountPaise),
      for (final c in _charges) (c.kind, parseRupees(c.amount.text) ?? 0),
    ]) {
      if (isExtraFare(kind)) {
        extra += paise;
      } else {
        expenses += paise;
      }
    }
    return [
      'Fare ${formatInr(widget.trip.quotedFarePaise)}',
      if (extra > 0) 'extra fare ${formatInr(extra)}',
      if (expenses > 0) 'tolls & expenses ${formatInr(expenses)}',
    ].join(' + ');
  }

  /// Km driven beyond the trip's included km, from the end reading typed so far.
  int? get _kmOver {
    final included = widget.trip.includedKm;
    final startKm = widget.trip.startOdometer?.typedKm;
    final endKm = int.tryParse(_km.text.trim());
    if (included == null || startKm == null || endKm == null) return null;
    final over = endKm - startKm - included;
    return over > 0 ? over : null;
  }

  int get _fuelPaidByDriver => widget.trip.fuelFills
      .where((f) => f.paidBy == 'driver_cash')
      .fold<int>(0, (sum, f) => sum + f.costPaise);

  int get _alreadyCollected =>
      widget.trip.collections.fold<int>(0, (sum, c) => sum + c.amountPaise);

  Future<void> _end() async {
    final valid = _form.currentState!.validate();
    setState(() => _photoMissing = _photo == null);
    if (!valid || _photo == null) return;
    final collections = [
      for (final c in _collections)
        if ((parseRupees(c.amount.text) ?? 0) > 0)
          TripCollection(
            id: _uuid.v4(),
            method: c.method,
            amountPaise: parseRupees(c.amount.text)!,
          ),
    ];
    final charges = [
      for (final c in _charges)
        TripCharge(
          id: _uuid.v4(),
          kind: c.kind,
          amountPaise: parseRupees(c.amount.text)!,
          paidByDriver: !isExtraFare(c.kind) && c.paidByDriver,
        ),
    ];
    await _submit(
      context,
      () => ref
          .read(tripsRepositoryProvider)
          .end(
            widget.trip,
            photo: _photo!,
            km: int.parse(_km.text.trim()),
            collections: collections,
            charges: charges,
          ),
      (message) => setState(() => _error = message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startKm = widget.trip.startOdometer?.typedKm;
    return Scaffold(
      appBar: AppBar(title: const Text('End trip')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PhotoField(
              kind: 'odometer',
              label: 'Odometer photo',
              photo: _photo,
              errorText: _photoMissing ? 'Take a photo of the odometer' : null,
              onChanged: (p) => setState(() {
                _photo = p;
                _photoMissing = false;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('end-km'),
              controller: _km,
              keyboardType: TextInputType.number,
              inputFormatters: _kmFormatters,
              decoration: InputDecoration(
                labelText: 'Odometer reading',
                suffixText: 'km',
                helperText: startKm == null ? null : 'Started at $startKm km',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => validateKm(v, atLeast: startKm),
              onChanged: (_) => setState(() {}),
            ),
            if (_kmOver case final over?)
              Padding(
                key: const Key('km-over-included'),
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$over km over the ${widget.trip.includedKm} km included in '
                  'the fare. Add an extra km charge below.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Charges you paid or added',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final c in _addedCharges)
              ListTile(
                key: ValueKey('added-charge-${c.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(chargeKindLabels[c.kind] ?? c.kind),
                subtitle: Text('Added during the trip · ${chargeNote(c)}'),
                trailing: Text(formatInr(c.amountPaise)),
              ),
            for (final (index, c) in _charges.indexed)
              Row(
                children: [
                  DropdownButton<String>(
                    value: c.kind,
                    items: [
                      for (final e in chargeKindLabels.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) => setState(() => c.kind = v ?? c.kind),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: c.amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(prefixText: '₹ '),
                      validator: validateRupees,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (isExtraFare(c.kind))
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Extra fare'),
                    )
                  else ...[
                    Checkbox(
                      value: c.paidByDriver,
                      onChanged: (v) =>
                          setState(() => c.paidByDriver = v ?? true),
                    ),
                    const Text('I paid'),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _charges.removeAt(index)),
                  ),
                ],
              ),
            TextButton.icon(
              onPressed: () => setState(() => _charges.add(_ChargeRow())),
              icon: const Icon(Icons.add),
              label: const Text('Add toll, night charge, extra km…'),
            ),
            const SizedBox(height: 16),
            if (widget.trip.fuelFills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Fuel filled on this trip',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final f in widget.trip.fuelFills)
                ListTile(
                  key: ValueKey('trip-fuel-${f.id}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_gas_station_outlined),
                  title: Text(fuelFillLabel(f)),
                  subtitle: Text(paidByLabels[f.paidBy] ?? f.paidBy),
                  trailing: Text(formatInr(f.costPaise)),
                ),
              if (_fuelPaidByDriver > 0)
                Text(
                  '${formatInr(_fuelPaidByDriver)} of fuel paid by you is '
                  'paid back in your settlement; the customer doesn’t pay for it.',
                ),
              const SizedBox(height: 8),
            ],
            Text(
              'Customer paid · expected ${formatInr(_expected)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              _fareBreakdown,
              key: const Key('fare-breakdown'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_alreadyCollected > 0)
              Text(
                '${formatInr(_alreadyCollected)} already recorded during the trip',
              ),
            for (final (index, c) in _collections.indexed)
              Row(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'cash', label: Text('Cash')),
                      ButtonSegment(value: 'upi', label: Text('UPI')),
                      ButtonSegment(value: 'card', label: Text('Card')),
                    ],
                    selected: {c.method},
                    onSelectionChanged: (s) =>
                        setState(() => c.method = s.first),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: Key('collection-$index'),
                      controller: c.amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(prefixText: '₹ '),
                      validator: (v) => validateRupees(v, allowZero: true),
                    ),
                  ),
                  if (_collections.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _collections.removeAt(index)),
                    ),
                ],
              ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _collections.add(_CollectionRow('upi'))),
              icon: const Icon(Icons.call_split),
              label: const Text('Split payment'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _end, child: const Text('End trip')),
          ],
        ),
      ),
    );
  }
}

/// A started trip can only be cancelled with a reason and the owner's approval.
class CancelRequestScreen extends ConsumerStatefulWidget {
  const CancelRequestScreen({required this.trip, super.key});
  final Trip trip;

  @override
  ConsumerState<CancelRequestScreen> createState() =>
      _CancelRequestScreenState();
}

class _CancelRequestScreenState extends ConsumerState<CancelRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _km = TextEditingController();
  CapturedPhoto? _photo;
  bool _photoMissing = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    _km.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final valid = _form.currentState!.validate();
    setState(() => _photoMissing = _photo == null);
    if (!valid || _photo == null) return;
    await _submit(
      context,
      () => ref
          .read(tripsRepositoryProvider)
          .requestCancellation(
            widget.trip,
            reason: _reason.text.trim(),
            photo: _photo!,
            km: int.parse(_km.text.trim()),
          ),
      (message) => setState(() => _error = message),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request cancellation')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your owner will approve or reject this. The trip keeps running until then.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reason,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'e.g. Customer got off at Lonavala',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Tell your owner why' : null,
          ),
          const SizedBox(height: 16),
          PhotoField(
            kind: 'odometer',
            label: 'Odometer photo',
            photo: _photo,
            errorText: _photoMissing ? 'Take a photo of the odometer' : null,
            onChanged: (p) => setState(() {
              _photo = p;
              _photoMissing = false;
            }),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _km,
            keyboardType: TextInputType.number,
            inputFormatters: _kmFormatters,
            decoration: const InputDecoration(
              labelText: 'Odometer reading',
              suffixText: 'km',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                validateKm(v, atLeast: widget.trip.startOdometer?.typedKm),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _send, child: const Text('Send request')),
        ],
      ),
    ),
  );
}
