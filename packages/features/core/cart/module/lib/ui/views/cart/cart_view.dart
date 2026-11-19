part of com.demo.market.cart.ui.views.cart;

/// F11 · Cart.
class CartView extends ConsumerWidget {
  const CartView({super.key});

  static const String route = CartRoutes.cartPath;
  static const String name = CartRoutes.cartName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CartState state = ref.watch(cartViewModelProvider);
    final CartViewModel viewModel = ref.read(cartViewModelProvider.notifier);
    ref.listen<CartState>(cartViewModelProvider, (
      CartState? previous,
      CartState next,
    ) {
      if (next.removedLine != null &&
          previous?.removedLine != next.removedLine) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Semantics(
                identifier: CartSemanticIds.itemRemovedText,
                child: Text('cart.home.item_removed'.tr()),
              ),
              duration: AppDurations.snackBar,
              action: SnackBarAction(
                key: CartKeys.undoRemoveButton,
                label: 'cart.home.undo_button'.tr(),
                onPressed: viewModel.undoRemove,
              ),
            ),
          );
      }
    });
    return AppScaffold(
      key: CartKeys.view,
      semanticsId: CartSemanticIds.view,
      titleSemanticsId: CartSemanticIds.titleText,
      title: 'cart.home.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: <Widget>[
        if (state.status.isData)
          IconButton(
            key: CartKeys.clearCartButton,
            icon: Semantics(
              identifier: CartSemanticIds.clearButton,
              child: const Icon(AppIcons.delete),
            ),
            tooltip: 'cart.home.clear_cart_button'.tr(),
            onPressed: () => _confirmClear(context, ref),
          ),
      ],
      body: switch (state.status) {
        ViewStatus.loading => const _CartShimmer(),
        ViewStatus.data => const _CartData(),
        ViewStatus.empty => const _CartEmpty(),
        ViewStatus.error => const _CartError(),
      },
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      dialogKey: CartKeys.clearCartDialog,
      dialogSemanticsId: CartSemanticIds.clearDialog,
      confirmSemanticsId: CartSemanticIds.clearConfirmButton,
      cancelSemanticsId: CartSemanticIds.clearCancelButton,
      title: 'cart.home.clear_cart_title'.tr(),
      message: 'cart.home.clear_cart_message'.tr(),
      confirmLabel: 'cart.home.confirm'.tr(),
      cancelLabel: 'cart.home.cancel'.tr(),
      destructive: true,
    );
    if (confirmed) {
      await ref.read(cartViewModelProvider.notifier).clearCart();
    }
  }
}
