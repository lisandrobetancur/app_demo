part of com.demo.market.cart.ui.views.checkout_success;

/// F12 · Post-purchase success screen with the order number.
class CheckoutSuccessView extends ConsumerWidget {
  const CheckoutSuccessView({super.key});

  static const String route = CartRoutes.checkoutSuccessPath;
  static const String name = CartRoutes.checkoutSuccessName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String orderId =
        NavigationManager.pathParamOf(context, CartRoutes.orderIdParam) ?? '';
    final CartNavigator navigatorNotifier = ref.read(cartNavigator.notifier);
    final String orderNumber = orderId.length <= 8
        ? orderId.toUpperCase()
        : orderId.substring(0, 8).toUpperCase();
    return AppScaffold(
      key: CheckoutKeys.successView,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Icon(AppIcons.checkFilled, size: 96, color: AppColors.success),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'cart.success.headline'.tr(),
            style: AppTypography.displayTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'cart.success.order_number'.tr(
              namedArgs: <String, String>{'number': orderNumber},
            ),
            key: CheckoutKeys.orderNumberText,
            style: AppTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'cart.success.body'.tr(),
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          AppSpacing.sectionGap,
          AppButton(
            key: CheckoutKeys.goToOrderButton,
            label: 'cart.success.go_to_order_button'.tr(),
            onPressed: () => navigatorNotifier.goToOrderDetail(orderId),
            expand: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: CheckoutKeys.goToHomeButton,
            label: 'cart.success.go_to_home_button'.tr(),
            variant: AppButtonVariant.secondary,
            onPressed: navigatorNotifier.goToDashboard,
            expand: true,
          ),
        ],
      ),
    );
  }
}
