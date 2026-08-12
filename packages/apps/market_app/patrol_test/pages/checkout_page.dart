import 'package:cart_constants/cart_constants.dart';
import 'package:design_system/design_system.dart';
import 'package:patrol/patrol.dart';

import 'base_page.dart';

/// F12 · Multi-step checkout and its success screen.
class CheckoutPage extends BasePage {
  const CheckoutPage(super.$);

  @override
  PatrolFinder get root => $(CheckoutKeys.view);

  PatrolFinder get stepIndicator => $(CheckoutKeys.stepIndicator);

  PatrolFinder get nextButton => $(CheckoutKeys.nextButton);

  PatrolFinder get backButton => $(CheckoutKeys.backButton);

  PatrolFinder get confirmButton => $(CheckoutKeys.confirmButton);

  PatrolFinder get addAddressButton => $(CheckoutKeys.addAddressButton);

  PatrolFinder get cardNumberInput => $(CheckoutKeys.cardNumberInput);

  PatrolFinder get cardHolderInput => $(CheckoutKeys.cardHolderInput);

  PatrolFinder get cardExpiryInput => $(CheckoutKeys.cardExpiryInput);

  PatrolFinder get cardCvvInput => $(CheckoutKeys.cardCvvInput);

  // --- Success screen ---
  PatrolFinder get successView => $(CheckoutKeys.successView);

  PatrolFinder get orderNumberText => $(CheckoutKeys.orderNumberText);

  PatrolFinder get goToOrderButton => $(CheckoutKeys.goToOrderButton);

  PatrolFinder get goToHomeButton => $(CheckoutKeys.goToHomeButton);

  /// Saved address option by id.
  PatrolFinder addressOption(String addressId) =>
      $(CheckoutKeys.addressOption(addressId));

  /// Payment method chip: `CARD`, `CASH` or `TRANSFER`.
  PatrolFinder paymentMethod(String value) =>
      $(CheckoutKeys.paymentMethod(value));

  Future<void> selectAddress(String addressId) =>
      addressOption(addressId).tap();

  Future<void> selectPaymentMethod(String value) => paymentMethod(value).tap();

  Future<void> fillCard({
    required String number,
    required String holder,
    required String expiry,
    required String cvv,
  }) async {
    await cardNumberInput.enterText(number);
    await cardHolderInput.enterText(holder);
    await cardExpiryInput.enterText(expiry);
    await cardCvvInput.enterText(cvv);
  }

  Future<void> goNext() => nextButton.tap();

  Future<void> goBack() => backButton.tap();

  Future<void> confirm() => confirmButton.tap();

  Future<void> openOrder() => goToOrderButton.tap();

  /// Disabled until the current step is valid.
  bool get isNextEnabled =>
      $.tester.widget<AppButton>(nextButton.finder).onPressed != null;
}
