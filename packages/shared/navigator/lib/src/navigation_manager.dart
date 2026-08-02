import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The app router, built by the shell (it owns routes, redirect and shell
/// navigation) and injected here so features never depend on the shell.
final Provider<GoRouter> goRouterProvider = Provider<GoRouter>(
  (Ref ref) => throw UnimplementedError('goRouterProvider'),
);

/// Riverpod handle for [NavigationManager].
final NotifierProvider<NavigationManager, void> navigationManagerProvider =
    NotifierProvider<NavigationManager, void>(NavigationManager.new);

/// Facade over `go_router`.
///
/// Features navigate exclusively through this manager (or their
/// [`FeatureNavigator`]); no view ever touches `go_router` directly.
class NavigationManager extends Notifier<void> {
  @override
  void build() {}

  GoRouter get _router => ref.read(goRouterProvider);

  /// Replaces the current stack with the named route.
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
  }) => _router.goNamed(name, pathParameters: pathParameters);

  /// Pushes the named route on top of the current stack.
  void pushNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
  }) => unawaited(
    _router.pushNamed<Object?>(name, pathParameters: pathParameters),
  );

  /// Navigates to a raw location (used by deep links from notifications).
  void go(String location) => _router.go(location);

  /// Pops the current route when possible.
  void pop() {
    if (_router.canPop()) {
      _router.pop();
    }
  }

  /// Reads a path parameter of the current route from a view.
  static String? pathParamOf(BuildContext context, String key) =>
      GoRouterState.of(context).pathParameters[key];
}
