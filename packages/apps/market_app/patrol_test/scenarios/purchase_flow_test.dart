import 'package:patrol/patrol.dart';

import '../steps/steps.dart';
import '../support/support.dart';

/// F07 → F08 → F11 → F12 · From the catalog to a confirmed order.
///
/// This is the critical path of the app: it ends in the single transaction
/// that creates the order, snapshots the items, decrements stock, empties the
/// cart and writes the notification.
void main() {
  e2eTest(
    'Compra de un producto del catálogo con confirmación de la orden',
    tags: <String>[Tags.smoke, Tags.success],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.checkout,
        severity: Severity.blocker,
        description:
            'La ruta crítica de la aplicación. Comprueba además que los '
            'totales cuadren antes y después del cupón: subtotal - descuento, '
            'IVA sobre la base gravable y total = base + IVA.',
      );
      await launchMarketApp($);
      final Steps steps = Steps($);

      // `testParam` goes AFTER the launch, not before: it reads from
      // `TestData`, and the data lives in the asset bundle, which does not
      // exist until the app has launched. It also records what the test
      // actually used, rather than what it meant to use.
      testParam('Usuario', TestData.demoEmail);
      testParam('Producto', TestData.buyableProductName);
      testParam('Cupón', TestData.validCoupon);
      testParam('Dirección', 'addr_demo_home');
      testParam('Medio de pago', 'Tarjeta');

      await steps.auth.login(
        email: TestData.demoEmail,
        password: TestData.demoPassword,
      );
      await steps.auth.expectLoggedInAs(TestData.demoFullName);
      await steps.catalog.openCatalog();
      await steps.catalog.openProduct(TestData.buyableProductId);
      await steps.catalog.addCurrentProductToCart();
      await steps.catalog.leaveProductDetail();

      await steps.cart.openCart();
      // Checked on both sides of the coupon: the arithmetic has to hold with no
      // discount and with one applied, which is where it usually breaks.
      await steps.cart.expectTotalsAddUp(taxRate: TestData.taxRate);
      await steps.cart.applyValidCoupon(
        TestData.validCoupon,
        discountPct: TestData.validCouponDiscountPct,
      );
      await steps.cart.expectTotalsAddUp(taxRate: TestData.taxRate);

      await steps.cart.checkoutWithCard(addressId: 'addr_demo_home');
      await steps.cart.expectOrderCreated();
    },
  );

  e2eTest(
    'Acciones de vendedor en una publicación propia',
    tags: <String>[Tags.regression, Tags.success],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.catalog,
        severity: Severity.normal,
        description:
            'Una publicación propia no es algo que se compre: el detalle '
            'debe ofrecer la edición en vez del botón de compra.',
      );
      await launchMarketApp($);
      final Steps steps = Steps($);

      // `testParam` goes AFTER the launch, not before: it reads from
      // `TestData`, and the data lives in the asset bundle, which does not
      // exist until the app has launched. It also records what the test
      // actually used, rather than what it meant to use.
      testParam('Usuario', TestData.demoEmail);
      testParam('Producto propio', TestData.ownProductName);

      await steps.auth.login(
        email: TestData.demoEmail,
        password: TestData.demoPassword,
      );
      await steps.auth.expectLoggedInAs(TestData.demoFullName);
      await steps.catalog.openCatalog();
      await steps.catalog.openProduct(TestData.ownProductId);

      await steps.catalog.expectOwnedByViewer();
    },
  );

  e2eTest(
    'Rechazo de un cupón vencido con su mensaje propio',
    tags: <String>[Tags.regression, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.coupons,
        severity: Severity.minor,
        description:
            'El error debe distinguir un cupón vencido de uno inexistente, '
            'y el descuento debe quedar en cero.',
      );
      await launchMarketApp($);
      final Steps steps = Steps($);

      // `testParam` goes AFTER the launch, not before: it reads from
      // `TestData`, and the data lives in the asset bundle, which does not
      // exist until the app has launched. It also records what the test
      // actually used, rather than what it meant to use.
      testParam('Usuario', TestData.demoEmail);
      testParam('Cupón', TestData.expiredCoupon);

      await steps.auth.login(
        email: TestData.demoEmail,
        password: TestData.demoPassword,
      );
      await steps.auth.expectLoggedInAs(TestData.demoFullName);
      await steps.catalog.openCatalog();
      await steps.catalog.openProduct(TestData.buyableProductId);
      await steps.catalog.addCurrentProductToCart();
      await steps.catalog.leaveProductDetail();

      await steps.cart.openCart();
      await steps.cart.applyRejectedCoupon(
        TestData.expiredCoupon,
        // The app's own wording — it is matched against the rendered message.
        expectedMessage: 'El cupón está vencido',
      );
    },
  );
}
