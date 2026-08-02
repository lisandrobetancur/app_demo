import 'package:flutter/foundation.dart';

/// Keys of the dashboard view (F06).
class DashboardKeys {
  const DashboardKeys._();

  static const Key view = Key('dashboard_view');
  static const Key greetingText = Key('dashboard_greeting_text');
  static const Key categoryCarousel = Key('category_carousel');
  static const Key recentProductsCarousel = Key('recent_products_carousel');
  static const Key goToCatalogButton = Key('go_to_catalog_button');
  static const Key goToCreateProductButton = Key('go_to_create_product_button');
  static const Key goToCartButton = Key('go_to_cart_button');
  static const Key goToFavoritesButton = Key('go_to_favorites_button');
  static const Key goToMyProductsButton = Key('go_to_my_products_button');
  static const Key notificationsButton = Key('notifications_button');
  static const Key logoutButton = Key('logout_button');
  static const Key logoutConfirmDialog = Key('dashboard_logout_dialog');
  static const Key refreshButton = Key('dashboard_refresh_button');

  /// `summary_card_<metric>` (metric: active_products, cart_items,
  /// cart_total, month_orders).
  static Key summaryCard(String metric) => Key('summary_card_$metric');

  /// `dashboard_state_<estado>`.
  static Key state(String state) => Key('dashboard_state_$state');

  /// `dashboard_category_item_<id>`.
  static Key categoryItem(String id) => Key('dashboard_category_item_$id');

  /// `dashboard_recent_item_<id>`.
  static Key recentItem(String id) => Key('dashboard_recent_item_$id');
}
