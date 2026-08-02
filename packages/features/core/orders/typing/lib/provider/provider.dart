import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/i_orders_service.dart';

/// Orders contract provider; the module overrides it.
final Provider<IOrdersService> ordersServiceProvider = Provider<IOrdersService>(
  (Ref ref) => throw UnimplementedError('ordersServiceProvider'),
);
