import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/repositories/trips_repository.dart';
import '../common/format.dart';
import '../common/widgets.dart';
import '../fuel/fuel_fill_screen.dart';
import 'new_trip_screen.dart';
import 'trip_detail_screen.dart';

/// Groups trips the way a driver thinks about them.
Map<String, List<TripView>> groupTrips(List<TripView> trips, {DateTime? now}) {
  final today = (now ?? DateTime.now()).toLocal();
  final startOfToday = DateTime(today.year, today.month, today.day);
  final startOfTomorrow = startOfToday.add(const Duration(days: 1));
  final groups = <String, List<TripView>>{
    'On the road': [],
    'Today': [],
    'Upcoming': [],
    'Recent': [],
  };
  for (final view in trips) {
    final t = view.trip;
    final at = t.scheduledStartAt.toLocal();
    if (t.status == 'started') {
      groups['On the road']!.add(view);
    } else if (t.status == 'assigned' && at.isBefore(startOfTomorrow)) {
      groups['Today']!.add(view);
    } else if (t.status == 'assigned' || t.status == 'created') {
      groups['Upcoming']!.add(view);
    } else {
      groups['Recent']!.add(view);
    }
  }
  groups['Recent']!.sort(
    (a, b) => b.trip.scheduledStartAt.compareTo(a.trip.scheduledStartAt),
  );
  groups.removeWhere((_, list) => list.isEmpty);
  return groups;
}

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-trip'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const NewTripScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New trip'),
      ),
      appBar: AppBar(
        title: const Text('My trips'),
        actions: [
          IconButton(
            tooltip: 'Log fuel',
            icon: const Icon(Icons.local_gas_station),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FuelFillScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signout') ref.read(authProvider.notifier).signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(syncEngineProvider).syncNow(),
              child: trips.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('$error'),
                    ),
                  ],
                ),
                data: (list) {
                  final groups = groupTrips(list);
                  if (groups.isEmpty) {
                    return ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No trips yet. Pull down to refresh.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    children: [
                      for (final entry in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        for (final view in entry.value) _TripTile(view),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile(this.view);
  final TripView view;

  @override
  Widget build(BuildContext context) {
    final t = view.trip;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: t.status == 'started'
              ? TaxcyColors.blue700
              : TaxcyColors.blue50,
          foregroundColor: t.status == 'started'
              ? Colors.white
              : TaxcyColors.blue700,
          child: Icon(
            t.status == 'started' ? Icons.local_taxi : Icons.route,
            size: 20,
          ),
        ),
        title: Text(
          t.routeLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            '${formatDay(t.scheduledStartAt)}, ${formatTime(t.scheduledStartAt)}',
            if (t.vehicle != null) t.vehicle!.registrationNo,
            if (view.conflict != null)
              '⚠ ${view.conflict == 'TRIP_CANCELLED' ? 'Cancelled by owner' : 'Reassigned'}',
          ].join(' · '),
        ),
        trailing: StatusChip(t.status),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TripDetailScreen(tripId: t.id),
          ),
        ),
      ),
    );
  }
}
