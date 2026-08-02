/// Navigation layer of the market workspace.
///
/// Exposes the [AppRoute] contract every feature uses to declare its routes,
/// the [NavigationManager] facade over `go_router`, the [FeatureNavigator]
/// base class, the [BootstrapGate] and the `market://` deep-link helpers.
library;

export 'src/app_route.dart';
export 'src/bootstrap_gate.dart';
export 'src/deep_links.dart';
export 'src/feature_navigator.dart';
export 'src/navigation_manager.dart';
