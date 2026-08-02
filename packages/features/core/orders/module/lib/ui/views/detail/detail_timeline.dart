part of com.demo.market.orders.ui.views.detail;

/// Vertical status timeline of an order.
///
/// Cancelled orders show a single terminal row; otherwise the four regular
/// stages render as reached / pending.
class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.status});

  final OrderStatus status;

  static const List<OrderStatus> _stages = <OrderStatus>[
    OrderStatus.created,
    OrderStatus.paid,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (status.isCancelled) {
      return Row(
        key: OrderDetailKeys.timeline,
        children: <Widget>[
          Icon(AppIcons.close, color: scheme.error),
          const SizedBox(width: AppSpacing.sm),
          Text(
            status.labelKey.tr(),
            style: AppTypography.body.copyWith(color: scheme.error),
          ),
        ],
      );
    }
    final int reachedIndex = _stages.indexOf(status);
    return Column(
      key: OrderDetailKeys.timeline,
      children: <Widget>[
        for (int index = 0; index < _stages.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                Icon(
                  index <= reachedIndex
                      ? AppIcons.checkFilled
                      : AppIcons.timeline,
                  size: 20,
                  color: index <= reachedIndex
                      ? AppColors.success
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _stages[index].labelKey.tr(),
                  style: AppTypography.body.copyWith(
                    fontWeight: index == reachedIndex
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
