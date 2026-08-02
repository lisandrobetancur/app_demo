part of com.demo.market.catalog.core.state.form;

/// Controller of the publish/edit product form.
class FormViewModel extends ViewModel<FormState> {
  FormViewModel({FormState? state}) : super(state ?? const FormState());

  @override
  void postInit() {
    service = ref.read(catalogServiceProvider);
    navigatorNotifier = ref.read(catalogNavigator.notifier);
  }

  late ICatalogService service;
  late CatalogNavigator navigatorNotifier;

  /// Prepares the form: loads categories and, when editing, the product.
  Future<void> start({String? productId}) async {
    state = const FormState();
    final Object? key = mountedKey;
    try {
      final List<Category> categories = await service.getCategories();
      Product? product;
      if (productId != null) {
        product = await service.getProduct(productId);
      }
      if (key != mountedKey) {
        return;
      }
      if (productId != null && product == null) {
        state = state.copyWith(status: ViewStatus.empty);
        return;
      }
      state = state.copyWith(
        productId: productId,
        categories: categories,
        name: product?.name ?? '',
        description: product?.description ?? '',
        priceText: product == null ? '' : _formatEditablePrice(product.price),
        stockText: product?.stock.toString() ?? '0',
        categoryId:
            product?.categoryId ??
            (categories.isEmpty ? '' : categories.first.id),
        condition: product?.condition ?? ProductCondition.brandNew,
        imageBytes: product?.imageBytes,
        status: ViewStatus.data,
      );
    } on Object catch (error, stackTrace) {
      log.error('catalog.form.start', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(status: ViewStatus.error);
    }
  }

  void setName(String value) =>
      state = state.copyWith(name: value, isDirty: true, clearError: true);

  void setDescription(String value) => state = state.copyWith(
    description: value,
    isDirty: true,
    clearError: true,
  );

  void setPriceText(String value) =>
      state = state.copyWith(priceText: value, isDirty: true, clearError: true);

  void setStockText(String value) =>
      state = state.copyWith(stockText: value, isDirty: true, clearError: true);

  void setCategoryId(String value) => state = state.copyWith(
    categoryId: value,
    isDirty: true,
    clearError: true,
  );

  void setCondition(ProductCondition value) =>
      state = state.copyWith(condition: value, isDirty: true);

  void setImageBytes(Uint8List bytes) =>
      state = state.copyWith(imageBytes: bytes, isDirty: true);

  Future<void> save() async {
    if (!state.canSubmit) {
      return;
    }
    final String? ownerId = ref.read(authSessionProvider)?.id;
    if (ownerId == null) {
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    final Object? key = mountedKey;
    try {
      final double price = Validators.parsePrice(state.priceText)!;
      final int stock = Validators.parseStock(state.stockText)!;
      if (state.isEditing) {
        await service.updateProduct(
          productId: state.productId!,
          name: state.name,
          description: state.description,
          price: price,
          stock: stock,
          categoryId: state.categoryId,
          conditionDbValue: state.condition.dbValue,
          imageBytes: state.imageBytes,
        );
      } else {
        await service.createProduct(
          ownerId: ownerId,
          name: state.name,
          description: state.description,
          price: price,
          stock: stock,
          categoryId: state.categoryId,
          conditionDbValue: state.condition.dbValue,
          imageBytes: state.imageBytes,
        );
      }
      // Listings must show the change as soon as the user returns.
      ref
        ..invalidate(listViewModelProvider)
        ..invalidate(myProductsViewModelProvider);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isSaving: false, isDirty: false);
      navigatorNotifier.back();
    } on Object catch (error, stackTrace) {
      log.error('catalog.form.save', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSaving: false,
        errorKey: 'catalog.form.save_error',
      );
    }
  }

  /// Whole prices render without decimals in the editable field.
  String _formatEditablePrice(double price) => price == price.roundToDouble()
      ? price.toInt().toString()
      : price.toString();
}
