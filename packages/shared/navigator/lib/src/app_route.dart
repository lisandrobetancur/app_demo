import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route declaration contract.
///
/// Every feature exposes a `List<AppRoute>` from its `ui/router.dart`; the
/// shell maps them to `go_router` routes without knowing any feature detail.
class AppRoute {
  const AppRoute(this.path, {required this.name, required this.widget});

  final String path;
  final String name;
  final Widget widget;

  /// Maps this declaration to a `go_router` route.
  GoRoute toGoRoute() => GoRoute(
    path: path,
    name: name,
    builder: (BuildContext context, GoRouterState state) => widget,
  );
}
