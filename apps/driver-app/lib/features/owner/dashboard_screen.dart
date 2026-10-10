import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api/owner_api.dart';
import '../../core/api/owner_models.dart';
import '../common/format.dart';
import 'alerts_screen.dart';
import 'documents_screen.dart';
import 'owner_providers.dart';
import 'owner_text.dart';
import 'owner_widgets.dart';
import 'review_screen.dart';
import 'trips/owner_trips_screen.dart';

const _severityOrder = {'critical': 0, 'warning': 1, 'info': 2};

/// Today at a glance: trips by status, what needs attention, documents due, and
/// the most urgent open alerts. [onOpenTab] switches the owner shell's tab.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({required this.onOpenTab, super.key});
  final ValueChanged<int> onOpenTab;

  static TripFilter todayFilter([DateTime? now]) {
    final (from, to) = istDayRange(istToday(now));
    return TripFilter(from: from, to: to);
  }

  static const _openAlerts = (status: 'open', kind: null, tripId: null);
  static const _dueDocuments = (
    vehicleId: null,
    driverId: null,
    expiringWithinDays: 30,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final filter = todayFilter();
    final trips = ref.watch(ownerTripsProvider(filter));
    final summary = ref.watch(alertSummaryProvider);
    final alerts = ref.watch(alertsProvider(_openAlerts));
    final documents = ref.watch(documentsProvider(_dueDocuments));
    return Scaffold(
      appBar: AppBar(title: Text(l.navDashboard)),
      body: RefreshPage(
        onRefresh: () async {
          ref
            ..invalidate(alertSummaryProvider)
            ..invalidate(alertsProvider(_openAlerts))
            ..invalidate(documentsProvider(_dueDocuments))
            ..invalidate(ownerTripsProvider(filter));
          await ref.read(ownerTripsProvider(filter).future);
        },
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${l.today} · ${fmt.calendarDate(istToday())}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SectionCard(
            title: l.todaysTrips,
            actions: [
              TextButton(onPressed: () => onOpenTab(1), child: Text(l.seeAll)),
            ],
            child: AsyncView(
              value: trips,
              onRetry: () => ref.invalidate(ownerTripsProvider(filter)),
              builder: (list) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in tripStatuses)
                        _CountTile(
                          key: ValueKey('today-$s'),
                          count: list.where((t) => t.status == s).length,
                          label: statusLabel(l, s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    EmptyState(l.noTripsToday)
                  else
                    for (final t
                        in [...list]..sort(
                          (a, b) =>
                              a.scheduledStartAt.compareTo(b.scheduledStartAt),
                        ))
                      OwnerTripTile(t),
                ],
              ),
            ),
          ),
          SectionCard(
            title: l.needsAttention,
            child: AsyncView(
              value: summary,
              onRetry: () => ref.invalidate(alertSummaryProvider),
              builder: (s) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountTile(
                    key: const Key('critical-count'),
                    count: s.critical,
                    label: l.criticalAlerts,
                    color: Colors.red.shade700,
                    onTap: () => onOpenTab(2),
                  ),
                  _CountTile(
                    count: s.warning,
                    label: l.severityWarning,
                    color: Colors.amber.shade900,
                    onTap: () => onOpenTab(2),
                  ),
                  _CountTile(
                    count: s.info,
                    label: l.severityInfo,
                    onTap: () => onOpenTab(2),
                  ),
                  _CountTile(
                    key: const Key('review-count'),
                    count: s.openReviewItems,
                    label: l.toReview,
                    onTap: () =>
                        openScreen<void>(context, const ReviewScreen()),
                  ),
                ],
              ),
            ),
          ),
          SectionCard(
            title: l.documentsDueSoon,
            actions: [
              TextButton(
                onPressed: () =>
                    openScreen<void>(context, const DocumentsScreen()),
                child: Text(l.seeAll),
              ),
            ],
            child: AsyncView(
              value: documents,
              onRetry: () => ref.invalidate(documentsProvider(_dueDocuments)),
              builder: (docs) {
                final due = docs
                    .where(
                      (d) => d.status == 'expiring' || d.status == 'expired',
                    )
                    .take(6)
                    .toList();
                if (due.isEmpty) return EmptyState(l.nothingExpiring);
                return Column(
                  children: [
                    for (final d in due)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(docTypeLabel(l, d.docType)),
                        subtitle: Text(fmt.calendarDate(d.expiresOn)),
                        trailing: DocumentStatusChip(d),
                      ),
                  ],
                );
              },
            ),
          ),
          SectionCard(
            title: l.openAlerts,
            actions: [
              TextButton(onPressed: () => onOpenTab(2), child: Text(l.seeAll)),
            ],
            child: AsyncView(
              value: alerts,
              onRetry: () => ref.invalidate(alertsProvider(_openAlerts)),
              builder: (list) {
                if (list.isEmpty) return EmptyState(l.noOpenAlerts);
                final sorted = [...list]..sort(_bySeverityThenNewest);
                return Column(
                  children: [
                    for (final a in sorted.take(6)) AlertCard(a, compact: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static int _bySeverityThenNewest(Alert a, Alert b) {
    final bySeverity = (_severityOrder[a.severity] ?? 3).compareTo(
      _severityOrder[b.severity] ?? 3,
    );
    return bySeverity != 0 ? bySeverity : b.createdAt.compareTo(a.createdAt);
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.count,
    required this.label,
    this.color,
    this.onTap,
    super.key,
  });

  final int count;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: TaxcyColors.blue50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TaxcyColors.blue100),
      ),
      child: Column(
        children: [
          Text(
            context.fmt.number(count),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color ?? TaxcyColors.blue800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, color: TaxcyColors.muted),
          ),
        ],
      ),
    ),
  );
}
