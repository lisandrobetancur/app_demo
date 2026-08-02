part of com.demo.market.cart.core.state.checkout;

/// Controller of the multi-step checkout.
class CheckoutViewModel extends ViewModel<CheckoutState> {
  CheckoutViewModel({CheckoutState? state})
    : super(state ?? const CheckoutState());

  @override
  void postInit() {
    service = ref.read(cartServiceProvider);
    navigatorNotifier = ref.read(cartNavigator.notifier);
    runPostBuild(loadAddresses);
  }

  late ICartService service;
  late CartNavigator navigatorNotifier;

  String? get _userId => ref.read(authSessionProvider)?.id;

  Future<void> loadAddresses() async {
    if (_userId == null) {
      return;
    }
    state = state.copyWith(status: ViewStatus.loading);
    final Object? key = mountedKey;
    try {
      final List<Address> addresses = await ref
          .read(profileServiceProvider)
          .addressesFor(_userId!);
      if (key != mountedKey) {
        return;
      }
      Address? defaultAddress;
      for (final Address address in addresses) {
        if (address.isDefault) {
          defaultAddress = address;
          break;
        }
      }
      state = state.copyWith(
        addresses: addresses,
        selectedAddressId:
            state.selectedAddressId ??
            defaultAddress?.id ??
            (addresses.isEmpty ? null : addresses.first.id),
        status: ViewStatus.data,
      );
    } on Object catch (error, stackTrace) {
      log.error('checkout.loadAddresses', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  /// Creates an address inline (step 1) and selects it.
  Future<void> createAddress({
    required String label,
    required String line1,
    required String city,
    required String stateName,
    String? notes,
  }) async {
    if (_userId == null) {
      return;
    }
    final Address created = await ref
        .read(profileServiceProvider)
        .createAddress(
          userId: _userId!,
          label: label,
          line1: line1,
          city: city,
          state: stateName,
          notes: notes,
        );
    state = state.copyWith(selectedAddressId: created.id);
    await loadAddresses();
  }

  void selectAddress(String addressId) =>
      state = state.copyWith(selectedAddressId: addressId);

  void selectPaymentMethod(PaymentMethod method) =>
      state = state.copyWith(paymentMethod: method, clearError: true);

  void setCardNumber(String value) =>
      state = state.copyWith(cardNumber: value, clearError: true);

  void setCardHolder(String value) =>
      state = state.copyWith(cardHolder: value, clearError: true);

  void setCardExpiry(String value) =>
      state = state.copyWith(cardExpiry: value, clearError: true);

  void setCardCvv(String value) =>
      state = state.copyWith(cardCvv: value, clearError: true);

  /// Forward navigation preserves every entered value; back too.
  void nextStep() {
    if (!state.canGoNext) {
      return;
    }
    if (state.step.isDelivery) {
      state = state.copyWith(step: CheckoutStep.payment);
    } else if (state.step.isPayment) {
      state = state.copyWith(step: CheckoutStep.summary);
    }
  }

  void previousStep() {
    if (state.step.isSummary) {
      state = state.copyWith(step: CheckoutStep.payment);
    } else if (state.step.isPayment) {
      state = state.copyWith(step: CheckoutStep.delivery);
    } else {
      navigatorNotifier.back();
    }
  }

  /// Confirms the purchase (single transaction in the service) and moves to
  /// the success screen.
  Future<void> confirm() async {
    if (_userId == null || state.isConfirming) {
      return;
    }
    state = state.copyWith(isConfirming: true, clearError: true);
    final Object? key = mountedKey;
    try {
      final Coupon? coupon = ref.read(cartViewModelProvider).appliedCoupon;
      final String orderId = await service.checkout(
        userId: _userId!,
        paymentMethod: state.paymentMethod,
        addressId: state.selectedAddressId,
        couponCode: coupon?.code,
      );
      ref.invalidate(cartViewModelProvider);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isConfirming: false);
      navigatorNotifier.goToCheckoutSuccess(orderId);
    } on CartException catch (error) {
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isConfirming: false,
        errorKey: error.code.messageKey,
      );
    } on Object catch (error, stackTrace) {
      log.error('checkout.confirm', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isConfirming: false,
        errorKey: 'cart.checkout.confirm_error',
      );
    }
  }
}
