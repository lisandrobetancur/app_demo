import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation_manager.dart';

/// Base class for per-feature navigators.
///
/// A feature's `core/navigator.dart` extends this class and exposes intent
/// methods (`goToDetail(productId)`); cross-feature navigation happens only
/// through route names/paths (plain strings), never by importing another
/// feature's `module/`.
abstract class FeatureNavigator extends Notifier<void> {
  @override
  void build() {}

  /// Shared navigation facade.
  NavigationManager get navigation =>
      ref.read(navigationManagerProvider.notifier);
}
