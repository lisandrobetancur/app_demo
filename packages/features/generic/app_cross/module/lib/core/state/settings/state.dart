part of com.demo.market.app_cross.core.state.settings;

/// Immutable state of the settings screen.
///
/// Theme mode and display currency live in shared providers
/// (`themeModeProvider`, `displayCurrencyProvider`); this state only tracks
/// the busy flag of destructive maintenance actions.
class SettingsState {
  const SettingsState({this.isBusy = false, this.errorKey});

  final bool isBusy;
  final String? errorKey;

  SettingsState copyWith({
    bool? isBusy,
    String? errorKey,
    bool clearError = false,
  }) => SettingsState(
    isBusy: isBusy ?? this.isBusy,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  bool operator ==(Object other) =>
      other is SettingsState &&
      other.isBusy == isBusy &&
      other.errorKey == errorKey;

  @override
  int get hashCode => Object.hash(isBusy, errorKey);

  @override
  String toString() => 'SettingsState: busy:$isBusy error:$errorKey';
}
