part of com.demo.market.cart.core.state.checkout;

/// Checkout steps.
enum CheckoutStep {
  delivery,
  payment,
  summary;

  bool get isDelivery => this == CheckoutStep.delivery;

  bool get isPayment => this == CheckoutStep.payment;

  bool get isSummary => this == CheckoutStep.summary;
}

/// Immutable state of the multi-step checkout (F12).
///
/// Card fields are validated for format only and are **never persisted**;
/// only the chosen payment method reaches the database.
class CheckoutState {
  const CheckoutState({
    this.step = CheckoutStep.delivery,
    this.addresses = const <Address>[],
    this.selectedAddressId,
    this.paymentMethod = PaymentMethod.card,
    this.cardNumber = '',
    this.cardHolder = '',
    this.cardExpiry = '',
    this.cardCvv = '',
    this.status = ViewStatus.loading,
    this.isConfirming = false,
    this.errorKey,
  });

  final CheckoutStep step;
  final List<Address> addresses;
  final String? selectedAddressId;
  final PaymentMethod paymentMethod;
  final String cardNumber;
  final String cardHolder;
  final String cardExpiry;
  final String cardCvv;
  final ViewStatus status;
  final bool isConfirming;
  final String? errorKey;

  static final RegExp _cardNumberRegExp = RegExp(r'^\d{16}$');
  static final RegExp _expiryRegExp = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
  static final RegExp _cvvRegExp = RegExp(r'^\d{3,4}$');

  String? get cardNumberErrorKey =>
      cardNumber.isEmpty ||
          _cardNumberRegExp.hasMatch(cardNumber.replaceAll(' ', ''))
      ? null
      : 'cart.checkout.card_number_invalid';

  String? get cardExpiryErrorKey =>
      cardExpiry.isEmpty || _expiryRegExp.hasMatch(cardExpiry)
      ? null
      : 'cart.checkout.card_expiry_invalid';

  String? get cardCvvErrorKey => cardCvv.isEmpty || _cvvRegExp.hasMatch(cardCvv)
      ? null
      : 'cart.checkout.card_cvv_invalid';

  bool get isCardValid =>
      _cardNumberRegExp.hasMatch(cardNumber.replaceAll(' ', '')) &&
      cardHolder.trim().length >= 3 &&
      _expiryRegExp.hasMatch(cardExpiry) &&
      _cvvRegExp.hasMatch(cardCvv);

  bool get canGoNext => switch (step) {
    CheckoutStep.delivery => selectedAddressId != null,
    CheckoutStep.payment => !paymentMethod.isCard || isCardValid,
    CheckoutStep.summary => !isConfirming,
  };

  Address? get selectedAddress {
    for (final Address address in addresses) {
      if (address.id == selectedAddressId) {
        return address;
      }
    }
    return null;
  }

  CheckoutState copyWith({
    CheckoutStep? step,
    List<Address>? addresses,
    String? selectedAddressId,
    PaymentMethod? paymentMethod,
    String? cardNumber,
    String? cardHolder,
    String? cardExpiry,
    String? cardCvv,
    ViewStatus? status,
    bool? isConfirming,
    String? errorKey,
    bool clearError = false,
  }) => CheckoutState(
    step: step ?? this.step,
    addresses: addresses ?? this.addresses,
    selectedAddressId: selectedAddressId ?? this.selectedAddressId,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    cardNumber: cardNumber ?? this.cardNumber,
    cardHolder: cardHolder ?? this.cardHolder,
    cardExpiry: cardExpiry ?? this.cardExpiry,
    cardCvv: cardCvv ?? this.cardCvv,
    status: status ?? this.status,
    isConfirming: isConfirming ?? this.isConfirming,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  bool operator ==(Object other) =>
      other is CheckoutState &&
      other.step == step &&
      other.selectedAddressId == selectedAddressId &&
      other.paymentMethod == paymentMethod &&
      other.cardNumber == cardNumber &&
      other.cardHolder == cardHolder &&
      other.cardExpiry == cardExpiry &&
      other.cardCvv == cardCvv &&
      other.status == status &&
      other.isConfirming == isConfirming &&
      other.errorKey == errorKey &&
      other.addresses.length == addresses.length;

  @override
  int get hashCode => Object.hash(
    step,
    selectedAddressId,
    paymentMethod,
    cardNumber,
    cardHolder,
    cardExpiry,
    cardCvv,
    status,
    isConfirming,
    errorKey,
    addresses.length,
  );

  @override
  String toString() =>
      'CheckoutState: ${step.name} address:$selectedAddressId '
      'method:${paymentMethod.name}';
}
