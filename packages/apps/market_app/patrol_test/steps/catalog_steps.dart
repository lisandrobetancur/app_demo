import 'package:flutter_test/flutter_test.dart';

import '../pages/pages.dart';
import '../support/support.dart';

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
  Future<void> openCatalog() => step('Abre el catálogo', () async {
    await _dashboard.waitUntilVisible();
    await _dashboard.openCatalog();
    await _catalog.waitUntilVisible();
    await _catalog.state('data').waitUntilVisible();
  });

  /// Opens a product detail from the catalog list, scrolling to it first.
  Future<void> openProduct(String productId) =>
      step('Abre el producto $productId', () async {
        await _catalog.openProduct(productId);
        await _detail.waitUntilVisible();
        await _detail.state('data').waitUntilVisible();
      });

  /// Searches and asserts the expected product survived the filter.
  Future<void> searchAndExpect({
    required String term,
    required String expectedProductId,
  }) => step('Busca "$term"', () async {
    await _catalog.search(term);
    await $.pumpAndSettle();
    // Asserted through the finder rather than a bool, so a failure names the
    // widget it looked for. `isPresent` and not `isVisible` on purpose: a
    // product can legitimately be in the results and still need scrolling.
    should(
      seeThatIsPresent(
        'La búsqueda de "$term" conserva $expectedProductId en los resultados',
        _catalog.productItem(expectedProductId),
      ),
    );
  });

  /// Adds the product currently on screen to the cart.
  Future<void> addCurrentProductToCart({int quantity = 1}) =>
      step('Agrega el producto al carrito', () async {
        should(
          seeThat(
            'El producto se puede comprar antes de agregarlo al carrito',
            () => _detail.isAddToCartEnabled,
            isTrue,
          ),
        );
        for (int i = 1; i < quantity; i++) {
          await _detail.increaseQuantity();
        }
        await _detail.addToCart();
        await $.pumpAndSettle();
      });

  /// Leaves the product detail and returns to the tab it was opened from.
  ///
  /// The detail is a full-screen route pushed on top of the navigation shell,
  /// so the tabs are only reachable again after popping it.
  Future<void> leaveProductDetail() =>
      step('Sale del detalle del producto', () async {
        await _detail.goBack();
        await $.pumpAndSettle();
      });

  /// Asserts a product owned by the logged-in user shows seller actions
  /// instead of the purchase CTA.
  Future<void> expectOwnedByViewer() => step(
    'Se ofrecen las acciones de vendedor en una publicación propia',
    () async {
      await _detail.waitUntilVisible();
      should(
        seeThat(
          'Una publicación propia ofrece editar en vez de agregar al carrito',
          () => _detail.isOwnedByViewer,
          isTrue,
        ),
      );
    },
  );

  /// Asserts the CTA is disabled for a product with no stock.
  Future<void> expectOutOfStock() =>
      step('El botón de compra queda deshabilitado', () async {
        await _detail.waitUntilVisible();
        should(
          seeThat(
            'Un producto sin existencias deshabilita el botón de compra',
            () => _detail.isAddToCartEnabled,
            isFalse,
          ),
        );
      });
}
