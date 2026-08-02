part of com.demo.market.orders.ui.views.detail;

/// F13 · Order detail with timeline, cancellation and re-order.
class OrderDetailView extends ConsumerStatefulWidget {
  const OrderDetailView({super.key});

  static const String route = OrdersRoutes.detailPath;
  static const String name = OrdersRoutes.detailName;

  @override
  ConsumerState<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends ConsumerState<OrderDetailView> {
  String? _loadedOrderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? orderId = NavigationManager.pathParamOf(
      context,
      OrdersRoutes.orderIdParam,
    );
    if (orderId != null && orderId != _loadedOrderId) {
      _loadedOrderId = orderId;
      Future<void>.microtask(
        () => ref.read(orderDetailViewModelProvider.notifier).load(orderId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrderDetailState state = ref.watch(orderDetailViewModelProvider);
    ref.listen<OrderDetailState>(orderDetailViewModelProvider, (
      OrderDetailState? previous,
      OrderDetailState next,
    ) {
      final String? event = next.lastEventKey;
      if (event != null && previous?.lastEventKey != event) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event.tr(
                namedArgs: <String, String>{
                  'count': next.lastEventArg,
                  'names': next.lastEventArg,
                },
              ),
            ),
          ),
        );
        ref.read(orderDetailViewModelProvider.notifier).consumeEvent();
      }
    });
    return AppScaffold(
      key: OrderDetailKeys.view,
      title: 'orders.detail.title'.tr(),
      scrollable: false,
      padding: EdgeInsets.zero,
      body: switch (state.status) {
        ViewStatus.loading => const _OrderDetailShimmer(),
        ViewStatus.data => const _OrderDetailData(),
        ViewStatus.empty => const _OrderDetailEmpty(),
        ViewStatus.error => _OrderDetailError(orderId: _loadedOrderId),
      },
    );
  }
}
