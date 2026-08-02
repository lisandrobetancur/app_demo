part of com.demo.market.catalog.ui.views.detail;

/// Not-found state: deep links to unknown products land here, never on a
/// blank screen.
class _DetailEmpty extends StatelessWidget {
  const _DetailEmpty();

  @override
  Widget build(BuildContext context) => EmptyState(
    key: ProductDetailKeys.state('empty'),
    icon: AppIcons.emptyBox,
    title: 'catalog.detail.not_found_title'.tr(),
    message: 'catalog.detail.not_found_message'.tr(),
  );
}
