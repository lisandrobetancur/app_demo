part of com.demo.market.cart.ui.views.checkout;

/// Step 2: payment method with masked card validation (never persisted).
class _CheckoutStepPayment extends ConsumerWidget {
  const _CheckoutStepPayment();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckoutState state = ref.watch(checkoutViewModelProvider);
    final CheckoutViewModel viewModel = ref.read(
      checkoutViewModelProvider.notifier,
    );
    return ListView(
      padding: AppSpacing.pagePadding,
      children: <Widget>[
        Text(
          'cart.checkout.choose_payment'.tr(),
          style: AppTypography.cardTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final PaymentMethod method in PaymentMethod.values)
              ChoiceChip(
                key: CheckoutKeys.paymentMethod(method.dbValue),
                avatar: Icon(switch (method) {
                  PaymentMethod.card => AppIcons.payment,
                  PaymentMethod.cash => AppIcons.cash,
                  PaymentMethod.transfer => AppIcons.transfer,
                }, size: 18),
                label: Text(method.labelKey.tr()),
                selected: state.paymentMethod == method,
                onSelected: (bool _) => viewModel.selectPaymentMethod(method),
              ),
          ],
        ),
        if (state.paymentMethod.isCard) ...<Widget>[
          AppSpacing.sectionGap,
          AppTextField(
            key: CheckoutKeys.cardNumberInput,
            label: 'cart.checkout.card_number_label'.tr(),
            keyboardType: TextInputType.number,
            maxLength: 16,
            errorText: state.cardNumberErrorKey?.tr(),
            onChanged: viewModel.setCardNumber,
          ),
          AppSpacing.formGap,
          AppTextField(
            key: CheckoutKeys.cardHolderInput,
            label: 'cart.checkout.card_holder_label'.tr(),
            onChanged: viewModel.setCardHolder,
          ),
          AppSpacing.formGap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: AppTextField(
                  key: CheckoutKeys.cardExpiryInput,
                  label: 'cart.checkout.card_expiry_label'.tr(),
                  hint: 'MM/YY',
                  maxLength: 5,
                  errorText: state.cardExpiryErrorKey?.tr(),
                  onChanged: viewModel.setCardExpiry,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  key: CheckoutKeys.cardCvvInput,
                  label: 'cart.checkout.card_cvv_label'.tr(),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  errorText: state.cardCvvErrorKey?.tr(),
                  onChanged: viewModel.setCardCvv,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'cart.checkout.card_disclaimer'.tr(),
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
