/// Semantics identifiers of the catalog feature, grouped per view.
///
/// The counterpart of `catalog_keys.dart` for tools that cannot see a Flutter
/// `Key`: Appium and Maestro on mobile, Playwright on the web. Each one reaches
/// the platform's accessibility layer as Android's `resource-id`, iOS's
/// `accessibilityIdentifier` and web's `flt-semantics-identifier`.
///
/// Contracts, like the keys: `<screen>_<element>_<type>` in English
/// snake_case, stable across language, country, theme and platform. Items of a
/// list carry a stable piece of their data — an id, a code — never their
/// position.

/// Semantics identifiers of the catalog list view.
class CatalogListSemanticIds {
  const CatalogListSemanticIds._();

  static const String view = 'catalog_list_view';
  static const String titleText = 'catalog_list_title_text';
  static const String searchInput = 'catalog_search_input';
  static const String filterButton = 'catalog_filter_button';
  static const String filterSheet = 'catalog_filter_sheet';
  static const String priceRangeSlider = 'catalog_price_range_slider';

  /// Carries the toggled state.
  static const String onlyInStockSwitch = 'catalog_only_in_stock_switch';
  static const String sortDropdown = 'catalog_sort_dropdown';
  static const String clearFiltersButton = 'catalog_clear_filters_button';
  static const String resultsCountText = 'catalog_results_count_text';
  static const String productsList = 'catalog_products_list';
  static const String emptyClearFiltersButton =
      'catalog_empty_clear_filters_button';
  static const String retryButton = 'catalog_retry_button';

  /// `catalog_list_state_<loading|data|empty|error>`.
  static String state(String state) => 'catalog_list_state_$state';

  /// `catalog_search_suggestion_<term>`. A suggestion is a past search, so the
  /// term itself is the stable part: lower-cased, every run of characters
  /// other than ASCII letters and digits turned into `_` ("Toyota Hilux" →
  /// `catalog_search_suggestion_toyota_hilux`).
  static String searchSuggestion(String term) =>
      'catalog_search_suggestion_${_slug(term)}';

  /// `catalog_category_filter_<category code>`. Carries the selected state.
  static String categoryFilter(String code) => 'catalog_category_filter_$code';

  /// `catalog_condition_filter_<condition>`. Carries the selected state.
  static String conditionFilter(String value) =>
      'catalog_condition_filter_$value';

  /// `catalog_sort_option_<sort>`.
  static String sortOption(String value) => 'catalog_sort_option_$value';

  /// `catalog_active_filter_chip_<category id|condition|price|stock>`.
  static String activeFilterChip(String id) => 'catalog_active_filter_chip_$id';

  /// `catalog_product_item_<product id>`.
  static String productItem(String id) => 'catalog_product_item_$id';

  /// `catalog_product_favorite_button_<product id>`.
  static String productFavoriteButton(String id) =>
      'catalog_product_favorite_button_$id';

  static String _slug(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Semantics identifiers of the product detail view.
class ProductDetailSemanticIds {
  const ProductDetailSemanticIds._();

  static const String view = 'product_detail_view';
  static const String titleText = 'product_detail_title_text';
  static const String image = 'product_detail_image';
  static const String nameText = 'product_detail_name_text';
  static const String favoriteToggleButton =
      'product_detail_favorite_toggle_button';
  static const String shareButton = 'product_detail_share_button';
  static const String priceText = 'product_detail_price_text';
  static const String stockText = 'product_detail_stock_text';
  static const String descriptionText = 'product_detail_description_text';
  static const String sellerText = 'product_detail_seller_text';
  static const String quantityStepper = 'product_detail_quantity_stepper';
  static const String quantityDecreaseButton =
      'product_detail_quantity_decrease_button';
  static const String quantityIncreaseButton =
      'product_detail_quantity_increase_button';
  static const String quantityText = 'product_detail_quantity_text';
  static const String addToCartButton = 'product_detail_add_to_cart_button';
  static const String ownProductNoticeText =
      'product_detail_own_product_notice_text';
  static const String editButton = 'product_detail_edit_button';
  static const String writeReviewButton = 'product_detail_write_review_button';
  static const String editOwnReviewButton =
      'product_detail_edit_own_review_button';
  static const String noReviewsText = 'product_detail_no_reviews_text';
  static const String reviewsList = 'product_detail_reviews_list';

  /// The snackbar confirming an action (added to cart, link copied, …).
  static const String messageText = 'product_detail_message_text';
  static const String retryButton = 'product_detail_retry_button';

  /// `product_detail_state_<loading|data|empty|error>`.
  static String state(String state) => 'product_detail_state_$state';

  /// `product_detail_review_item_<review id>`.
  static String reviewItem(String id) => 'product_detail_review_item_$id';
}

/// Semantics identifiers of the product form (create and edit share it).
class ProductFormSemanticIds {
  const ProductFormSemanticIds._();

  static const String view = 'product_form_view';
  static const String titleText = 'product_form_title_text';
  static const String nameInput = 'product_form_name_input';
  static const String descriptionInput = 'product_form_description_input';
  static const String priceInput = 'product_form_price_input';
  static const String stockInput = 'product_form_stock_input';

  /// The dropdown's text field: carries the selected category as its value.
  static const String categoryDropdown = 'product_form_category_dropdown';
  static const String conditionSelector = 'product_form_condition_selector';
  static const String imagePreview = 'product_form_image_preview';
  static const String imagePickerButton = 'product_form_image_picker_button';
  static const String errorText = 'product_form_error_text';
  static const String saveButton = 'product_form_save_button';
  static const String discardChangesDialog =
      'product_form_discard_changes_dialog';
  static const String discardChangesConfirmButton =
      'product_form_discard_changes_dialog_confirm_button';
  static const String discardChangesCancelButton =
      'product_form_discard_changes_dialog_cancel_button';
  static const String retryButton = 'product_form_retry_button';

  /// `product_form_state_<loading|data|empty|error>`.
  static String state(String state) => 'product_form_state_$state';

  /// `product_form_category_option_<category id>`, in the open dropdown.
  static String categoryOption(String id) => 'product_form_category_option_$id';

  /// `product_form_condition_option_<condition>`. Carries the selected state.
  static String conditionOption(String value) =>
      'product_form_condition_option_$value';
}

/// Semantics identifiers of the "my products" view.
class MyProductsSemanticIds {
  const MyProductsSemanticIds._();

  static const String view = 'my_products_view';
  static const String titleText = 'my_products_title_text';
  static const String createButton = 'my_products_create_button';
  static const String confirmDeleteDialog = 'my_products_confirm_delete_dialog';
  static const String confirmDeleteConfirmButton =
      'my_products_confirm_delete_dialog_confirm_button';
  static const String confirmDeleteCancelButton =
      'my_products_confirm_delete_dialog_cancel_button';
  static const String emptyCreateButton = 'my_products_empty_create_button';
  static const String retryButton = 'my_products_retry_button';

  /// `my_products_state_<loading|data|empty|error>`.
  static String state(String state) => 'my_products_state_$state';

  /// `my_products_item_<product id>`: one node whose text holds the name,
  /// status, price and stock.
  static String item(String id) => 'my_products_item_$id';

  /// `my_products_stock_input_<product id>`: the stock quick-edit stepper.
  static String stockInput(String id) => 'my_products_stock_input_$id';

  /// `my_products_stock_text_<product id>`: the stock value in the stepper.
  static String stockText(String id) => 'my_products_stock_text_$id';

  /// `my_products_stock_decrease_button_<product id>`.
  static String stockDecreaseButton(String id) =>
      'my_products_stock_decrease_button_$id';

  /// `my_products_stock_increase_button_<product id>`.
  static String stockIncreaseButton(String id) =>
      'my_products_stock_increase_button_$id';

  /// `my_products_edit_button_<product id>`.
  static String editButton(String id) => 'my_products_edit_button_$id';

  /// `my_products_toggle_status_button_<product id>`.
  static String toggleStatusButton(String id) =>
      'my_products_toggle_status_button_$id';

  /// `my_products_delete_button_<product id>`.
  static String deleteButton(String id) => 'my_products_delete_button_$id';
}

/// Semantics identifiers of the favorites view.
class FavoritesSemanticIds {
  const FavoritesSemanticIds._();

  static const String view = 'favorites_view';
  static const String titleText = 'favorites_title_text';
  static const String moveAllToCartButton = 'favorites_move_all_to_cart_button';

  /// The snackbar confirming a move to the cart.
  static const String messageText = 'favorites_message_text';
  static const String retryButton = 'favorites_retry_button';

  /// `favorites_state_<loading|data|empty|error>`.
  static String state(String state) => 'favorites_state_$state';

  /// `favorites_item_<product id>`: the card and its move-to-cart button.
  static String item(String id) => 'favorites_item_$id';

  /// `favorites_product_card_<product id>`: the card itself, whose text holds
  /// the product and any notice (out of stock, removed by its owner).
  static String productCard(String id) => 'favorites_product_card_$id';

  /// `favorites_toggle_button_<product id>`.
  static String toggleButton(String id) => 'favorites_toggle_button_$id';

  /// `favorites_move_to_cart_button_<product id>`.
  static String moveToCartButton(String id) =>
      'favorites_move_to_cart_button_$id';
}
