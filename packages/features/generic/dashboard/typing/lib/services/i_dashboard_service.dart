import '../models/dashboard_summary.dart';

/// Dashboard contract: the aggregated metrics of the home screen.
abstract interface class IDashboardService {
  /// Metrics of [userId] at [reference] time (month bucket for orders).
  Future<DashboardSummary> summaryFor({
    required String userId,
    required DateTime reference,
  });
}
