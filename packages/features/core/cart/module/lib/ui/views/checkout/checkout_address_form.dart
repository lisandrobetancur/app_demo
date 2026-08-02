part of com.demo.market.cart.ui.views.checkout;

/// Inline address creation inside the delivery step.
class _CheckoutAddressForm extends ConsumerStatefulWidget {
  const _CheckoutAddressForm();

  @override
  ConsumerState<_CheckoutAddressForm> createState() =>
      _CheckoutAddressFormState();
}

class _CheckoutAddressFormState extends ConsumerState<_CheckoutAddressForm> {
  String _label = '';
  String _line1 = '';
  String _city = '';
  String _state = '';
  String _notes = '';
  bool _saving = false;

  bool get _isValid =>
      _label.trim().isNotEmpty &&
      _line1.trim().isNotEmpty &&
      _city.trim().isNotEmpty &&
      _state.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(checkoutViewModelProvider.notifier)
        .createAddress(
          label: _label,
          line1: _line1,
          city: _city,
          stateName: _state,
          notes: _notes.trim().isEmpty ? null : _notes,
        );
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
          'cart.checkout.add_address_button'.tr(),
          style: AppTypography.sectionTitle,
        ),
        AppSpacing.formGap,
        AppTextField(
          label: 'cart.checkout.address_label'.tr(),
          onChanged: (String value) => setState(() => _label = value),
        ),
        AppSpacing.formGap,
        AppTextField(
          label: 'cart.checkout.address_line1'.tr(),
          onChanged: (String value) => setState(() => _line1 = value),
        ),
        AppSpacing.formGap,
        AppTextField(
          label: 'cart.checkout.address_city'.tr(),
          onChanged: (String value) => setState(() => _city = value),
        ),
        AppSpacing.formGap,
        AppTextField(
          label: 'cart.checkout.address_state'.tr(),
          onChanged: (String value) => setState(() => _state = value),
        ),
        AppSpacing.formGap,
        AppTextField(
          label: 'cart.checkout.address_notes'.tr(),
          onChanged: (String value) => setState(() => _notes = value),
        ),
        AppSpacing.formGap,
        AppButton(
          label: 'cart.checkout.address_save_button'.tr(),
          isLoading: _saving,
          onPressed: _isValid && !_saving ? _save : null,
          expand: true,
        ),
      ],
    ),
  );
}
