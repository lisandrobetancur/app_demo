part of com.demo.market.catalog.ui.views.detail;

/// Error state of the product detail with retry.
class _DetailError extends ConsumerWidget {
  const _DetailError({required this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    key: ProductDetailKeys.state('error'),
    icon: AppIcons.error,
    title: 'catalog.detail.error_title'.tr(),
    actionLabel: 'catalog.detail.retry_button'.tr(),
    onAction: productId == null
        ? null
        : () => ref.read(detailViewModelProvider.notifier).load(productId!),
  );
}
