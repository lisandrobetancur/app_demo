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
    tags: <String>[Tags.smoke, Tags.success],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.checkout,
        severity: Severity.blocker,
        description:
            'The critical path of the application. It also checks that the '
            'totals add up before and after the coupon: subtotal - discount, '
            'tax on the taxable base, and total = base + tax.',
      );
      await launchMarketApp($);
      final Steps steps = Steps($);

      // `testParam` goes AFTER the launch, not before: it reads from
      // `TestData`, and the data lives in the asset bundle, which does not
      // exist until the app has launched. It also records what the test
      // actually used, rather than what it meant to use.
      testParam('User', TestData.demoEmail);
      testParam('Product', TestData.buyableProductName);
      testParam('Coupon', TestData.validCoupon);
      testParam('Address', 'addr_demo_home');
      testParam('Payment method', 'Card');

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
    tags: <String>[Tags.regression, Tags.success],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.catalog,
        severity: Severity.normal,
        description:
            'Your own publication is not something you buy: the detail screen '
            'must offer editing instead of the purchase CTA.',
      );
      await launchMarketApp($);
      final Steps steps = Steps($);

      // `testParam` goes AFTER the launch, not before: it reads from
      // `TestData`, and the data lives in the asset bundle, which does not
      // exist until the app has launched. It also records what the test
      // actually used, rather than what it meant to use.
      testParam('User', TestData.demoEmail);
      testParam('Own product', TestData.ownProductName);

      await steps.auth.loginAsDemoUser();
      await steps.catalog.openCatalog();
      await steps.catalog.openProduct(TestData.ownProductId);

      await steps.catalog.expectOwnedByViewer();
    },
  );

  e2eTest(
    'rejects an expired coupon with its own message',
    tags: <String>[Tags.regression, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.coupons,
        severity: Severity.minor,
        description:
            'The error must tell expired apart from non-existent, and the '
            'discount must end up at zero.',
      );
      await launchMarketApp($);
      final Steps steps = Steps($);

      // `testParam` goes AFTER the launch, not before: it reads from
      // `TestData`, and the data lives in the asset bundle, which does not
      // exist until the app has launched. It also records what the test
      // actually used, rather than what it meant to use.
      testParam('User', TestData.demoEmail);
      testParam('Coupon', TestData.expiredCoupon);

      await steps.auth.loginAsDemoUser();
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
