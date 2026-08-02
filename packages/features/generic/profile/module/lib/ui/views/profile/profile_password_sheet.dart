part of com.demo.market.profile.ui.views.profile;

/// Change-password bottom sheet: current + new + confirmation.
class _ProfilePasswordSheet extends ConsumerWidget {
  const _ProfilePasswordSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState state = ref.watch(profileViewModelProvider);
    final ProfileViewModel viewModel = ref.read(
      profileViewModelProvider.notifier,
    );
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'profile.home.change_password_button'.tr(),
            style: AppTypography.sectionTitle,
          ),
          AppSpacing.formGap,
          AppTextField(
            key: ProfileKeys.currentPasswordInput,
            label: 'profile.home.current_password_label'.tr(),
            obscureText: true,
            onChanged: viewModel.setCurrentPassword,
          ),
          AppSpacing.formGap,
          AppTextField(
            key: ProfileKeys.newPasswordInput,
            label: 'profile.home.new_password_label'.tr(),
            obscureText: true,
            errorText: state.newPasswordErrorKey?.tr(),
            onChanged: viewModel.setNewPassword,
          ),
          AppSpacing.formGap,
          AppTextField(
            key: ProfileKeys.confirmNewPasswordInput,
            label: 'profile.home.confirm_new_password_label'.tr(),
            obscureText: true,
            errorText: state.confirmNewPasswordErrorKey?.tr(),
            onChanged: viewModel.setConfirmNewPassword,
          ),
          if (state.errorKey != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                state.errorKey!.tr(),
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          AppSpacing.formGap,
          AppButton(
            key: ProfileKeys.submitPasswordButton,
            label: 'profile.home.submit_password_button'.tr(),
            isLoading: state.isChangingPassword,
            onPressed: state.canChangePassword
                ? () async {
                    await viewModel.changePassword();
                    if (context.mounted &&
                        ref.read(profileViewModelProvider).errorKey == null) {
                      Navigator.of(context).pop();
                    }
                  }
                : null,
            expand: true,
          ),
        ],
      ),
    );
  }
}
