import 'package:patrol/patrol.dart';

import 'steps/steps.dart';
import 'support/support.dart';

/// F07 → F08 → F11 → F12 · From the catalog to a confirmed order.
///
/// This is the critical path of the app: it ends in the single transaction
/// that creates the order, snapshots the items, decrements stock, empties the
/// cart and writes the notification.
void main() {
  patrolTest('buys a product from the catalog and confirms the order', (
    PatrolIntegrationTester $,
  ) async {
    await launchMarketApp($);
    final Steps steps = Steps($);

    await steps.auth.loginAsDemoUser();
    await steps.catalog.openCatalog();
    await steps.catalog.openProduct(TestData.buyableProductId);
    await steps.catalog.addCurrentProductToCart();
    await steps.catalog.leaveProductDetail();

    await steps.cart.openCart();
    steps.cart.expectTotalsVisible();
    await steps.cart.applySeededValidCoupon();

    await steps.cart.checkoutWithCard(addressId: 'addr_demo_home');
    steps.cart.expectOrderCreated();
  });

  patrolTest('shows seller actions on an own publication', (
    PatrolIntegrationTester $,
  ) async {
    await launchMarketApp($);
    final Steps steps = Steps($);

    await steps.auth.loginAsDemoUser();
    await steps.catalog.openCatalog();
    await steps.catalog.openProduct(TestData.ownProductId);

    await steps.catalog.expectOwnedByViewer();
  });

  patrolTest('rejects an expired coupon with its own message', (
    PatrolIntegrationTester $,
  ) async {
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
  });
}
