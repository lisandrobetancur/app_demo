part of com.demo.market.cart.ui.views.cart;

/// Coupon input with differentiated inline errors.
class _CartCoupon extends ConsumerWidget {
  const _CartCoupon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CartState state = ref.watch(cartViewModelProvider);
    final CartViewModel viewModel = ref.read(cartViewModelProvider.notifier);
    final Coupon? coupon = state.appliedCoupon;
    if (coupon != null) {
      return Row(
        children: <Widget>[
          Icon(
            AppIcons.coupon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'cart.home.coupon_applied'.tr(
                namedArgs: <String, String>{
                  'code': coupon.code,
                  'pct': coupon.discountPct.toStringAsFixed(0),
                },
              ),
              style: AppTypography.body,
            ),
          ),
          TextButton(
            key: CartKeys.removeCouponButton,
            onPressed: viewModel.removeCoupon,
            child: Text('cart.home.remove_coupon_button'.tr()),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: AppTextField(
                key: CartKeys.couponInput,
                label: 'cart.home.coupon_label'.tr(),
                prefixIcon: AppIcons.coupon,
                onChanged: viewModel.setCouponInput,
                onSubmitted: (String _) => viewModel.applyCoupon(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              key: CartKeys.applyCouponButton,
              label: 'cart.home.apply_coupon_button'.tr(),
              variant: AppButtonVariant.secondary,
              isLoading: state.isApplyingCoupon,
              onPressed: state.couponInput.trim().isEmpty
                  ? null
                  : viewModel.applyCoupon,
            ),
          ],
        ),
        if (state.couponErrorKey != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              state.couponErrorKey!.tr(),
              key: CartKeys.couponErrorText,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
