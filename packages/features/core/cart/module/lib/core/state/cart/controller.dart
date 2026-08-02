part of com.demo.market.cart.core.state.cart;

/// Controller of the cart.
class CartViewModel extends ViewModel<CartState> {
  CartViewModel({CartState? state}) : super(state ?? const CartState());

  @override
  void postInit() {
    service = ref.read(cartServiceProvider);
    navigatorNotifier = ref.read(cartNavigator.notifier);
    runPostBuild(load);
  }

  late ICartService service;
  late CartNavigator navigatorNotifier;

  String? get _userId => ref.read(authSessionProvider)?.id;

  Future<void> load() async {
    if (_userId == null) {
      state = state.copyWith(status: ViewStatus.empty);
      return;
    }
    state = state.copyWith(status: ViewStatus.loading);
    final Object? key = mountedKey;
    try {
      final List<CartLine> lines = await service.linesFor(_userId!);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        lines: lines,
        status: lines.isEmpty ? ViewStatus.empty : ViewStatus.data,
      );
      await _revalidateCoupon();
    } on Object catch (error, stackTrace) {
      log.error('cart.load', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  Future<void> setQuantity(CartLine line, int quantity) async {
    if (quantity < 1 || quantity > line.stock) {
      return;
    }
    await service.updateQuantity(cartItemId: line.id, quantity: quantity);
    await _reloadQuietly();
  }

  /// Removes a line, keeping it around for the undo snackbar.
  Future<void> removeLine(CartLine line) async {
    await service.removeLine(line.id);
    state = state.copyWith(removedLine: line);
    await _reloadQuietly();
  }

  /// Restores the last removed line.
  Future<void> undoRemove() async {
    final CartLine? removed = state.removedLine;
    if (removed == null || _userId == null) {
      return;
    }
    state = state.copyWith(clearRemovedLine: true);
    await service.addToCart(
      userId: _userId!,
      productId: removed.productId,
      quantity: removed.quantity,
    );
    await _reloadQuietly();
  }

  Future<void> clearCart() async {
    if (_userId == null) {
      return;
    }
    await service.clear(_userId!);
    state = state.copyWith(clearCoupon: true, clearCouponError: true);
    await load();
  }

  void setCouponInput(String value) =>
      state = state.copyWith(couponInput: value, clearCouponError: true);

  Future<void> applyCoupon() async {
    final String code = state.couponInput.trim();
    if (code.isEmpty) {
      return;
    }
    state = state.copyWith(isApplyingCoupon: true, clearCouponError: true);
    final Object? key = mountedKey;
    try {
      final Coupon coupon = await service.validateCoupon(
        code: code,
        subtotal: state.totals.subtotal,
      );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(appliedCoupon: coupon, isApplyingCoupon: false);
    } on CouponException catch (error) {
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isApplyingCoupon: false,
        couponErrorKey: error.code.messageKey,
        clearCoupon: true,
      );
    } on Object catch (error, stackTrace) {
      log.error('cart.applyCoupon', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isApplyingCoupon: false);
    }
  }

  void removeCoupon() =>
      state = state.copyWith(clearCoupon: true, clearCouponError: true);

  void consumeRemovedLine() => state = state.copyWith(clearRemovedLine: true);

  void goToCheckout() {
    if (state.canCheckout) {
      navigatorNotifier.goToCheckout();
    }
  }

  void goToCatalog() => navigatorNotifier.goToCatalog();

  /// Reload without flashing the shimmer (used after small mutations).
  Future<void> _reloadQuietly() async {
    if (_userId == null) {
      return;
    }
    final Object? key = mountedKey;
    final List<CartLine> lines = await service.linesFor(_userId!);
    if (key != mountedKey) {
      return;
    }
    state = state.copyWith(
      lines: lines,
      status: lines.isEmpty ? ViewStatus.empty : ViewStatus.data,
    );
    await _revalidateCoupon();
  }

  /// A coupon may stop meeting its minimum after quantity changes.
  Future<void> _revalidateCoupon() async {
    final Coupon? coupon = state.appliedCoupon;
    if (coupon == null) {
      return;
    }
    try {
      await service.validateCoupon(
        code: coupon.code,
        subtotal: state.totals.subtotal,
      );
    } on CouponException catch (error) {
      state = state.copyWith(
        clearCoupon: true,
        couponErrorKey: error.code.messageKey,
      );
    }
  }
}
