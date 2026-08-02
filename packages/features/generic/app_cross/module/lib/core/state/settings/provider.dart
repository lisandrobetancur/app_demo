part of com.demo.market.app_cross.core.state.settings;

/// Riverpod handle for [SettingsViewModel].
final NotifierProvider<SettingsViewModel, SettingsState>
settingsViewModelProvider = NotifierProvider<SettingsViewModel, SettingsState>(
  SettingsViewModel.new,
);
