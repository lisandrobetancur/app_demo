part of com.demo.market.catalog.ui.views.form;

/// F09 · Publish a new product.
class ProductCreateView extends StatelessWidget {
  const ProductCreateView({super.key});

  static const String route = CatalogRoutes.createPath;
  static const String name = CatalogRoutes.createName;

  @override
  Widget build(BuildContext context) => const _ProductFormScaffold();
}

/// F09/F10 · Edit an existing publication (same form, preloaded).
class ProductEditView extends StatelessWidget {
  const ProductEditView({super.key});

  static const String route = CatalogRoutes.editPath;
  static const String name = CatalogRoutes.editName;

  @override
  Widget build(BuildContext context) => const _ProductFormScaffold();
}

/// Shared scaffold of both form routes: reads the optional productId path
/// parameter, drives the controller lifecycle and the discard-changes guard.
class _ProductFormScaffold extends ConsumerStatefulWidget {
  const _ProductFormScaffold();

  @override
  ConsumerState<_ProductFormScaffold> createState() =>
      _ProductFormScaffoldState();
}

class _ProductFormScaffoldState extends ConsumerState<_ProductFormScaffold> {
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
    Future<void>.microtask(
      () =>
          ref.read(formViewModelProvider.notifier).start(productId: productId),
    );
  }

  Future<void> _onPopRequested(bool didPop) async {
    if (didPop) {
      return;
    }
    final bool leave = await AppDialog.confirm(
      context,
      dialogKey: ProductFormKeys.discardChangesDialog,
      title: 'catalog.form.discard_title'.tr(),
      message: 'catalog.form.discard_message'.tr(),
      confirmLabel: 'catalog.form.discard_confirm'.tr(),
      cancelLabel: 'catalog.form.discard_cancel'.tr(),
      destructive: true,
    );
    if (leave && mounted) {
      ref.read(formViewModelProvider.notifier).navigatorNotifier.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final FormState state = ref.watch(formViewModelProvider);
    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (bool didPop, Object? result) =>
          _onPopRequested(didPop),
      child: AppScaffold(
        key: ProductFormKeys.view,
        title: state.isEditing
            ? 'catalog.form.edit_title'.tr()
            : 'catalog.form.create_title'.tr(),
        scrollable: false,
        padding: EdgeInsets.zero,
        body: switch (state.status) {
          ViewStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ViewStatus.data => const _FormBody(),
          ViewStatus.empty => EmptyState(
            icon: AppIcons.emptyBox,
            title: 'catalog.form.not_found_title'.tr(),
          ),
          ViewStatus.error => EmptyState(
            icon: AppIcons.error,
            title: 'catalog.form.error_title'.tr(),
            actionLabel: 'catalog.form.retry_button'.tr(),
            onAction: () => ref
                .read(formViewModelProvider.notifier)
                .start(productId: state.productId),
          ),
        },
      ),
    );
  }
}
