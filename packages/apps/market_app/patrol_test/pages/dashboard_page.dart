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

  Future<void> openCatalog() =>
      act('dashboard_to_catalog', () => goToCatalogButton.tap());

  Future<void> openCart() =>
      act('dashboard_to_cart', () => goToCartButton.tap());

  Future<void> openFavorites() =>
      act('dashboard_to_favorites', () => goToFavoritesButton.tap());

  Future<void> openMyProducts() =>
      act('dashboard_to_my_products', () => goToMyProductsButton.tap());

  Future<void> openCreateProduct() =>
      act('dashboard_to_create_product', () => goToCreateProductButton.tap());

  Future<void> openNotifications() =>
      act('notifications_opened', () => notificationsButton.tap());

  Future<void> tapLogout() => act('logout_tapped', () => logoutButton.tap());
}
