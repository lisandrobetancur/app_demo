part of com.demo.market.authentication.ui.views.recover_password;

/// Step 2: 6-digit code, surfaced in a demo banner (offline demo — in
/// production it would arrive by email).
class _RecoverStepCode extends ConsumerWidget {
  const _RecoverStepCode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecoverState state = ref.watch(recoverViewModelProvider);
    final RecoverViewModel viewModel = ref.read(
      recoverViewModelProvider.notifier,
    );
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          key: RecoverPasswordKeys.demoCodeBanner,
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: AppRadius.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'authentication.recover.demo_code_banner'.tr(
                namedArgs: <String, String>{'code': state.issuedCode},
              ),
              style: AppTypography.body.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ),
        AppSpacing.formGap,
        AppTextField(
          key: RecoverPasswordKeys.codeInput,
          label: 'authentication.recover.code_label'.tr(),
          keyboardType: TextInputType.number,
          maxLength: AuthenticationLimits.recoveryCodeLength,
          onChanged: viewModel.setCodeInput,
          onSubmitted: (String _) => viewModel.validateCode(),
        ),
        AppSpacing.formGap,
        AppButton(
          key: RecoverPasswordKeys.validateCodeButton,
          label: 'authentication.recover.validate_code_button'.tr(),
          onPressed: state.canValidateCode ? viewModel.validateCode : null,
          expand: true,
        ),
      ],
    );
  }
}
