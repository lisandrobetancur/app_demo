import 'package:flutter_test/flutter_test.dart';

import '../pages/pages.dart';
import 'base_steps.dart';

/// Business steps around browsing and opening products.
class CatalogSteps extends BaseSteps {
  CatalogSteps(super.$)
    : _dashboard = DashboardPage($),
      _catalog = CatalogPage($),
      _detail = ProductDetailPage($);

  final DashboardPage _dashboard;
  final CatalogPage _catalog;
  final ProductDetailPage _detail;

  /// Enters the catalog from the dashboard and waits for the data state.
  Future<void> openCatalog() => step('Open the catalog', () async {
    await _dashboard.waitUntilVisible();
    await _dashboard.openCatalog();
    await _catalog.waitUntilVisible();
    await _catalog.state('data').waitUntilVisible();
  });

  /// Opens a product detail from the catalog list, scrolling to it first.
  Future<void> openProduct(String productId) =>
      step('Open product $productId', () async {
        await _catalog.openProduct(productId);
        await _detail.waitUntilVisible();
        await _detail.state('data').waitUntilVisible();
      });

  /// Searches and asserts the expected product survived the filter.
  Future<void> searchAndExpect({
    required String term,
    required String expectedProductId,
  }) => step('Search "$term"', () async {
    await _catalog.search(term);
    await $.pumpAndSettle();
    // Asserted through the finder rather than a bool, so a failure names the
    // widget it looked for. `isPresent` and not `isVisible` on purpose: a
    // product can legitimately be in the results and still need scrolling.
    softly
        .assertThatWidget(_catalog.productItem(expectedProductId))
        .describedAs(
          'searching "$term" must keep $expectedProductId in the results',
        )
        .isPresent();
  });

  /// Adds the product currently on screen to the cart.
  Future<void> addCurrentProductToCart({int quantity = 1}) => step(
    'Add the product to the cart',
    () async {
      expectThat(
        'the product is purchasable before adding it to the cart',
        _detail.isAddToCartEnabled,
        isTrue,
      );
      for (int i = 1; i < quantity; i++) {
        await _detail.increaseQuantity();
      }
      await _detail.addToCart();
      await $.pumpAndSettle();
    },
  );

  /// Leaves the product detail and returns to the tab it was opened from.
  ///
  /// The detail is a full-screen route pushed on top of the navigation shell,
  /// so the tabs are only reachable again after popping it.
  Future<void> leaveProductDetail() =>
      step('Leave the product detail', () async {
        await _detail.goBack();
        await $.pumpAndSettle();
      });

  /// Asserts a product owned by the logged-in user shows seller actions
  /// instead of the purchase CTA.
  Future<void> expectOwnedByViewer() =>
      step('Expect seller actions on an own publication', () async {
        await _detail.waitUntilVisible();
        expectThat(
          'an own publication offers edit instead of add-to-cart',
          _detail.isOwnedByViewer,
          isTrue,
        );
      });

  /// Asserts the CTA is disabled for a product with no stock.
  Future<void> expectOutOfStock() =>
      step('Expect the purchase CTA disabled', () async {
        await _detail.waitUntilVisible();
        expectThat(
          'a product without stock disables the purchase CTA',
          _detail.isAddToCartEnabled,
          isFalse,
        );
      });
}
