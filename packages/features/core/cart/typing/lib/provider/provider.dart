import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/i_cart_service.dart';

/// Cart contract provider; the module overrides it.
final Provider<ICartService> cartServiceProvider = Provider<ICartService>(
  (Ref ref) => throw UnimplementedError('cartServiceProvider'),
);

/// Shared cart badge: number of lines. Owned by the cart service.
final StateProvider<int> cartItemCountProvider = StateProvider<int>(
  (Ref ref) => 0,
);

/// Shared cart badge: current subtotal (before coupon/tax). Owned by the
/// cart service; the dashboard summary card watches it.
final StateProvider<double> cartSubtotalProvider = StateProvider<double>(
  (Ref ref) => 0,
);
