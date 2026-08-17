import 'package:catalog_constants/catalog_constants.dart';
import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// F08 · Product detail.
class ProductDetailPage extends BasePage {
  const ProductDetailPage(super.$);

  @override
  PatrolFinder get root => $(ProductDetailKeys.view);

  PatrolFinder get priceText => $(ProductDetailKeys.priceText);

  PatrolFinder get stockText => $(ProductDetailKeys.stockText);

  PatrolFinder get addToCartButton => $(ProductDetailKeys.addToCartButton);

  PatrolFinder get quantityStepper => $(ProductDetailKeys.quantityStepper);

  PatrolFinder get increaseQuantityButton =>
      $(ProductDetailKeys.quantityIncreaseButton);

  PatrolFinder get decreaseQuantityButton =>
      $(ProductDetailKeys.quantityDecreaseButton);

  PatrolFinder get favoriteToggleButton =>
      $(ProductDetailKeys.favoriteToggleButton);

  PatrolFinder get shareButton => $(ProductDetailKeys.shareProductButton);

  /// Only rendered when the viewer owns the publication.
  PatrolFinder get editProductButton => $(ProductDetailKeys.editProductButton);

  PatrolFinder get reviewsList => $(ProductDetailKeys.reviewsList);

  PatrolFinder state(String name) => $(ProductDetailKeys.state(name));

  /// The app bar's implicit back button.
  ///
  /// Matched by widget type on purpose: `WidgetTester.pageBack()` looks for
  /// the English "Back" tooltip and this app runs in Spanish by default.
  PatrolFinder get backButton => $(BackButton);

  Future<void> goBack() => backButton.tap();

  Future<void> increaseQuantity() => increaseQuantityButton.tap();

  Future<void> decreaseQuantity() => decreaseQuantityButton.tap();

  Future<void> addToCart() => addToCartButton.tap();

  Future<void> toggleFavorite() => favoriteToggleButton.tap();

  /// False when the product is out of stock: the CTA stays disabled.
  ///
  /// Goes through the element layer so the rule is the shared one — including
  /// the loading state, which a bare `onPressed` check misses.
  bool get isAddToCartEnabled =>
      element(Loc.widgetKey(ProductDetailKeys.addToCartButton)).isEnabled;

  /// True when the viewer owns this publication (seller actions instead of
  /// the purchase CTA).
  bool get isOwnedByViewer => editProductButton.exists;
}
