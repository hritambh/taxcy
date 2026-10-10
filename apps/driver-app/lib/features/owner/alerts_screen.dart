import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/owner_models.dart';
import '../common/format.dart';
import 'documents_screen.dart';
import 'fuel_screens.dart';
import 'owner_providers.dart';
import 'owner_text.dart';
import 'owner_widgets.dart';
import 'trips/owner_trip_detail_screen.dart';
import 'vehicles_screen.dart';

/// The alerts inbox, filtered by status and kind.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String? _status = 'open';
  String? _kind;

  AlertQuery get _query => (status: _status, kind: _kind, tripId: null);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final alerts = ref.watch(alertsProvider(_query));
    Widget box(Widget child) => SizedBox(width: 220, child: child);
    return Scaffold(
      appBar: AppBar(title: Text(l.navAlerts)),
      body: RefreshPage(
        onRefresh: () => ref.refresh(alertsProvider(_query).future),
        children: [
          Text(l.alertsIntro, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              box(
                DropdownButtonFormField<String?>(
                  key: const Key('alert-status-filter'),
                  initialValue: _status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.status,
                    isDense: true,
                  ),
                  items: [
                    for (final s in const [
                      'open',
                      'acknowledged',
                      'resolved',
                      'dismissed',
                    ])
                      DropdownMenuItem<String?>(
                        value: s,
                        child: Text(alertStatusLabel(l, s)),
                      ),
                    DropdownMenuItem<String?>(child: Text(l.all)),
                  ],
                  onChanged: (v) => setState(() => _status = v),
                ),
              ),
              box(
                DropdownButtonFormField<String?>(
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.allKinds,
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem<String?>(child: Text(l.allKinds)),
                    for (final k in Alert.kinds)
                      DropdownMenuItem<String?>(
                        value: k,
                        child: Text(
                          alertKindLabel(l, k),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _kind = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AsyncView(
            value: alerts,
            onRetry: () => ref.invalidate(alertsProvider(_query)),
            builder: (list) => list.isEmpty
                ? EmptyState(_status == 'open' ? l.allClear : l.noAlertsMatch)
                : Column(children: [for (final a in list) AlertCard(a)]),
          ),
        ],
      ),
    );
  }
}

/// One alert, worded from its message code, with its actions.
class AlertCard extends ConsumerWidget {
  const AlertCard(this.alert, {this.compact = false, super.key});
  final Alert alert;

  /// The dashboard shows alerts without actions.
  final bool compact;

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    String status, {
    bool? falsePositive,
  }) => runAction(context, () async {
    await ref
        .read(ownerApiProvider)
        .updateAlert(alert.id, status, falsePositive: falsePositive);
    refreshAfter(ref, {OwnerArea.alerts, OwnerArea.fuel});
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final a = alert;
    final link = _subjectLink(context);
    return Card(
      key: ValueKey('alert-${a.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SeverityChip(a.severity),
                ToneChip(alertKindLabel(l, a.kind)),
                if (a.status != 'open') ToneChip(alertStatusLabel(l, a.status)),
                if (a.falsePositive) ToneChip(l.falseAlarm, tone: Tone.brand),
                Text(
                  fmt.dayTime(a.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: TaxcyColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alertTitle(fmt, a),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              alertBody(fmt, a),
              maxLines: compact ? 3 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (link != null)
                    TextButton(onPressed: link.$2, child: Text(link.$1)),
                  if (a.status == 'open')
                    TextButton(
                      key: const Key('alert-acknowledge'),
                      onPressed: () => _update(context, ref, 'acknowledged'),
                      child: Text(l.acknowledge),
                    ),
                  if (a.isOpen && a.isFuel)
                    OutlinedButton(
                      key: const Key('alert-false-alarm'),
                      onPressed: () => _update(
                        context,
                        ref,
                        'dismissed',
                        falsePositive: true,
                      ),
                      child: Text(l.dismissFalseAlarm),
                    ),
                  if (a.isOpen)
                    OutlinedButton(
                      key: const Key('alert-dismiss'),
                      onPressed: () => _update(context, ref, 'dismissed'),
                      child: Text(l.dismiss),
                    ),
                  if (a.isOpen)
                    FilledButton(
                      key: const Key('alert-resolve'),
                      onPressed: () => _update(context, ref, 'resolved'),
                      child: Text(l.markResolved),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, VoidCallback)? _subjectLink(BuildContext context) {
    final l = context.l10n;
    final a = alert;
    if (a.isFuel && a.vehicleId != null) {
      return (
        l.openFuelHistory,
        () => fire(
          openScreen(context, VehicleFuelScreen(vehicleId: a.vehicleId!)),
        ),
      );
    }
    if (a.tripId != null) {
      return (
        l.openTrip,
        () =>
            fire(openScreen(context, OwnerTripDetailScreen(tripId: a.tripId!))),
      );
    }
    if (a.subjectType == 'document') {
      return (
        l.openDocuments,
        () => fire(openScreen(context, const DocumentsScreen())),
      );
    }
    if (a.vehicleId != null) {
      return (
        l.openVehicle,
        () => fire(
          openScreen(context, VehicleDetailScreen(vehicleId: a.vehicleId!)),
        ),
      );
    }
    return null;
  }
}
