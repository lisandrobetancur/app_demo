import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/i_dashboard_service.dart';

/// Dashboard contract provider; the module overrides it.
final Provider<IDashboardService> dashboardServiceProvider =
    Provider<IDashboardService>(
      (Ref ref) => throw UnimplementedError('dashboardServiceProvider'),
    );
