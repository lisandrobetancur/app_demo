part of com.demo.market.catalog.ui.views.review_form;

/// F15 · Review form (create or edit own review).
class ReviewFormView extends ConsumerStatefulWidget {
  const ReviewFormView({super.key});

  static const String route = CatalogRoutes.reviewFormPath;
  static const String name = CatalogRoutes.reviewFormName;

  @override
  ConsumerState<ReviewFormView> createState() => _ReviewFormViewState();
}

class _ReviewFormViewState extends ConsumerState<ReviewFormView> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final String? productId = NavigationManager.pathParamOf(
      context,
      CatalogRoutes.productIdParam,
    );
    if (productId != null) {
      Future<void>.microtask(
        () => ref.read(reviewFormViewModelProvider.notifier).start(productId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ReviewFormState state = ref.watch(reviewFormViewModelProvider);
    return AppScaffold(
      key: ReviewFormKeys.view,
      title: 'catalog.review_form.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      body: switch (state.status) {
        ViewStatus.loading => const Center(child: CircularProgressIndicator()),
        ViewStatus.data => const _ReviewFormBody(),
        ViewStatus.empty => EmptyState(
          icon: AppIcons.starOutline,
          title: 'catalog.review_form.cannot_title'.tr(),
          message: 'catalog.review_form.cannot_message'.tr(),
        ),
        ViewStatus.error => EmptyState(
          icon: AppIcons.error,
          title: 'catalog.review_form.error_title'.tr(),
          actionLabel: 'catalog.review_form.retry_button'.tr(),
          onAction: () => ref
              .read(reviewFormViewModelProvider.notifier)
              .start(state.productId),
        ),
      },
    );
  }
}
