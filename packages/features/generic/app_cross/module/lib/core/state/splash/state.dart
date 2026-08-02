part of com.demo.market.app_cross.core.state.splash;

/// Immutable state of the splash/bootstrap screen.
class SplashState {
  const SplashState({this.isInitializing = true, this.hasError = false});

  final bool isInitializing;

  /// Set when bootstrap failed; the view shows a retry action instead of
  /// hanging forever.
  final bool hasError;

  SplashState copyWith({bool? isInitializing, bool? hasError}) => SplashState(
    isInitializing: isInitializing ?? this.isInitializing,
    hasError: hasError ?? this.hasError,
  );

  @override
  bool operator ==(Object other) =>
      other is SplashState &&
      other.isInitializing == isInitializing &&
      other.hasError == hasError;

  @override
  int get hashCode => Object.hash(isInitializing, hasError);

  @override
  String toString() =>
      'SplashState: initializing:$isInitializing error:$hasError';
}
