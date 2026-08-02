part of com.demo.market.profile.ui.views.profile;

/// Inline edit form: name, phone and avatar.
class _ProfileEditForm extends ConsumerStatefulWidget {
  const _ProfileEditForm();

  @override
  ConsumerState<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<_ProfileEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final ProfileState state = ref.read(profileViewModelProvider);
    _nameController = TextEditingController(text: state.fullName);
    _phoneController = TextEditingController(text: state.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) {
      return;
    }
    final Uint8List bytes = await picked.readAsBytes();
    ref.read(profileViewModelProvider.notifier).setPendingAvatar(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final ProfileState state = ref.watch(profileViewModelProvider);
    final ProfileViewModel viewModel = ref.read(
      profileViewModelProvider.notifier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          key: ProfileKeys.nameInput,
          label: 'profile.home.name_label'.tr(),
          controller: _nameController,
          onChanged: viewModel.setFullName,
        ),
        AppSpacing.formGap,
        AppTextField(
          key: ProfileKeys.phoneInput,
          label: 'profile.home.phone_label'.tr(),
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          onChanged: viewModel.setPhone,
        ),
        AppSpacing.formGap,
        AppButton(
          key: ProfileKeys.avatarPickerButton,
          label: 'profile.home.avatar_button'.tr(),
          icon: AppIcons.camera,
          variant: AppButtonVariant.secondary,
          onPressed: _pickAvatar,
        ),
        AppSpacing.formGap,
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'profile.home.cancel_button'.tr(),
                variant: AppButtonVariant.text,
                onPressed: viewModel.cancelEditing,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                key: ProfileKeys.saveProfileButton,
                label: 'profile.home.save_button'.tr(),
                isLoading: state.isSaving,
                onPressed: state.canSaveProfile ? viewModel.saveProfile : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
