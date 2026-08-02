import 'package:equatable/equatable.dart';

/// Aggregated metrics shown in the dashboard summary cards.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.activePublications,
    required this.cartItemCount,
    required this.cartSubtotal,
    required this.ordersThisMonth,
  });

  const DashboardSummary.zero()
    : activePublications = 0,
      cartItemCount = 0,
      cartSubtotal = 0,
      ordersThisMonth = 0;

  final int activePublications;
  final int cartItemCount;
  final double cartSubtotal;
  final int ordersThisMonth;

  @override
  List<Object?> get props => <Object?>[
    activePublications,
    cartItemCount,
    cartSubtotal,
    ordersThisMonth,
  ];
}
