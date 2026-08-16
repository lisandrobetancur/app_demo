import 'package:dashboard_constants/dashboard_constants.dart';
import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

import 'base_page.dart';

/// F06 · Dashboard.
class DashboardPage extends BasePage {
  const DashboardPage(super.$);

  @override
  PatrolFinder get root => $(DashboardKeys.view);

  PatrolFinder get greeting => $(DashboardKeys.greetingText);

  /// The rendered greeting, e.g. "Hola, Ana Marín".
  ///
  /// Read from the widget instead of matching a literal: `$('text')` matches
  /// the whole string exactly, and the user's name is only a fragment of the
  /// translated sentence.
  String get greetingText => $.tester.widget<Text>(greeting.finder).data ?? '';

  PatrolFinder get notificationsButton => $(DashboardKeys.notificationsButton);

  PatrolFinder get logoutButton => $(DashboardKeys.logoutButton);

  PatrolFinder get goToCatalogButton => $(DashboardKeys.goToCatalogButton);

  PatrolFinder get goToCartButton => $(DashboardKeys.goToCartButton);

  PatrolFinder get goToFavoritesButton => $(DashboardKeys.goToFavoritesButton);

  PatrolFinder get goToMyProductsButton =>
      $(DashboardKeys.goToMyProductsButton);

  PatrolFinder get goToCreateProductButton =>
      $(DashboardKeys.goToCreateProductButton);

  /// Summary card by metric: `active_products`, `cart_items`, `cart_total`,
  /// `month_orders`.
  PatrolFinder summaryCard(String metric) =>
      $(DashboardKeys.summaryCard(metric));

  /// The quick actions sit below the summary, the categories and the recent
  /// products, so on a shorter screen they start off-screen — and far enough
  /// down that Flutter has not built them, which a finder reports as "Found 0
  /// widgets" rather than as something invisible. Scrolling first makes these
  /// independent of how tall the device happens to be: the same tap worked on
  /// a 411x914 phone and failed on a 394x804 emulator.
  Future<void> openCatalog() => _tapQuickAction(goToCatalogButton);

  Future<void> openCart() => _tapQuickAction(goToCartButton);

  Future<void> openFavorites() => _tapQuickAction(goToFavoritesButton);

  Future<void> openMyProducts() => _tapQuickAction(goToMyProductsButton);

  Future<void> openCreateProduct() => goToCreateProductButton.tap();

  Future<void> openNotifications() => notificationsButton.tap();

  Future<void> tapLogout() => logoutButton.tap();

  Future<void> _tapQuickAction(PatrolFinder action) async {
    await action.scrollTo();
    await action.tap();
  }
}
