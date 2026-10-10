import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/owner_models.dart';
import '../common/format.dart';
import 'owner_providers.dart';
import 'owner_text.dart';
import 'owner_widgets.dart';

/// Every vehicle with its latest fuel verdict; tap for the full audit.
class FuelIndexScreen extends ConsumerWidget {
  const FuelIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final vehicles = ref.watch(fleetVehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.fuel)),
      body: RefreshPage(
        onRefresh: () async {
          ref
            ..invalidate(vehicleAuditProvider)
            ..invalidate(fleetVehiclesProvider);
          await ref.read(fleetVehiclesProvider.future);
        },
        children: [
          Text(l.fuelIntro, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          AsyncView(
            value: vehicles,
            onRetry: () => ref.invalidate(fleetVehiclesProvider),
            builder: (list) => list.isEmpty
                ? EmptyState(l.noVehiclesYet)
                : Column(
                    children: [
                      for (final v in list)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            key: ValueKey('fuel-vehicle-${v.id}'),
                            title: Text(formatRegistration(v.registrationNo)),
                            subtitle: _FuelSummary(
                              vehicleId: v.id,
                              text:
                                  '${v.make} ${v.model} · ${fuelName(l, v.fuelType)}',
                            ),
                            trailing: _LatestVerdict(v.id),
                            onTap: () => openScreen<void>(
                              context,
                              VehicleFuelScreen(vehicleId: v.id),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LatestVerdict extends ConsumerWidget {
  const _LatestVerdict(this.vehicleId);
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audit = ref.watch(vehicleAuditProvider(vehicleId)).value;
    if (audit == null) return const SizedBox(width: 24);
    final last = audit.cycles.lastOrNull;
    return last == null
        ? ToneChip(context.l10n.noCyclesShort)
        : VerdictChip(last.verdict);
  }
}

/// The vehicle line, plus its usual efficiency once the audit has loaded.
class _FuelSummary extends ConsumerWidget {
  const _FuelSummary({required this.vehicleId, required this.text});
  final String vehicleId;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audit = ref.watch(vehicleAuditProvider(vehicleId)).value;
    if (audit == null || audit.baselineMean == null) return Text(text);
    return Text(
      '$text · ${context.l10n.usualValue(value: fuelMetricText(context.fmt, audit, audit.baselineMean))}',
    );
  }
}

class VerdictChip extends StatelessWidget {
  const VerdictChip(this.verdict, {super.key});
  final String verdict;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (verdict) {
      'flagged' => ToneChip('⚠ ${l.verdictFlagged}', tone: Tone.danger),
      'invalid' => ToneChip('◆ ${l.verdictInvalid}', tone: Tone.warning),
      _ => ToneChip(l.verdictOk, tone: Tone.success),
    };
  }
}

/// One vehicle's fuel audit on its own page.
class VehicleFuelScreen extends ConsumerWidget {
  const VehicleFuelScreen({required this.vehicleId, super.key});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(fleetVehicleProvider(vehicleId)).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          v == null
              ? context.l10n.fuel
              : '${context.l10n.fuel} · ${formatRegistration(v.registrationNo)}',
        ),
      ),
      body: VehicleFuelPanel(vehicleId: vehicleId),
    );
  }
}

/// Chart of each cycle against the usual figure, the cycles, and the fills
/// (with void). Used on the fuel page and the vehicle page.
class VehicleFuelPanel extends ConsumerWidget {
  const VehicleFuelPanel({required this.vehicleId, super.key});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final audit = ref.watch(vehicleAuditProvider(vehicleId));
    final fills = ref.watch(fuelFillsProvider(vehicleId));
    return RefreshPage(
      onRefresh: () async {
        ref
          ..invalidate(fuelFillsProvider(vehicleId))
          ..invalidate(vehicleAuditProvider(vehicleId));
        await ref.read(vehicleAuditProvider(vehicleId).future);
      },
      children: [
        AsyncView(
          value: audit,
          onRetry: () => ref.invalidate(vehicleAuditProvider(vehicleId)),
          builder: (a) => SectionCard(
            title: a.isCost ? l.costByCycle : l.efficiencyByCycle,
            child: a.cycles.isEmpty
                ? EmptyState(l.noCycles)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatGrid([
                        StatTile(
                          label: l.usual,
                          value: fuelMetricText(fmt, a, a.baselineMean),
                        ),
                        StatTile(
                          label: l.cyclesInBaseline,
                          value: fmt.number(a.baselineCycles),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      FuelChart(audit: a),
                      const SizedBox(height: 8),
                      for (final c in a.cycles.reversed)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l.cycleRange(
                              from: fmt.date(c.startedAt),
                              to: fmt.date(c.endedAt),
                            ),
                          ),
                          subtitle: Text(
                            [
                              fmt.km(c.distanceKm),
                              fuelMetricText(fmt, a, c.metricValue),
                              l.usualValue(
                                value: fuelMetricText(fmt, a, c.baselineMean),
                              ),
                              if (c.deviation != null)
                                c.method == 'sigma'
                                    ? l.sigmaRule(
                                        value: fmt.number(
                                          c.deviation!,
                                          decimals: 1,
                                        ),
                                      )
                                    : l.percentRule(
                                        value: fmt.number(c.deviation!),
                                      ),
                            ].join(' · '),
                          ),
                          trailing: VerdictChip(c.verdict),
                        ),
                    ],
                  ),
          ),
        ),
        SectionCard(
          title: l.fuelFills,
          child: AsyncView(
            value: fills,
            onRetry: () => ref.invalidate(fuelFillsProvider(vehicleId)),
            builder: (list) => list.isEmpty
                ? EmptyState(l.noFills)
                : Column(children: [for (final f in list) _FillTile(f)]),
          ),
        ),
      ],
    );
  }
}

class _FillTile extends ConsumerWidget {
  const _FillTile(this.fill);
  final FuelFill fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final f = fill;
    final strike = TextStyle(
      decoration: f.voided ? TextDecoration.lineThrough : null,
      color: f.voided ? TaxcyColors.muted : null,
    );
    return ListTile(
      key: ValueKey('fill-${f.id}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${fuelName(l, f.fuel)} ${fmt.quantity(f.quantityMilli, f.fuel)} · ${fmt.inr(f.costPaise)}',
        style: strike,
      ),
      subtitle: Text(
        [
          fmt.dayTime(f.filledAt),
          ?f.driverName,
          fmt.km(f.odometer.typedKm),
          f.isFullTank ? l.fullTankShort : l.partialTank,
          ownerPaidByLabel(l, f.paidBy),
          if (f.ocrCostPaise != null && f.ocrCostPaise != f.costPaise)
            l.receiptAmount(amount: fmt.inr(f.ocrCostPaise!)),
        ].join(' · '),
        style: strike,
      ),
      trailing: f.voided
          ? null
          : TextButton(
              key: ValueKey('void-fill-${f.id}'),
              onPressed: () async {
                final reason = await askText(
                  context,
                  title: l.voidFillTitle,
                  intro: l.voidFillIntro(
                    quantity: fmt.quantity(f.quantityMilli, f.fuel),
                    amount: fmt.inr(f.costPaise),
                    when: fmt.dayTime(f.filledAt),
                  ),
                  label: l.reason,
                  hint: l.voidReasonHint,
                  confirm: l.voidFill,
                  destructive: true,
                );
                if (reason == null || !context.mounted) return;
                await runAction(context, () async {
                  await ref
                      .read(ownerApiProvider)
                      .voidFuelFill(f.id, reason: reason);
                  refreshAfter(ref, {OwnerArea.fuel, OwnerArea.alerts});
                });
              },
              child: Text(l.voidAction),
            ),
    );
  }
}

/// Each cycle's efficiency (or ₹/km for bi-fuel) as a line with dots coloured
/// by verdict, and the usual figure it was judged against as a dashed line.
class FuelChart extends StatelessWidget {
  const FuelChart({required this.audit, super.key});
  final VehicleFuelAudit audit;

  @override
  Widget build(BuildContext context) {
    final scale = audit.isCost ? 0.01 : 1.0;
    final cycles = audit.cycles.where((c) => c.metricValue != null).toList();
    if (cycles.isEmpty) return const SizedBox.shrink();
    final values = [
      for (final (i, c) in cycles.indexed)
        FlSpot(i.toDouble(), c.metricValue! * scale),
    ];
    final usual = [
      for (final (i, c) in cycles.indexed)
        if (c.baselineMean != null)
          FlSpot(i.toDouble(), c.baselineMean! * scale),
    ];
    final day = DateFormat('d MMM', context.fmt.locale);
    Color dot(String verdict) => switch (verdict) {
      'flagged' => Colors.red.shade700,
      'invalid' => Colors.amber.shade800,
      _ => TaxcyColors.blue700,
    };
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                audit.isCost ? '₹/${context.l10n.unitKm}' : audit.unitLabel,
                style: const TextStyle(fontSize: 11),
              ),
              sideTitles: const SideTitles(showTitles: true, reservedSize: 36),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (cycles.length / 4).ceilToDouble().clamp(1, 1000),
                getTitlesWidget: (x, meta) {
                  final i = x.round();
                  if (i < 0 || i >= cycles.length || x != i) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    day.format(cycles[i].endedAt.toLocal()),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: values,
              color: TaxcyColors.blue300,
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
                  radius: 4,
                  color: dot(cycles[index].verdict),
                  strokeWidth: 0,
                ),
              ),
            ),
            if (usual.isNotEmpty)
              LineChartBarData(
                spots: usual,
                color: TaxcyColors.muted,
                barWidth: 1.5,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}
