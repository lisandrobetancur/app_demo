part of com.demo.market.catalog.ui.views.form;

/// Scrollable body of the product form.
class _FormBody extends ConsumerWidget {
  const _FormBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FormState state = ref.watch(formViewModelProvider);
    final FormViewModel viewModel = ref.read(formViewModelProvider.notifier);
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _FormFields(),
          const SizedBox(height: AppSpacing.lg),
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
          AppButton(
            key: ProductFormKeys.saveButton,
            label: 'catalog.form.save_button'.tr(),
            isLoading: state.isSaving,
            onPressed: state.canSubmit ? viewModel.save : null,
            expand: true,
          ),
        ],
      ),
    );
  }
}
