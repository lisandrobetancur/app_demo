import 'package:cart_typing/cart_typing.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shell_keys.dart';

/// Navigation chrome around the five preserved tab branches: bottom bar on
/// mobile widths, side rail on wide (web/desktop) layouts.
class AppNavigationShell extends ConsumerWidget {
  const AppNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int cartCount = ref.watch(cartItemCountProvider);
    final bool wide =
        MediaQuery.sizeOf(context).width >= AppSpacing.webBreakpoint;
    final List<_TabSpec> tabs = <_TabSpec>[
      _TabSpec(
        key: ShellKeys.tabDashboard,
        icon: AppIcons.home,
        label: 'shell.tabs.dashboard'.tr(),
      ),
      _TabSpec(
        key: ShellKeys.tabCatalog,
        icon: AppIcons.catalog,
        label: 'shell.tabs.catalog'.tr(),
      ),
      _TabSpec(
        key: ShellKeys.tabCart,
        icon: AppIcons.cart,
        label: 'shell.tabs.cart'.tr(),
        badgeCount: cartCount,
      ),
      _TabSpec(
        key: ShellKeys.tabOrders,
        icon: AppIcons.orders,
        label: 'shell.tabs.orders'.tr(),
      ),
      _TabSpec(
        key: ShellKeys.tabProfile,
        icon: AppIcons.profile,
        label: 'shell.tabs.profile'.tr(),
      ),
    ];
    if (!wide) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          key: ShellKeys.navigationBar,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: <Widget>[
            for (final _TabSpec tab in tabs)
              NavigationDestination(
                key: tab.key,
                icon: AppBadge(count: tab.badgeCount, child: Icon(tab.icon)),
                label: tab.label,
              ),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            key: ShellKeys.navigationRail,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            labelType: NavigationRailLabelType.all,
            destinations: <NavigationRailDestination>[
              for (final _TabSpec tab in tabs)
                NavigationRailDestination(
                  icon: KeyedSubtree(
                    key: tab.key,
                    child: AppBadge(
                      count: tab.badgeCount,
                      child: Icon(tab.icon),
                    ),
                  ),
                  label: Text(tab.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

/// One tab of the navigation shell.
class _TabSpec {
  const _TabSpec({
    required this.key,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final Key key;
  final IconData icon;
  final String label;
  final int badgeCount;
}
