part of com.demo.market.catalog.ui.views.my_products;

/// F10 · My publications.
class MyProductsView extends ConsumerWidget {
  const MyProductsView({super.key});

  static const String route = CatalogRoutes.myProductsPath;
  static const String name = CatalogRoutes.myProductsName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyProductsState state = ref.watch(myProductsViewModelProvider);
    return AppScaffold(
      key: MyProductsKeys.view,
      title: 'catalog.my_products.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton(
        onPressed: ref.read(myProductsViewModelProvider.notifier).goToCreate,
        tooltip: 'catalog.my_products.publish_button'.tr(),
        child: const Icon(AppIcons.add),
      ),
      body: switch (state.status) {
        ViewStatus.loading => const _MyProductsShimmer(),
        ViewStatus.data => const _MyProductsData(),
        ViewStatus.empty => const _MyProductsEmpty(),
        ViewStatus.error => const _MyProductsError(),
      },
    );
  }
}
