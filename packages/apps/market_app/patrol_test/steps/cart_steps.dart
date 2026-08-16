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
    await _cart.state('data').waitVisible();
  }

  /// Applies a coupon and asserts it was accepted *and* discounted the right
  /// amount.
  ///
  /// Accepting the coupon and applying it correctly are two different claims:
  /// the applied-coupon row can appear while the discount stays at zero. Both
  /// are checked, against the percentage the seed declares.
  Future<void> applyValidCoupon(String code) =>
      step('Apply the valid coupon $code', () async {
        final double subtotalBefore = _cart.subtotal;
        await _cart.enterCoupon(code);
        await _cart.applyCoupon();
        await $.pumpAndSettle();

        // Accepting the coupon and applying it correctly are different
        // claims that fail apart: the applied-coupon row can appear while the
        // discount stays at zero.
        should(
          seeThat(
            'the coupon $code is accepted and replaces the input',
            () => _cart.removeCouponButton.isDisplayed,
            isTrue,
          ),
          seeThat(
            'the subtotal is untouched by the coupon',
            () => _cart.subtotal,
            Money.closeToAmount(subtotalBefore),
          ),
          seeThat(
            'the discount is ${TestData.validCouponDiscountPct}% of the subtotal',
            () => _cart.discount.abs(),
            Money.closeToAmount(
              subtotalBefore * TestData.validCouponDiscountPct / 100,
            ),
          ),
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
    // "An error appeared" and "it is the *right* error" fail for
    // different reasons, so a generic message replacing a specific one
    // would otherwise look like no error at all.
    should(
      seeThat(
        'the coupon $code is rejected with an inline error',
        () => _cart.couponErrorText.isDisplayed,
        isTrue,
      ),
      seeThat(
        'the error for $code is the specific one, not a generic',
        () => $(expectedMessage).exists,
        isTrue,
      ),
      seeThat(
        'a rejected coupon discounts nothing',
        () => _cart.discount.abs(),
        Money.closeToAmount(0),
      ),
    );
  });

  /// Runs the three checkout steps and confirms the purchase.
  ///
  /// Card data is typed but never persisted — the app only stores the chosen
  /// method, so this also exercises that rule.
  Future<void> checkoutWithCard({required String addressId}) =>
      step('Check out paying by card', () async {
        // On its own: a cart that cannot check out makes everything below
        // meaningless, so this one is a precondition, not part of a claim.
        should(
          seeThat(
            'checkout is reachable with a valid cart',
            () => _cart.isCheckoutEnabled,
            isTrue,
          ),
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
          should(
            seeThat(
              'a well-formed card unlocks the summary step',
              () => _checkout.isNextEnabled,
              isTrue,
            ),
          );
          await _checkout.goNext();
        });

        await step('Confirm the purchase', () async {
          await _checkout.confirm();
          await _checkout.successView.waitUntilVisible();
        });
      });

  /// Asserts the success screen shows a real order identifier.
  ///
  /// Checking that the widget exists is not enough here: the view builds the
  /// number from a route path parameter that falls back to an empty string,
  /// so a lost parameter still renders the label — `"Orden "` — and a
  /// presence check passes on an order that cannot be found again.
  Future<void> expectOrderCreated() =>
      step('Expect the order to be created', () async {
        should(
          seeThat(
            'the success screen shows an order identifier',
            () => _checkout.orderNumber,
            matches(RegExp(r'^[0-9A-F]{8}$')),
          ),
        );
      });

  /// Asserts the totals block is arithmetically consistent.
  ///
  /// This is the rule `CartService` applies when it writes the order:
  ///
  ///     taxable = subtotal - discount
  ///     tax     = taxable * taxRate
  ///     total   = taxable + tax
  ///
  /// Checking the four rows exist proves nothing about it — a cart rendering
  /// zeros passes that. Reading them back and re-deriving the total is what
  /// makes this step worth a failure, and it is the same rule the user is
  /// charged by.
  ///
  /// Amounts are compared with [Money.tolerance] because the display currency
  /// renders whole units, so what is on screen is already rounded.
  Future<void> expectTotalsAddUp() => step(
    'Expect the totals to add up',
    () async {
      final double subtotal = _cart.subtotal;
      final double discount = _cart.discount.abs();
      final double taxable = subtotal - discount;

      // One batch, because these four are one claim: the totals block is
      // internally consistent. Checked together, a broken line does not hide
      // the others, and the report shows which of the four gave way.
      should(
        seeThat(
          'the subtotal is a real amount, not an empty cart',
          () => subtotal,
          greaterThan(0),
        ),
        seeThat(
          'the discount never exceeds the subtotal',
          () => discount,
          lessThanOrEqualTo(subtotal),
        ),
        seeThat(
          'VAT is ${(TestData.taxRate * 100).round()}% of the taxable base',
          () => _cart.tax,
          Money.closeToAmount(taxable * TestData.taxRate),
        ),
        seeThat(
          'the total is the taxable base plus VAT',
          () => _cart.total,
          Money.closeToAmount(taxable + taxable * TestData.taxRate),
        ),
      );
    },
  );

  /// Asserts the cart is showing its empty state.
  Future<void> expectEmptyCart() => step('Expect an empty cart', () async {
    await _cart.waitUntilVisible();
    should(
      seeThat(
        'the cart shows its empty state',
        () => _cart.state('empty').isDisplayed,
        isTrue,
      ),
    );
  });

  /// Convenience for the seeded valid coupon.
  Future<void> applySeededValidCoupon() =>
      applyValidCoupon(TestData.validCoupon);
}
