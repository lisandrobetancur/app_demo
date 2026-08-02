import 'package:flutter/foundation.dart';

/// Keys of the catalog list view (F07).
class CatalogListKeys {
  const CatalogListKeys._();

  static const Key view = Key('catalog_list_view');
  static const Key searchInput = Key('search_input');
  static const Key filterButton = Key('filter_button');
  static const Key filterSheet = Key('filter_sheet');
  static const Key priceRangeSlider = Key('price_range_slider');
  static const Key sortDropdown = Key('sort_dropdown');
  static const Key clearFiltersButton = Key('clear_filters_button');
  static const Key resultsCountText = Key('results_count_text');
  static const Key productsList = Key('products_list');

  /// `catalog_list_state_<estado>`.
  static Key state(String state) => Key('catalog_list_state_$state');

  /// `search_suggestion_<n>` (1-based).
  static Key searchSuggestion(int n) => Key('search_suggestion_$n');

  /// `category_filter_<code>`.
  static Key categoryFilter(String code) => Key('category_filter_$code');

  /// `condition_filter_<value>`.
  static Key conditionFilter(String value) => Key('condition_filter_$value');

  /// `sort_option_<value>`.
  static Key sortOption(String value) => Key('sort_option_$value');

  /// `active_filter_chip_<id>`.
  static Key activeFilterChip(String id) => Key('active_filter_chip_$id');

  /// `product_item_<id>`.
  static Key productItem(String id) => Key('product_item_$id');
}

/// Keys of the product detail view (F08).
class ProductDetailKeys {
  const ProductDetailKeys._();

  static const Key view = Key('product_detail_view');
  static const Key image = Key('product_image');
  static const Key priceText = Key('product_price_text');
  static const Key stockText = Key('product_stock_text');
  static const Key quantityStepper = Key('quantity_stepper');
  static const Key quantityIncreaseButton = Key(
    'quantity_stepper_increase_button',
  );
  static const Key quantityDecreaseButton = Key(
    'quantity_stepper_decrease_button',
  );
  static const Key addToCartButton = Key('add_to_cart_button');
  static const Key favoriteToggleButton = Key('favorite_toggle_button');
  static const Key shareProductButton = Key('share_product_button');
  static const Key reviewsList = Key('reviews_list');
  static const Key editProductButton = Key('edit_product_button');
  static const Key writeReviewButton = Key('write_review_button');

  /// `product_detail_state_<estado>`.
  static Key state(String state) => Key('product_detail_state_$state');

  /// `review_item_<id>`.
  static Key reviewItem(String id) => Key('review_item_$id');
}

/// Keys of the product create/edit form (F09).
class ProductFormKeys {
  const ProductFormKeys._();

  static const Key view = Key('product_create_view');
  static const Key nameInput = Key('product_name_input');
  static const Key descriptionInput = Key('product_description_input');
  static const Key priceInput = Key('product_price_input');
  static const Key stockInput = Key('product_stock_input');
  static const Key categoryDropdown = Key('product_category_dropdown');
  static const Key conditionSelector = Key('product_condition_selector');
  static const Key imagePickerButton = Key('product_image_picker_button');
  static const Key imagePreview = Key('product_image_preview');
  static const Key saveButton = Key('product_save_button');
  static const Key discardChangesDialog = Key('discard_changes_dialog');

  /// `product_condition_option_<value>`.
  static Key conditionOption(String value) =>
      Key('product_condition_option_$value');

  /// `product_category_option_<id>`.
  static Key categoryOption(String id) => Key('product_category_option_$id');
}

/// Keys of the my-products view (F10).
class MyProductsKeys {
  const MyProductsKeys._();

  static const Key view = Key('my_products_view');
  static const Key confirmDeleteDialog = Key('confirm_delete_dialog');

  /// `my_products_state_<estado>`.
  static Key state(String state) => Key('my_products_state_$state');

  /// `my_product_item_<id>`.
  static Key item(String id) => Key('my_product_item_$id');

  /// `edit_product_button_<id>`.
  static Key editButton(String id) => Key('edit_product_button_$id');

  /// `toggle_status_button_<id>`.
  static Key toggleStatusButton(String id) => Key('toggle_status_button_$id');

  /// `delete_product_button_<id>`.
  static Key deleteButton(String id) => Key('delete_product_button_$id');

  /// `stock_quick_edit_<id>`.
  static Key stockQuickEdit(String id) => Key('stock_quick_edit_$id');
}

/// Keys of the favorites view (F14).
class FavoritesKeys {
  const FavoritesKeys._();

  static const Key view = Key('favorites_view');
  static const Key moveAllToCartButton = Key('move_all_to_cart_button');

  /// `favorites_state_<estado>`.
  static Key state(String state) => Key('favorites_state_$state');

  /// `favorite_item_<id>`.
  static Key item(String id) => Key('favorite_item_$id');

  /// `favorite_toggle_button_<id>`.
  static Key toggleButton(String id) => Key('favorite_toggle_button_$id');

  /// `move_to_cart_button_<id>`.
  static Key moveToCartButton(String id) => Key('move_to_cart_button_$id');
}

/// Keys of the review form (F15).
class ReviewFormKeys {
  const ReviewFormKeys._();

  static const Key view = Key('review_form_view');
  static const Key commentInput = Key('review_comment_input');
  static const Key submitButton = Key('review_submit_button');
  static const Key editOwnReviewButton = Key('edit_own_review_button');

  /// `rating_star_<n>` (1-based).
  static Key ratingStar(int n) => Key('rating_star_$n');

  /// The five star keys, in order.
  static List<Key> get ratingStars =>
      List<Key>.generate(5, (int index) => ratingStar(index + 1));
}
