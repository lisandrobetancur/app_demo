import 'package:cart_typing/cart_typing.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shell_keys.dart';
import '../shell_semantic_ids.dart';

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
        semanticsId: ShellSemanticIds.tabDashboard,
        icon: AppIcons.home,
        label: 'shell.tabs.dashboard'.tr(),
      ),
      _TabSpec(
        key: ShellKeys.tabCatalog,
        semanticsId: ShellSemanticIds.tabCatalog,
        icon: AppIcons.catalog,
        label: 'shell.tabs.catalog'.tr(),
      ),
      _TabSpec(
        key: ShellKeys.tabCart,
        semanticsId: ShellSemanticIds.tabCart,
        icon: AppIcons.cart,
        label: 'shell.tabs.cart'.tr(),
        badgeCount: cartCount,
      ),
      _TabSpec(
        key: ShellKeys.tabOrders,
        semanticsId: ShellSemanticIds.tabOrders,
        icon: AppIcons.orders,
        label: 'shell.tabs.orders'.tr(),
      ),
      _TabSpec(
        key: ShellKeys.tabProfile,
        semanticsId: ShellSemanticIds.tabProfile,
        icon: AppIcons.profile,
        label: 'shell.tabs.profile'.tr(),
      ),
    ];
    if (!wide) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: SemanticRegion(
          identifier: ShellSemanticIds.navigationBar,
          child: NavigationBar(
            key: ShellKeys.navigationBar,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            destinations: <Widget>[
              for (final _TabSpec tab in tabs)
                NavigationDestination(
                  key: tab.key,
                  icon: tab.labelled(
                    AppBadge(count: tab.badgeCount, child: Icon(tab.icon)),
                  ),
                  label: tab.label,
                ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: <Widget>[
          SemanticRegion(
            identifier: ShellSemanticIds.navigationRail,
            child: NavigationRail(
              key: ShellKeys.navigationRail,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: NavigationRailLabelType.all,
              destinations: <NavigationRailDestination>[
                for (final _TabSpec tab in tabs)
                  NavigationRailDestination(
                    icon: KeyedSubtree(
                      key: tab.key,
                      child: tab.labelled(
                        AppBadge(count: tab.badgeCount, child: Icon(tab.icon)),
                      ),
                    ),
                    label: Text(tab.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // A semantics boundary around the branch navigator. Each page in it
          // has a modal barrier whose BlockSemantics drops everything painted
          // before it in the same semantics container — which, without this
          // boundary, is the rail: it vanished from the accessibility tree
          // (screen readers, and every black-box tool on the web) while still
          // on screen. The bottom bar never had the problem: it is painted
          // after the body.
          Expanded(child: Semantics(container: true, child: navigationShell)),
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
    required this.semanticsId,
    this.badgeCount = 0,
  });

  final Key key;
  final IconData icon;
  final String label;
  final int badgeCount;
  final String semanticsId;

  /// Puts the tab's identifier on its icon: it joins the destination's own
  /// node — the one with the tap and the selected state — in both the bar and
  /// the rail.
  Widget labelled(Widget icon) =>
      Semantics(identifier: semanticsId, child: icon);
}
