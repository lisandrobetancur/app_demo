import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base class for every state controller in the workspace.
///
/// A [ViewModel] wraps a Riverpod [Notifier] with:
///  * a [defaultState] provided at construction time,
///  * a [postInit] hook called once right after [build],
///  * [runPostBuild], to launch the first data load safely,
///  * a [mountedKey] token to detect disposal across `await` gaps.
abstract class ViewModel<T> extends Notifier<T> {
  ViewModel(this.defaultState);

  /// Opaque token renewed on every [build] and nulled on dispose.
  /// Capture it before an `await` to detect mid-flight disposal.
  Object? mountedKey;

  T defaultState;

  @override
  T build() {
    mountedKey = Object();
    ref
      ..onDispose(dispose)
      ..onDispose(() => mountedKey = null);
    postInit();
    return defaultState;
  }

  /// Called once, synchronously, right after [build] wires the notifier.
  ///
  /// Resolve dependencies here (`service`, `navigatorNotifier`, …) so they
  /// are ready before anyone can call a method on this controller. Kick off
  /// asynchronous work with [runPostBuild], never inline: Riverpod forbids
  /// writing `state` while [build] is still running.
  void postInit() {}

  /// Runs [action] on the microtask right after [build] returns.
  ///
  /// Skipped when the controller was disposed in the meantime.
  void runPostBuild(Future<void> Function() action) {
    final Object? key = mountedKey;
    scheduleMicrotask(() {
      if (key != mountedKey) {
        return;
      }
      unawaited(action());
    });
  }

  void dispose() {}
}
