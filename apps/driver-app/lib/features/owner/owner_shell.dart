import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../common/format.dart';
import '../common/language_picker.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'documents_screen.dart';
import 'fuel_screens.dart';
import 'owner_providers.dart';
import 'owner_text.dart';
import 'owner_widgets.dart';
import 'people_screens.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'settlements_screen.dart';
import 'trips/owner_trips_screen.dart';
import 'vehicles_screen.dart';

/// Owner mode: Dashboard / Trips / Alerts / More. A bottom navigation bar on
/// phones, a side rail on wide screens (tablets, the web build on a desktop).
class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _tab = 0;

  void _open(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final summary = ref.watch(alertSummaryProvider).value;
    final alertCount = summary?.openAlerts ?? 0;
    final reviewCount = summary?.openReviewItems ?? 0;
    Widget badged(IconData icon, int count) => Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(icon),
    );
    final destinations = [
      (Icons.dashboard_outlined, l.navDashboard, 0),
      (Icons.route, l.navTrips, 0),
      (Icons.notifications_outlined, l.navAlerts, alertCount),
      (Icons.menu, l.navMore, reviewCount),
    ];
    final body = IndexedStack(
      index: _tab,
      children: [
        DashboardScreen(onOpenTab: _open),
        const OwnerTripsScreen(),
        const AlertsScreen(),
        const MoreScreen(),
      ],
    );
    final wide = MediaQuery.sizeOf(context).width >= 840;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              key: const Key('owner-rail'),
              selectedIndex: _tab,
              onDestinationSelected: _open,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              indicatorColor: TaxcyColors.blue100,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Icon(Icons.local_taxi, color: TaxcyColors.blue700),
              ),
              destinations: [
                for (final (icon, label, count) in destinations)
                  NavigationRailDestination(
                    icon: badged(icon, count),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        key: const Key('owner-nav'),
        selectedIndex: _tab,
        onDestinationSelected: _open,
        backgroundColor: Colors.white,
        indicatorColor: TaxcyColors.blue100,
        destinations: [
          for (final (icon, label, count) in destinations)
            NavigationDestination(icon: badged(icon, count), label: label),
        ],
      ),
    );
  }
}

/// Everything else: fleet, money, settings, language, mode switch, sign out.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(authProvider).value;
    final reviewCount =
        ref.watch(alertSummaryProvider).value?.openReviewItems ?? 0;
    Widget item(IconData icon, String title, Widget screen, {Key? key}) =>
        ListTile(
          key: key,
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openScreen<void>(context, screen),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.navMore)),
      body: ListView(
        children: [
          PageWidth(
            child: Column(
              children: [
                if (session != null)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(session.activeMembership?.orgName ?? ''),
                    subtitle: Text(
                      l.signedInAs(
                        name: session.name ?? formatPhone(session.phone),
                        roles: session.roles
                            .map((r) => roleLabel(l, r))
                            .join(', '),
                      ),
                    ),
                  ),
                const Divider(),
                item(
                  Icons.directions_car,
                  l.vehicles,
                  const VehiclesScreen(),
                  key: const Key('more-vehicles'),
                ),
                item(
                  Icons.badge,
                  l.drivers,
                  const DriversScreen(),
                  key: const Key('more-drivers'),
                ),
                item(
                  Icons.group,
                  l.members,
                  const MembersScreen(),
                  key: const Key('more-members'),
                ),
                item(
                  Icons.description,
                  l.documents,
                  const DocumentsScreen(),
                  key: const Key('more-documents'),
                ),
                item(
                  Icons.local_gas_station,
                  l.fuel,
                  const FuelIndexScreen(),
                  key: const Key('more-fuel'),
                ),
                ListTile(
                  key: const Key('more-review'),
                  leading: const Icon(Icons.fact_check),
                  title: Text(l.review),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reviewCount > 0) Badge(label: Text('$reviewCount')),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => openScreen<void>(context, const ReviewScreen()),
                ),
                item(
                  Icons.account_balance_wallet,
                  l.settlements,
                  const SettlementsScreen(),
                  key: const Key('more-settlements'),
                ),
                item(
                  Icons.settings,
                  l.settings,
                  const SettingsScreen(),
                  key: const Key('more-settings'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(l.language),
                  onTap: () => showLanguagePicker(context, ref),
                ),
                if (session?.isDriver ?? false)
                  ListTile(
                    key: const Key('switch-to-driver'),
                    leading: const Icon(Icons.local_taxi),
                    title: Text(l.driverMode),
                    onTap: () =>
                        ref.read(appModeProvider.notifier).set(AppMode.driver),
                  ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l.signOut),
                  onTap: () => ref.read(authProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
