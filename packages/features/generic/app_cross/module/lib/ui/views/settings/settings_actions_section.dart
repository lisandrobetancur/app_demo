part of com.demo.market.app_cross.ui.views.settings;

/// Maintenance and navigation actions of the settings screen.
class _SettingsActionsSection extends ConsumerWidget {
  const _SettingsActionsSection();

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      dialogKey: AppCrossKeys.resetDemoDataDialog,
      title: 'app_cross.settings.reset_demo_data'.tr(),
      message: 'app_cross.settings.reset_demo_data_message'.tr(),
      confirmLabel: 'app_cross.settings.confirm'.tr(),
      cancelLabel: 'app_cross.settings.cancel'.tr(),
      destructive: true,
    );
    if (confirmed) {
      await ref.read(settingsViewModelProvider.notifier).resetDemoData();
    }
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      dialogKey: AppCrossKeys.wipeDataDialog,
      title: 'app_cross.settings.wipe_data'.tr(),
      message: 'app_cross.settings.wipe_data_message'.tr(),
      confirmLabel: 'app_cross.settings.confirm'.tr(),
      cancelLabel: 'app_cross.settings.cancel'.tr(),
      destructive: true,
    );
    if (confirmed) {
      await ref.read(settingsViewModelProvider.notifier).wipeData();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState state = ref.watch(settingsViewModelProvider);
    final SettingsViewModel viewModel = ref.read(
      settingsViewModelProvider.notifier,
    );
    return Column(
      children: <Widget>[
        ListTile(
          key: AppCrossKeys.seeOnboardingAgainButton,
          leading: const Icon(AppIcons.play),
          title: Text('app_cross.settings.see_onboarding_again'.tr()),
          trailing: const Icon(AppIcons.chevronRight),
          contentPadding: EdgeInsets.zero,
          onTap: viewModel.seeOnboardingAgain,
        ),
        ListTile(
          key: AppCrossKeys.resetDemoDataButton,
          leading: const Icon(AppIcons.refresh),
          title: Text('app_cross.settings.reset_demo_data'.tr()),
          contentPadding: EdgeInsets.zero,
          enabled: !state.isBusy,
          onTap: () => _confirmReset(context, ref),
        ),
        ListTile(
          key: AppCrossKeys.wipeDataButton,
          leading: Icon(
            AppIcons.delete,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'app_cross.settings.wipe_data'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          contentPadding: EdgeInsets.zero,
          enabled: !state.isBusy,
          onTap: () => _confirmWipe(context, ref),
        ),
        ListTile(
          key: AppCrossKeys.goToAboutButton,
          leading: const Icon(AppIcons.about),
          title: Text('app_cross.settings.about'.tr()),
          trailing: const Icon(AppIcons.chevronRight),
          contentPadding: EdgeInsets.zero,
          onTap: ref.read(appCrossNavigator.notifier).goToAbout,
        ),
      ],
    );
  }
}
