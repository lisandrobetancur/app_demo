import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds what the router must remember while the app boots.
///
/// A cold start with a deep link (`market://catalog/detail/x`, or the same
/// URL typed on the web) reaches the router *before* the database and the
/// session exist, so the session redirect would bounce it to login and the
/// requested resource would be lost. The router parks the location here,
/// sends the user through the splash, and the splash (or the login that
/// follows it) resumes the pending location once bootstrap is done.
///
/// Kept as a plain mutable object behind a provider on purpose: the router
/// writes to it from inside `redirect`, where mutating provider state is
/// not allowed.
class BootstrapGate {
  BootstrapGate();

  String? _pendingLocation;

  /// True once the splash finished initializing database, settings and
  /// session; until then every route resolves to the splash.
  bool isReady = false;

  /// Location requested before the app was ready.
  bool get hasPending => _pendingLocation != null;

  /// Parks [location] until bootstrap completes.
  void remember(String location) => _pendingLocation = location;

  /// Returns the parked location (once) and clears it.
  String? consumePending() {
    final String? pending = _pendingLocation;
    _pendingLocation = null;
    return pending;
  }

  /// Marks bootstrap as finished.
  void markReady() => isReady = true;
}

/// Shared handle of the [BootstrapGate].
final Provider<BootstrapGate> bootstrapGateProvider = Provider<BootstrapGate>(
  (Ref ref) => BootstrapGate(),
);
