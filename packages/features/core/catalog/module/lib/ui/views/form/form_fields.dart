part of com.demo.market.catalog.ui.views.form;

/// Input fields of the product form. Text fields keep their own edit state
/// (initialized from the controller once) while the controller stays the
/// single source of truth for validation and submission.
class _FormFields extends ConsumerStatefulWidget {
  const _FormFields();

  @override
  ConsumerState<_FormFields> createState() => _FormFieldsState();
}

class _FormFieldsState extends ConsumerState<_FormFields> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    final FormState state = ref.read(formViewModelProvider);
    _nameController = TextEditingController(text: state.name);
    _descriptionController = TextEditingController(text: state.description);
    _priceController = TextEditingController(text: state.priceText);
    _stockController = TextEditingController(text: state.stockText);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) {
      return;
    }
    final Uint8List bytes = await picked.readAsBytes();
    ref.read(formViewModelProvider.notifier).setImageBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final FormState state = ref.watch(formViewModelProvider);
    final FormViewModel viewModel = ref.read(formViewModelProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          key: ProductFormKeys.nameInput,
          label: 'catalog.form.name_label'.tr(),
          controller: _nameController,
          maxLength: CatalogLimits.nameMaxLength,
          errorText: state.nameErrorKey?.tr(),
          onChanged: viewModel.setName,
        ),
        AppSpacing.formGap,
        AppTextField(
          key: ProductFormKeys.descriptionInput,
          label: 'catalog.form.description_label'.tr(),
          controller: _descriptionController,
          maxLength: CatalogLimits.descriptionMaxLength,
          maxLines: 4,
          errorText: state.descriptionErrorKey?.tr(),
          onChanged: viewModel.setDescription,
        ),
        AppSpacing.formGap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppTextField(
                key: ProductFormKeys.priceInput,
                label: 'catalog.form.price_label'.tr(),
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: state.priceErrorKey?.tr(),
                onChanged: viewModel.setPriceText,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                key: ProductFormKeys.stockInput,
                label: 'catalog.form.stock_label'.tr(),
                controller: _stockController,
                keyboardType: TextInputType.number,
                errorText: state.stockErrorKey?.tr(),
                onChanged: viewModel.setStockText,
              ),
            ),
          ],
        ),
        AppSpacing.formGap,
        DropdownMenu<String>(
          key: ProductFormKeys.categoryDropdown,
          initialSelection: state.categoryId,
          expandedInsets: EdgeInsets.zero,
          label: Text('catalog.form.category_label'.tr()),
          onSelected: (String? value) {
            if (value != null) {
              viewModel.setCategoryId(value);
            }
          },
          dropdownMenuEntries: <DropdownMenuEntry<String>>[
            for (final Category category in state.categories)
              DropdownMenuEntry<String>(
                value: category.id,
                label: category.labelKey.tr(),
              ),
          ],
        ),
        AppSpacing.formGap,
        Text(
          'catalog.form.condition_label'.tr(),
          style: AppTypography.cardTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          key: ProductFormKeys.conditionSelector,
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final ProductCondition condition in ProductCondition.values)
              ChoiceChip(
                key: ProductFormKeys.conditionOption(condition.dbValue),
                label: Text(condition.labelKey.tr()),
                selected: state.condition == condition,
                onSelected: (bool _) => viewModel.setCondition(condition),
              ),
          ],
        ),
        AppSpacing.formGap,
        Text('catalog.form.image_label'.tr(), style: AppTypography.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        if (state.imageBytes != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ClipRRect(
              key: ProductFormKeys.imagePreview,
              borderRadius: AppRadius.card,
              child: Image.memory(
                state.imageBytes!,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
        AppButton(
          key: ProductFormKeys.imagePickerButton,
          label: 'catalog.form.pick_image_button'.tr(),
          icon: AppIcons.image,
          variant: AppButtonVariant.secondary,
          onPressed: _pickImage,
        ),
      ],
    );
  }
}
