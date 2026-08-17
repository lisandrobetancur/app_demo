import 'package:patrol/patrol.dart';

import 'steps/steps.dart';
import 'support/support.dart';

/// F07 → F08 → F11 → F12 · From the catalog to a confirmed order.
///
/// This is the critical path of the app: it ends in the single transaction
/// that creates the order, snapshots the items, decrements stock, empties the
/// cart and writes the notification.
void main() {
  e2eTest(
    'buys a product from the catalog and confirms the order',
    tags: <String>[Tags.smoke, Tags.exito],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Compra',
        feature: 'Carrito y checkout',
        story: 'Comprar un producto del catálogo hasta confirmar la orden',
        severity: Severity.blocker,
        description:
            'Camino crítico de la aplicación. Verifica además que los totales '
            'cuadren antes y después del cupón: subtotal - descuento, IVA sobre '
            'la base gravable, y total = base + IVA.',
      );
      testParam('Usuario', TestData.demoEmail);
      testParam('Producto', TestData.buyableProductName);
      testParam('Cupón', TestData.validCoupon);
      testParam('Dirección', 'addr_demo_home');
      testParam('Medio de pago', 'Tarjeta');

      await launchMarketApp($);
      final Steps steps = Steps($);

      await steps.auth.loginAsDemoUser();
      await steps.catalog.openCatalog();
      await steps.catalog.openProduct(TestData.buyableProductId);
      await steps.catalog.addCurrentProductToCart();
      await steps.catalog.leaveProductDetail();

      await steps.cart.openCart();
      // Checked on both sides of the coupon: the arithmetic has to hold with no
      // discount and with one applied, which is where it usually breaks.
      await steps.cart.expectTotalsAddUp();
      await steps.cart.applySeededValidCoupon();
      await steps.cart.expectTotalsAddUp();

      await steps.cart.checkoutWithCard(addressId: 'addr_demo_home');
      await steps.cart.expectOrderCreated();
    },
  );

  e2eTest(
    'shows seller actions on an own publication',
    tags: <String>[Tags.regression, Tags.exito],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Compra',
        feature: 'Catálogo',
        story: 'Ofrecer acciones de vendedor sobre una publicación propia',
        severity: Severity.normal,
        description:
            'Una publicación propia no se compra: el detalle debe ofrecer '
            'editar en lugar del CTA de compra.',
      );
      testParam('Usuario', TestData.demoEmail);
      testParam('Producto propio', TestData.ownProductName);

      await launchMarketApp($);
      final Steps steps = Steps($);

      await steps.auth.loginAsDemoUser();
      await steps.catalog.openCatalog();
      await steps.catalog.openProduct(TestData.ownProductId);

      await steps.catalog.expectOwnedByViewer();
    },
  );

  e2eTest(
    'rejects an expired coupon with its own message',
    tags: <String>[Tags.regression, Tags.negativo],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Compra',
        feature: 'Cupones',
        story: 'Rechazar un cupón vencido con su mensaje específico',
        severity: Severity.minor,
        description:
            'El error debe distinguir vencido de inexistente, y el descuento '
            'debe quedar en cero.',
      );
      testParam('Usuario', TestData.demoEmail);
      testParam('Cupón', TestData.expiredCoupon);

      await launchMarketApp($);
      final Steps steps = Steps($);

      await steps.auth.loginAsDemoUser();
      await steps.catalog.openCatalog();
      await steps.catalog.openProduct(TestData.buyableProductId);
      await steps.catalog.addCurrentProductToCart();
      await steps.catalog.leaveProductDetail();

      await steps.cart.openCart();
      await steps.cart.applyRejectedCoupon(
        TestData.expiredCoupon,
        expectedMessage: 'El cupón está vencido',
      );
    },
  );
}
