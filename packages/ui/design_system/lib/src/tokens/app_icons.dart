import 'package:flutter/material.dart';

/// Icon tokens.
///
/// Features never reference `Icons.*` directly; every glyph used in the app
/// has a semantic name here, including one per vehicle category code.
class AppIcons {
  const AppIcons._();

  // Navigation & app chrome.
  static const IconData home = Icons.home_outlined;
  static const IconData catalog = Icons.storefront_outlined;
  static const IconData cart = Icons.shopping_cart_outlined;
  static const IconData orders = Icons.receipt_long_outlined;
  static const IconData profile = Icons.person_outline;
  static const IconData settings = Icons.settings_outlined;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData back = Icons.arrow_back;
  static const IconData close = Icons.close;
  static const IconData search = Icons.search;
  static const IconData filter = Icons.tune;
  static const IconData sort = Icons.swap_vert;
  static const IconData refresh = Icons.refresh;
  static const IconData logout = Icons.logout;
  static const IconData language = Icons.translate;
  static const IconData theme = Icons.brightness_6_outlined;
  static const IconData currency = Icons.payments_outlined;
  static const IconData about = Icons.info_outline;

  // Actions.
  static const IconData add = Icons.add;
  static const IconData remove = Icons.remove;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData share = Icons.share_outlined;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData favorite = Icons.favorite;
  static const IconData favoriteOutline = Icons.favorite_border;
  static const IconData star = Icons.star;
  static const IconData starOutline = Icons.star_border;
  static const IconData camera = Icons.photo_camera_outlined;
  static const IconData image = Icons.image_outlined;
  static const IconData pause = Icons.pause_circle_outline;
  static const IconData play = Icons.play_circle_outline;
  static const IconData check = Icons.check_circle_outline;
  static const IconData checkFilled = Icons.check_circle;
  static const IconData warning = Icons.warning_amber_outlined;
  static const IconData error = Icons.error_outline;
  static const IconData emptyBox = Icons.inbox_outlined;
  static const IconData coupon = Icons.local_offer_outlined;
  static const IconData address = Icons.location_on_outlined;
  static const IconData payment = Icons.credit_card_outlined;
  static const IconData cash = Icons.attach_money;
  static const IconData transfer = Icons.account_balance_outlined;
  static const IconData timeline = Icons.schedule_outlined;
  static const IconData security = Icons.lock_outline;
  static const IconData chevronRight = Icons.chevron_right;

  // Vehicle categories, keyed by category code.
  static const IconData categoryCar = Icons.directions_car_outlined;
  static const IconData categoryMotorcycle = Icons.two_wheeler_outlined;
  static const IconData categoryScooter = Icons.electric_scooter_outlined;
  static const IconData categoryBicycle = Icons.pedal_bike_outlined;
  static const IconData categoryTruck = Icons.local_shipping_outlined;

  /// Resolves the icon for a category [code] (CAR, MOTORCYCLE, ...).
  static IconData forCategoryCode(String code) => switch (code) {
    'CAR' => categoryCar,
    'MOTORCYCLE' => categoryMotorcycle,
    'SCOOTER' => categoryScooter,
    'BICYCLE' => categoryBicycle,
    'TRUCK' => categoryTruck,
    _ => catalog,
  };
}
