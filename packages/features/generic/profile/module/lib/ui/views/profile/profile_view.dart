part of com.demo.market.profile.ui.views.profile;

/// F16 · Profile: personal data, security and shortcuts.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  static const String route = ProfileRoutes.profilePath;
  static const String name = ProfileRoutes.profileName;

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      dialogKey: ProfileKeys.logoutConfirmDialog,
      title: 'profile.home.logout_title'.tr(),
      message: 'profile.home.logout_message'.tr(),
      confirmLabel: 'profile.home.confirm'.tr(),
      cancelLabel: 'profile.home.cancel'.tr(),
    );
    if (confirmed) {
      await ref.read(profileViewModelProvider.notifier).logout();
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool first = await AppDialog.confirm(
      context,
      dialogKey: ProfileKeys.confirmDeleteAccountDialog,
      title: 'profile.home.delete_account_title'.tr(),
      message: 'profile.home.delete_account_message'.tr(),
      confirmLabel: 'profile.home.confirm'.tr(),
      cancelLabel: 'profile.home.cancel'.tr(),
      destructive: true,
    );
    if (!first || !context.mounted) {
      return;
    }
    final bool second = await AppDialog.confirm(
      context,
      dialogKey: ProfileKeys.confirmDeleteAccountSecondDialog,
      title: 'profile.home.delete_account_second_title'.tr(),
      message: 'profile.home.delete_account_second_message'.tr(),
      confirmLabel: 'profile.home.confirm'.tr(),
      cancelLabel: 'profile.home.cancel'.tr(),
      destructive: true,
    );
    if (second) {
      await ref.read(profileViewModelProvider.notifier).deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState state = ref.watch(profileViewModelProvider);
    final ProfileViewModel viewModel = ref.read(
      profileViewModelProvider.notifier,
    );
    final ProfileNavigator navigatorNotifier = ref.read(
      profileNavigator.notifier,
    );
    ref.listen<ProfileState>(profileViewModelProvider, (
      ProfileState? previous,
      ProfileState next,
    ) {
      final String? event = next.lastEventKey;
      if (event != null && previous?.lastEventKey != event) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(event.tr())));
        viewModel.consumeEvent();
      }
    });
    return AppScaffold(
      key: ProfileKeys.view,
      title: 'profile.home.title'.tr(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _ProfileHeader(),
          AppSpacing.sectionGap,
          if (state.isEditing) ...<Widget>[
            const _ProfileEditForm(),
            AppSpacing.sectionGap,
          ] else
            AppButton(
              key: ProfileKeys.editProfileButton,
              label: 'profile.home.edit_button'.tr(),
              icon: AppIcons.edit,
              variant: AppButtonVariant.secondary,
              onPressed: viewModel.startEditing,
            ),
          const Divider(),
          Text(
            'profile.home.security_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          ListTile(
            key: ProfileKeys.changePasswordButton,
            leading: const Icon(AppIcons.security),
            title: Text('profile.home.change_password_button'.tr()),
            trailing: const Icon(AppIcons.chevronRight),
            contentPadding: EdgeInsets.zero,
            onTap: () => AppBottomSheet.show<void>(
              context,
              child: const _ProfilePasswordSheet(),
            ),
          ),
          ListTile(
            key: ProfileKeys.goToAddressesButton,
            leading: const Icon(AppIcons.address),
            title: Text('profile.home.addresses_button'.tr()),
            trailing: const Icon(AppIcons.chevronRight),
            contentPadding: EdgeInsets.zero,
            onTap: navigatorNotifier.goToAddresses,
          ),
          ListTile(
            key: ProfileKeys.goToSettingsButton,
            leading: const Icon(AppIcons.settings),
            title: Text('profile.home.settings_button'.tr()),
            trailing: const Icon(AppIcons.chevronRight),
            contentPadding: EdgeInsets.zero,
            onTap: navigatorNotifier.goToSettings,
          ),
          ListTile(
            key: ProfileKeys.logoutButton,
            leading: const Icon(AppIcons.logout),
            title: Text('profile.home.logout_button'.tr()),
            contentPadding: EdgeInsets.zero,
            onTap: () => _confirmLogout(context, ref),
          ),
          const Divider(),
          Text(
            'profile.home.danger_title'.tr(),
            style: AppTypography.sectionTitle.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.errorKey != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                state.errorKey!.tr(),
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          AppButton(
            key: ProfileKeys.deleteAccountButton,
            label: 'profile.home.delete_account_button'.tr(),
            variant: AppButtonVariant.danger,
            isLoading: state.isDeleting,
            onPressed: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}
