part of com.demo.market.cart.ui.views.checkout;

/// F12 · Multi-step checkout (delivery → payment → summary).
class CheckoutView extends ConsumerWidget {
  const CheckoutView({super.key});

  static const String route = CartRoutes.checkoutPath;
  static const String name = CartRoutes.checkoutName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckoutState state = ref.watch(checkoutViewModelProvider);
    final CheckoutViewModel viewModel = ref.read(
      checkoutViewModelProvider.notifier,
    );
    return AppScaffold(
      key: CheckoutKeys.view,
      title: 'cart.checkout.title'.tr(),
      leading: BackButton(onPressed: viewModel.previousStep),
      scrollable: false,
      padding: EdgeInsets.zero,
      body: switch (state.status) {
        ViewStatus.loading => const Center(child: CircularProgressIndicator()),
        ViewStatus.error => EmptyState(
          icon: AppIcons.error,
          title: 'cart.checkout.error_title'.tr(),
          actionLabel: 'cart.checkout.retry_button'.tr(),
          onAction: viewModel.loadAddresses,
        ),
        ViewStatus.data || ViewStatus.empty => Column(
          children: <Widget>[
            Padding(
              padding: AppSpacing.pagePadding,
              child: StepperHeader(
                key: CheckoutKeys.stepIndicator,
                steps: <String>[
                  'cart.checkout.step_delivery'.tr(),
                  'cart.checkout.step_payment'.tr(),
                  'cart.checkout.step_summary'.tr(),
                ],
                currentIndex: state.step.index,
              ),
            ),
            Expanded(
              child: switch (state.step) {
                CheckoutStep.delivery => const _CheckoutStepDelivery(),
                CheckoutStep.payment => const _CheckoutStepPayment(),
                CheckoutStep.summary => const _CheckoutStepSummary(),
              },
            ),
            const _CheckoutNavigationBar(),
          ],
        ),
      },
    );
  }
}

/// Bottom bar with back/next/confirm actions.
class _CheckoutNavigationBar extends ConsumerWidget {
  const _CheckoutNavigationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckoutState state = ref.watch(checkoutViewModelProvider);
    final CheckoutViewModel viewModel = ref.read(
      checkoutViewModelProvider.notifier,
    );
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              key: CheckoutKeys.backButton,
              label: 'cart.checkout.back_button'.tr(),
              variant: AppButtonVariant.secondary,
              onPressed: viewModel.previousStep,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: state.step.isSummary
                ? AppButton(
                    key: CheckoutKeys.confirmButton,
                    label: 'cart.checkout.confirm_button'.tr(),
                    isLoading: state.isConfirming,
                    onPressed: state.canGoNext ? viewModel.confirm : null,
                  )
                : AppButton(
                    key: CheckoutKeys.nextButton,
                    label: 'cart.checkout.next_button'.tr(),
                    onPressed: state.canGoNext ? viewModel.nextStep : null,
                  ),
          ),
        ],
      ),
    );
  }
}
