import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/models.dart';
import '../../core/media/captured_photo.dart';
import '../../core/repositories/fuel_repository.dart';
import '../common/format.dart';
import '../common/widgets.dart';

final _vehiclesProvider = FutureProvider<List<Vehicle>>(
  (ref) => ref.watch(fuelRepositoryProvider).vehicles(),
);

const _fuelNames = {'petrol': 'Petrol', 'diesel': 'Diesel', 'cng': 'CNG'};
const _paidByLabels = {
  'driver_cash': 'Me (cash)',
  'owner': 'Owner',
  'fuel_card': 'Fuel card',
};

/// Receipt photo, odometer photo + km, quantity, amount, full-tank toggle, who paid.
class FuelFillScreen extends ConsumerStatefulWidget {
  const FuelFillScreen({this.tripId, this.vehicleId, super.key});
  final String? tripId;

  /// Defaults the picker to the current trip's vehicle.
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

  Future<void> _save(Vehicle vehicle) async {
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
            tripId: widget.tripId,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fuel fill saved; it will sync automatically'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(_vehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Log fuel')),
      body: vehicles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No vehicles yet. Connect once to load them.'),
            );
          }
          final vehicle = list.firstWhere(
            (v) => v.id == _vehicleId,
            orElse: () => list.first,
          );
          final fuel = vehicle.allowedFuels.contains(_fuel)
              ? _fuel!
              : vehicle.allowedFuels.first;
          final unit = fuel == 'cng' ? 'kg' : 'L';
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: vehicle.id,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final v in list)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.registrationNo} · ${v.model}'),
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
                        ButtonSegment(
                          value: f,
                          label: Text(_fuelNames[f] ?? f),
                        ),
                    ],
                    selected: {fuel},
                    onSelectionChanged: (s) => setState(() => _fuel = s.first),
                  )
                else
                  Text('Fuel: ${_fuelNames[fuel] ?? fuel}'),
                const SizedBox(height: 12),
                PhotoField(
                  kind: 'fuel_receipt',
                  label: 'Receipt photo',
                  photo: _receipt,
                  errorText: _showPhotoErrors && _receipt == null
                      ? 'Take a photo of the receipt'
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
                          labelText: 'Quantity',
                          suffixText: unit,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final q = double.tryParse((v ?? '').trim());
                          if (q == null || q <= 0 || q > 200) {
                            return 'Enter the $unit filled';
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
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: validateRupees,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Full tank'),
                  subtitle: const Text(
                    'Turn on when the tank was filled completely',
                  ),
                  value: _fullTank,
                  onChanged: (v) => setState(() => _fullTank = v),
                ),
                const Text('Who paid?'),
                const SizedBox(height: 4),
                SegmentedButton<String>(
                  segments: [
                    for (final e in _paidByLabels.entries)
                      ButtonSegment(value: e.key, label: Text(e.value)),
                  ],
                  selected: {_paidBy},
                  onSelectionChanged: (s) => setState(() => _paidBy = s.first),
                ),
                const SizedBox(height: 16),
                PhotoField(
                  kind: 'odometer',
                  label: 'Odometer photo',
                  photo: _odometer,
                  errorText: _showPhotoErrors && _odometer == null
                      ? 'Take a photo of the odometer'
                      : null,
                  onChanged: (p) => setState(() => _odometer = p),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _km,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Odometer reading',
                    suffixText: 'km',
                    border: OutlineInputBorder(),
                  ),
                  validator: validateKm,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _save(vehicle),
                  child: const Text('Save fuel fill'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
