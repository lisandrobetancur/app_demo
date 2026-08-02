part of com.demo.market.catalog.ui.views.detail;

/// F08 · Product detail.
class DetailView extends ConsumerStatefulWidget {
  const DetailView({super.key});

  static const String route = CatalogRoutes.detailPath;
  static const String name = CatalogRoutes.detailName;

  @override
  ConsumerState<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<DetailView> {
  String? _loadedProductId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? productId = NavigationManager.pathParamOf(
      context,
      CatalogRoutes.productIdParam,
    );
    if (productId != null && productId != _loadedProductId) {
      _loadedProductId = productId;
      Future<void>.microtask(
        () => ref.read(detailViewModelProvider.notifier).load(productId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DetailState state = ref.watch(detailViewModelProvider);
    ref.listen<DetailState>(detailViewModelProvider, (
      DetailState? previous,
      DetailState next,
    ) {
      final String? event = next.lastEventKey;
      if (event != null && previous?.lastEventKey != event) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(event.tr())));
        ref.read(detailViewModelProvider.notifier).consumeEvent();
      }
    });
    return AppScaffold(
      key: ProductDetailKeys.view,
      title: state.product?.name ?? 'catalog.detail.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      body: switch (state.status) {
        ViewStatus.loading => const _DetailShimmer(),
        ViewStatus.data => const _DetailData(),
        ViewStatus.empty => const _DetailEmpty(),
        ViewStatus.error => _DetailError(productId: _loadedProductId),
      },
    );
  }
}
