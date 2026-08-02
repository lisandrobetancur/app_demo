part of com.demo.market.app_cross.ui.views.settings;

/// F16 · Settings: language, theme, currency and data maintenance.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  static const String route = AppCrossRoutes.settingsPath;
  static const String name = AppCrossRoutes.settingsName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState state = ref.watch(settingsViewModelProvider);
    final SettingsViewModel viewModel = ref.read(
      settingsViewModelProvider.notifier,
    );
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    return AppScaffold(
      key: AppCrossKeys.settingsView,
      title: 'app_cross.settings.title'.tr(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SettingsChoiceSection(
            sectionKey: AppCrossKeys.languageSelector,
            label: 'app_cross.settings.language_label'.tr(),
            options: <_ChoiceOption>[
              _ChoiceOption(
                key: AppCrossKeys.languageOption('es'),
                label: 'app_cross.settings.language_es'.tr(),
                selected: context.locale.languageCode == 'es',
                onSelected: () => context.setLocale(const Locale('es')),
              ),
              _ChoiceOption(
                key: AppCrossKeys.languageOption('en'),
                label: 'app_cross.settings.language_en'.tr(),
                selected: context.locale.languageCode == 'en',
                onSelected: () => context.setLocale(const Locale('en')),
              ),
            ],
          ),
          _SettingsChoiceSection(
            sectionKey: AppCrossKeys.themeSelector,
            label: 'app_cross.settings.theme_label'.tr(),
            options: <_ChoiceOption>[
              for (final ThemeMode mode in ThemeMode.values)
                _ChoiceOption(
                  key: AppCrossKeys.themeOption(mode.name),
                  label: 'app_cross.settings.theme_${mode.name}'.tr(),
                  selected: themeMode == mode,
                  onSelected: () => viewModel.setThemeMode(mode),
                ),
            ],
          ),
          _SettingsChoiceSection(
            sectionKey: AppCrossKeys.currencySelector,
            label: 'app_cross.settings.currency_label'.tr(),
            options: <_ChoiceOption>[
              for (final DisplayCurrency option in DisplayCurrency.values)
                _ChoiceOption(
                  key: AppCrossKeys.currencyOption(option.code),
                  label: option.code,
                  selected: currency == option,
                  onSelected: () => viewModel.setCurrency(option),
                ),
            ],
          ),
          const Divider(),
          if (state.errorKey != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                state.errorKey!.tr(),
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const _SettingsActionsSection(),
        ],
      ),
    );
  }
}
