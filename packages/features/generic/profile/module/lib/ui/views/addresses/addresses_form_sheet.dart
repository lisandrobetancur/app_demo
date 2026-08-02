part of com.demo.market.profile.ui.views.addresses;

/// Create/edit address bottom sheet.
class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet({this.existing});

  final Address? existing;

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  late String _label = widget.existing?.label ?? '';
  late String _line1 = widget.existing?.line1 ?? '';
  late String _city = widget.existing?.city ?? '';
  late String _state = widget.existing?.state ?? '';
  late String _notes = widget.existing?.notes ?? '';
  bool _saving = false;

  bool get _isValid =>
      _label.trim().isNotEmpty &&
      _line1.trim().isNotEmpty &&
      _city.trim().isNotEmpty &&
      _state.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final AddressesViewModel viewModel = ref.read(
      addressesViewModelProvider.notifier,
    );
    if (widget.existing == null) {
      await viewModel.create(
        label: _label,
        line1: _line1,
        city: _city,
        stateName: _state,
        notes: _notes.trim().isEmpty ? null : _notes,
      );
    } else {
      await viewModel.update(
        widget.existing!.copyWith(
          label: _label.trim(),
          line1: _line1.trim(),
          city: _city.trim(),
          state: _state.trim(),
          notes: _notes.trim().isEmpty ? null : _notes.trim(),
        ),
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.existing == null
              ? 'profile.addresses.add_button'.tr()
              : 'profile.addresses.edit_button'.tr(),
          style: AppTypography.sectionTitle,
        ),
        AppSpacing.formGap,
        AppTextField(
          key: AddressesKeys.labelInput,
          label: 'profile.addresses.label_label'.tr(),
          controller: TextEditingController(text: _label),
          onChanged: (String value) => setState(() => _label = value),
        ),
        AppSpacing.formGap,
        AppTextField(
          key: AddressesKeys.line1Input,
          label: 'profile.addresses.line1_label'.tr(),
          controller: TextEditingController(text: _line1),
          onChanged: (String value) => setState(() => _line1 = value),
        ),
        AppSpacing.formGap,
        AppTextField(
          key: AddressesKeys.cityInput,
          label: 'profile.addresses.city_label'.tr(),
          controller: TextEditingController(text: _city),
          onChanged: (String value) => setState(() => _city = value),
        ),
        AppSpacing.formGap,
        AppTextField(
          key: AddressesKeys.stateInput,
          label: 'profile.addresses.state_label'.tr(),
          controller: TextEditingController(text: _state),
          onChanged: (String value) => setState(() => _state = value),
        ),
        AppSpacing.formGap,
        AppTextField(
          key: AddressesKeys.notesInput,
          label: 'profile.addresses.notes_label'.tr(),
          controller: TextEditingController(text: _notes),
          onChanged: (String value) => setState(() => _notes = value),
        ),
        AppSpacing.formGap,
        AppButton(
          key: AddressesKeys.saveButton,
          label: 'profile.addresses.save_button'.tr(),
          isLoading: _saving,
          onPressed: _isValid && !_saving ? _save : null,
          expand: true,
        ),
      ],
    ),
  );
}
