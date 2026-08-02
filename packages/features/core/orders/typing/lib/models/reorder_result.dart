import 'package:equatable/equatable.dart';

/// Outcome of "buy again": how many items went back to the cart and which
/// products are no longer available (deleted, paused or out of stock).
class ReorderResult extends Equatable {
  const ReorderResult({
    required this.addedCount,
    required this.unavailableNames,
  });

  final int addedCount;
  final List<String> unavailableNames;

  bool get hasUnavailable => unavailableNames.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[addedCount, unavailableNames];
}
