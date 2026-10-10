import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/api/models.dart';
import '../../core/media/captured_photo.dart';
import '../../core/repositories/trips_repository.dart';
import '../common/errors.dart';
import '../common/format.dart';
import '../common/widgets.dart';

Future<void> showChargeSheet(BuildContext context, Trip trip) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ChargeSheet(trip: trip),
      ),
    );

/// Toll, parking, allowance… with an optional receipt photo.
class _ChargeSheet extends ConsumerStatefulWidget {
  const _ChargeSheet({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_ChargeSheet> createState() => _ChargeSheetState();
}

class _ChargeSheetState extends ConsumerState<_ChargeSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  String _kind = 'toll';
  bool _paidByDriver = true;
  CapturedPhoto? _receipt;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    try {
      await ref
          .read(tripsRepositoryProvider)
          .addCharge(
            widget.trip,
            TripCharge(
              id: const Uuid().v4(),
              kind: _kind,
              amountPaise: parseRupees(_amount.text)!,
              paidByDriver: !isExtraFare(_kind) && _paidByDriver,
              mediaId: _receipt?.id,
            ),
            receipt: _receipt,
          );
      if (mounted) Navigator.of(context).pop();
    } on LocalRejection catch (error) {
      setState(() => _error = rejectionText(context.l10n, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.addCharge, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: InputDecoration(
                labelText: l.chargeType,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final kind in chargeKinds)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(chargeKindLabel(l, kind)),
                  ),
              ],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
            ),
            const SizedBox(height: 12),
            TextFormField(
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
            if (isExtraFare(_kind))
              ListTile(
                key: const Key('extra-fare-note'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_circle_outline),
                title: Text(l.extraFareTitle),
                subtitle: Text(l.extraFareSubtitle),
              )
            else
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.iPaidThis),
                subtitle: Text(l.paidBackInSettlement),
                value: _paidByDriver,
                onChanged: (v) => setState(() => _paidByDriver = v),
              ),
            PhotoField(
              kind: 'fuel_receipt',
              label: l.receiptPhotoOptional,
              photo: _receipt,
              onChanged: (p) => setState(() => _receipt = p),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: Text(l.addCharge)),
          ],
        ),
      ),
    );
  }
}
