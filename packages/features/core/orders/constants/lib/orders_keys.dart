import 'package:flutter/foundation.dart';

/// Keys of the orders list view (F13).
class OrdersListKeys {
  const OrdersListKeys._();

  static const Key view = Key('orders_list_view');
  static const Key searchInput = Key('orders_search_input');

  /// `orders_state_<estado>`.
  static Key state(String state) => Key('orders_state_$state');

  /// `order_status_filter_<value>`.
  static Key statusFilter(String value) => Key('order_status_filter_$value');

  /// `order_item_<id>`.
  static Key item(String id) => Key('order_item_$id');
}

/// Keys of the order detail view (F13).
class OrderDetailKeys {
  const OrderDetailKeys._();

  static const Key view = Key('order_detail_view');
  static const Key timeline = Key('order_timeline');
  static const Key cancelButton = Key('cancel_order_button');
  static const Key confirmCancelDialog = Key('confirm_cancel_dialog');
  static const Key reorderButton = Key('reorder_button');

  /// `order_detail_state_<estado>`.
  static Key state(String state) => Key('order_detail_state_$state');
}
