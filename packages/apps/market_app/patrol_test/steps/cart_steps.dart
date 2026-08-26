import 'package:flutter_test/flutter_test.dart';

import '../pages/pages.dart';
import '../support/support.dart';

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
  Future<void> openCart() => step('Abre el carrito', () async {
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
  /// are checked, against [discountPct] — handed in by the test, like every
  /// datum in this layer: a step asserts what it is told to expect, and the
  /// test says with which coupon and at what percentage.
  Future<void> applyValidCoupon(String code, {required double discountPct}) =>
      step('Aplica el cupón válido $code', () async {
        final double subtotalBefore = _cart.subtotal;
        await _cart.enterCoupon(code);
        await capturing(
          _cart.applyCoupon,
          before: 'El cupón $code escrito, antes de aplicarlo',
          after: 'El carrito con el cupón aplicado',
        );
        await $.pumpAndSettle();

        // Accepting the coupon and applying it correctly are different
        // claims that fail apart: the applied-coupon row can appear while the
        // discount stays at zero.
        should(
          seeThat(
            'El cupón $code es aceptado y reemplaza el campo de ingreso',
            () => _cart.removeCouponButton.isDisplayed,
            isTrue,
          ),
          seeThat(
            'El cupón no altera el subtotal',
            () => _cart.subtotal,
            Money.closeToAmount(subtotalBefore),
          ),
          seeThat(
            'El descuento es el $discountPct% del subtotal',
            () => _cart.discount.abs(),
            Money.closeToAmount(subtotalBefore * discountPct / 100),
          ),
        );
      });

  /// Applies a coupon expected to fail and asserts the differentiated inline
  /// error is shown with [expectedMessage].
  Future<void> applyRejectedCoupon(
    String code, {
    required String expectedMessage,
  }) => step('Aplica el cupón rechazado $code', () async {
    await _cart.enterCoupon(code);
    await _cart.applyCoupon();
    await $.pumpAndSettle();
    // "An error appeared" and "it is the *right* error" fail for
    // different reasons, so a generic message replacing a specific one
    // would otherwise look like no error at all.
    should(
      seeThat(
        'El cupón $code es rechazado con un error en línea',
        () => _cart.couponErrorText.isDisplayed,
        isTrue,
      ),
      seeThat(
        'El error de $code es el específico, no uno genérico',
        () => $(expectedMessage).exists,
        isTrue,
      ),
      seeThat(
        'Un cupón rechazado no descuenta nada',
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
      step('Paga con tarjeta', () async {
        // On its own: a cart that cannot check out makes everything below
        // meaningless, so this one is a precondition, not part of a claim.
        should(
          seeThat(
            'Se puede ir a pagar con un carrito válido',
            () => _cart.isCheckoutEnabled,
            isTrue,
          ),
        );
        await _cart.goToCheckout();
        await _checkout.waitUntilVisible();

        await step('Elige la dirección de entrega', () async {
          await _checkout.selectAddress(addressId);
          await _checkout.goNext();
        });

        await step('Diligencia los datos de la tarjeta', () async {
          await _checkout.selectPaymentMethod('CARD');
          await _checkout.fillCard(
            number: '4111111111111111',
            holder: 'ANA MARIN',
            expiry: '12/29',
            cvv: '123',
          );
          should(
            seeThat(
              'Una tarjeta bien diligenciada habilita el paso de resumen',
              () => _checkout.isNextEnabled,
              isTrue,
            ),
          );
          await capturing(
            _checkout.goNext,
            before: 'La tarjeta diligenciada, antes de continuar',
            after: 'El resumen de la compra',
          );
        });

        await step('Confirma la compra', () async {
          await capturing(
            _checkout.confirm,
            before: 'El resumen, justo antes de confirmar',
            after: 'La confirmación de la compra',
          );
          await _checkout.successView.waitUntilVisible();
        });
      });

  /// Asserts the success screen shows a real order identifier.
  ///
  /// Checking that the widget exists is not enough here: the view builds the
  /// number from a route path parameter that falls back to an empty string,
  /// so a lost parameter still renders the label — `"Orden "` — and a
  /// presence check passes on an order that cannot be found again.
  Future<void> expectOrderCreated() => step('Se crea la orden', () async {
    should(
      seeThat(
        'La pantalla de éxito muestra un identificador de orden',
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
  ///
  /// [taxRate] comes from the test, not from a lookup here: the step recomputes
  /// the arithmetic it is handed, and which rate the product is supposed to
  /// charge is the scenario's claim to make.
  Future<void> expectTotalsAddUp({required double taxRate}) =>
      step('Los totales cuadran', () async {
        final double subtotal = _cart.subtotal;
        final double discount = _cart.discount.abs();
        final double taxable = subtotal - discount;

        // One batch, because these four are one claim: the totals block is
        // internally consistent. Checked together, a broken line does not hide
        // the others, and the report shows which of the four gave way.
        should(
          seeThat(
            'El subtotal es un monto real, no un carrito vacío',
            () => subtotal,
            greaterThan(0),
          ),
          seeThat(
            'El descuento nunca supera al subtotal',
            () => discount,
            lessThanOrEqualTo(subtotal),
          ),
          seeThat(
            'El IVA es el ${(taxRate * 100).round()}% de la base gravable',
            () => _cart.tax,
            Money.closeToAmount(taxable * taxRate),
          ),
          seeThat(
            'El total es la base gravable más el IVA',
            () => _cart.total,
            Money.closeToAmount(taxable + taxable * taxRate),
          ),
        );
      });

  /// Asserts the cart is showing its empty state.
  Future<void> expectEmptyCart() => step('El carrito queda vacío', () async {
    await _cart.waitUntilVisible();
    should(
      seeThat(
        'El carrito muestra su estado vacío',
        () => _cart.state('empty').isDisplayed,
        isTrue,
      ),
    );
  });
}
