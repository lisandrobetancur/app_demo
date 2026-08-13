import 'package:flutter_test/flutter_test.dart';

import '../pages/pages.dart';
import '../support/support.dart';
import 'base_steps.dart';

/// Business steps around the cart, coupons and checkout.
class CartSteps extends BaseSteps {
  CartSteps(super.$)
    : _cart = CartPage($),
      _checkout = CheckoutPage($),
      _shell = AppShellPage($);

  final CartPage _cart;
  final CheckoutPage _checkout;
  final AppShellPage _shell;

  /// Switches to the cart tab and waits for its data state.
  Future<void> openCart() => step('Open the cart', () async {
    await _shell.openCart();
    await _waitForCart();
  });

  Future<void> _waitForCart() async {
    await _cart.waitUntilVisible();
    await _cart.state('data').waitUntilVisible();
  }

  /// Applies a coupon and asserts it was accepted (the applied-coupon row
  /// replaces the input).
  Future<void> applyValidCoupon(String code) =>
      step('Apply the valid coupon $code', () async {
        await _cart.enterCoupon(code);
        await _cart.applyCoupon();
        await $.pumpAndSettle();
        expect(
          _cart.removeCouponButton.exists,
          isTrue,
          reason: 'coupon $code should have been accepted',
        );
      });

  /// Applies a coupon expected to fail and asserts the differentiated inline
  /// error is shown with [expectedMessage].
  Future<void> applyRejectedCoupon(
    String code, {
    required String expectedMessage,
  }) => step('Apply the rejected coupon $code', () async {
    await _cart.enterCoupon(code);
    await _cart.applyCoupon();
    await $.pumpAndSettle();
    expect(
      _cart.couponErrorText.exists,
      isTrue,
      reason: 'coupon $code should have been rejected with an inline error',
    );
    expect(
      $(expectedMessage).exists,
      isTrue,
      reason: 'the error for $code must be the specific one, not a generic',
    );
  });

  /// Runs the three checkout steps and confirms the purchase.
  ///
  /// Card data is typed but never persisted — the app only stores the chosen
  /// method, so this also exercises that rule.
  Future<void> checkoutWithCard({required String addressId}) =>
      step('Check out paying by card', () async {
        expect(
          _cart.isCheckoutEnabled,
          isTrue,
          reason: 'checkout must be reachable with a valid cart',
        );
        await _cart.goToCheckout();
        await _checkout.waitUntilVisible();

        await step('Choose the delivery address', () async {
          await _checkout.selectAddress(addressId);
          await _checkout.goNext();
        });

        await step('Fill in the card details', () async {
          await _checkout.selectPaymentMethod('CARD');
          await _checkout.fillCard(
            number: '4111111111111111',
            holder: 'ANA MARIN',
            expiry: '12/29',
            cvv: '123',
          );
          expect(
            _checkout.isNextEnabled,
            isTrue,
            reason: 'a well-formed card must unlock the summary step',
          );
          await _checkout.goNext();
        });

        await step('Confirm the purchase', () async {
          await _checkout.confirm();
          await _checkout.successView.waitUntilVisible();
        });
      });

  /// Asserts the success screen shows an order number.
  Future<void> expectOrderCreated() =>
      step('Expect the order to be created', () async {
        expect(
          _checkout.orderNumberText.exists,
          isTrue,
          reason: 'the success screen must show the new order number',
        );
      });

  /// Asserts the totals block renders every line the cart promises.
  Future<void> expectTotalsVisible() => step(
    'Expect the totals to be visible',
    () async {
      expect(_cart.subtotalText.exists, isTrue, reason: 'subtotal is missing');
      expect(_cart.discountText.exists, isTrue, reason: 'discount is missing');
      expect(_cart.taxText.exists, isTrue, reason: 'tax is missing');
      expect(_cart.totalText.exists, isTrue, reason: 'total is missing');
    },
  );

  /// Asserts the cart is showing its empty state.
  Future<void> expectEmptyCart() => step('Expect an empty cart', () async {
    await _cart.waitUntilVisible();
    expect(
      _cart.state('empty').exists,
      isTrue,
      reason: 'the cart should be empty',
    );
  });

  /// Convenience for the seeded valid coupon.
  Future<void> applySeededValidCoupon() =>
      applyValidCoupon(TestData.validCoupon);
}
