import 'package:market_app/shell_keys.dart';
import 'package:patrol/patrol.dart';

import 'base_page.dart';

/// The navigation chrome around the five preserved tabs.
///
/// The shell renders a bottom bar below 768 px and a side rail above it, but
/// both use the same tab keys, so a test does not care which layout the
/// viewport produced.
class AppShellPage extends BasePage {
  const AppShellPage(super.$);

  @override
  PatrolFinder get root => $(ShellKeys.tabDashboard);

  PatrolFinder get dashboardTab => $(ShellKeys.tabDashboard);

  PatrolFinder get catalogTab => $(ShellKeys.tabCatalog);

  PatrolFinder get cartTab => $(ShellKeys.tabCart);

  PatrolFinder get ordersTab => $(ShellKeys.tabOrders);

  PatrolFinder get profileTab => $(ShellKeys.tabProfile);

  Future<void> openDashboard() => dashboardTab.tap();

  Future<void> openCatalog() => catalogTab.tap();

  Future<void> openCart() => cartTab.tap();

  Future<void> openOrders() => ordersTab.tap();

  Future<void> openProfile() => profileTab.tap();
}
