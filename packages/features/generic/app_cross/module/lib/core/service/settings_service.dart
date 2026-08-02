part of com.demo.market.app_cross.core;

/// Module-internal settings service.
///
/// Persists theme mode, display currency and the onboarding flag in
/// `shared_preferences`, and orchestrates the demo-data reset and wipe.
/// Locale persistence is handled by easy_localization itself.
class SettingsService {
  SettingsService({
    required AppDatabase database,
    required StateController<ThemeMode> themeMode,
    required StateController<DisplayCurrency> currency,
  }) : _database = database,
       _themeMode = themeMode,
       _currency = currency;

  final AppDatabase _database;
  final StateController<ThemeMode> _themeMode;
  final StateController<DisplayCurrency> _currency;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Loads persisted settings into the shared providers (called at splash).
  Future<void> restore() async {
    final SharedPreferences prefs = await _prefs;
    final String? theme = prefs.getString(AppCrossLimits.themeModePrefKey);
    if (theme != null) {
      _themeMode.state = ThemeMode.values.firstWhere(
        (ThemeMode mode) => mode.name == theme,
        orElse: () => ThemeMode.system,
      );
    }
    final String? currency = prefs.getString(AppCrossLimits.currencyPrefKey);
    if (currency != null) {
      _currency.state = DisplayCurrency.parse(currency);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.state = mode;
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(AppCrossLimits.themeModePrefKey, mode.name);
  }

  Future<void> setCurrency(DisplayCurrency currency) async {
    _currency.state = currency;
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(AppCrossLimits.currencyPrefKey, currency.code);
  }

  Future<bool> hasSeenOnboarding() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getBool(AppCrossLimits.onboardingSeenPrefKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setBool(AppCrossLimits.onboardingSeenPrefKey, true);
  }

  /// Re-enables the onboarding for the next app start ("see it again").
  Future<void> resetOnboardingFlag() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(AppCrossLimits.onboardingSeenPrefKey);
  }

  /// Deletes everything and re-creates the deterministic seed.
  Future<void> resetToSeed() => _database.resetToSeed();

  /// Deletes everything, leaving the database empty.
  Future<void> wipe() => _database.wipe();
}
