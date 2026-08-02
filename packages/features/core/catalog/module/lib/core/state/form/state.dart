part of com.demo.market.catalog.core.state.form;

/// Immutable state of the publish/edit form (F09).
class FormState {
  const FormState({
    this.productId,
    this.name = '',
    this.description = '',
    this.priceText = '',
    this.stockText = '0',
    this.categoryId = '',
    this.condition = ProductCondition.brandNew,
    this.imageBytes,
    this.categories = const <Category>[],
    this.status = ViewStatus.loading,
    this.isSaving = false,
    this.isDirty = false,
    this.errorKey,
  });

  /// Null when creating; set when editing an existing publication.
  final String? productId;

  final String name;
  final String description;
  final String priceText;
  final String stockText;
  final String categoryId;
  final ProductCondition condition;
  final Uint8List? imageBytes;
  final List<Category> categories;
  final ViewStatus status;
  final bool isSaving;

  /// Unsaved changes → leaving asks for confirmation.
  final bool isDirty;

  final String? errorKey;

  bool get isEditing => productId != null;

  String? get nameErrorKey =>
      name.isEmpty ||
          Validators.hasLengthBetween(
            name,
            min: CatalogLimits.nameMinLength,
            max: CatalogLimits.nameMaxLength,
          )
      ? null
      : 'catalog.form.name_invalid';

  String? get descriptionErrorKey =>
      description.isEmpty ||
          Validators.hasLengthBetween(
            description,
            min: CatalogLimits.descriptionMinLength,
            max: CatalogLimits.descriptionMaxLength,
          )
      ? null
      : 'catalog.form.description_invalid';

  String? get priceErrorKey {
    if (priceText.isEmpty) {
      return null;
    }
    final double? price = Validators.parsePrice(priceText);
    return price == null || price <= 0 ? 'catalog.form.price_invalid' : null;
  }

  String? get stockErrorKey =>
      stockText.isEmpty || Validators.parseStock(stockText) != null
      ? null
      : 'catalog.form.stock_invalid';

  bool get canSubmit {
    final double? price = Validators.parsePrice(priceText);
    return !isSaving &&
        Validators.hasLengthBetween(
          name,
          min: CatalogLimits.nameMinLength,
          max: CatalogLimits.nameMaxLength,
        ) &&
        Validators.hasLengthBetween(
          description,
          min: CatalogLimits.descriptionMinLength,
          max: CatalogLimits.descriptionMaxLength,
        ) &&
        price != null &&
        price > 0 &&
        Validators.parseStock(stockText) != null &&
        categoryId.isNotEmpty;
  }

  FormState copyWith({
    String? productId,
    String? name,
    String? description,
    String? priceText,
    String? stockText,
    String? categoryId,
    ProductCondition? condition,
    Uint8List? imageBytes,
    List<Category>? categories,
    ViewStatus? status,
    bool? isSaving,
    bool? isDirty,
    String? errorKey,
    bool clearError = false,
  }) => FormState(
    productId: productId ?? this.productId,
    name: name ?? this.name,
    description: description ?? this.description,
    priceText: priceText ?? this.priceText,
    stockText: stockText ?? this.stockText,
    categoryId: categoryId ?? this.categoryId,
    condition: condition ?? this.condition,
    imageBytes: imageBytes ?? this.imageBytes,
    categories: categories ?? this.categories,
    status: status ?? this.status,
    isSaving: isSaving ?? this.isSaving,
    isDirty: isDirty ?? this.isDirty,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  bool operator ==(Object other) =>
      other is FormState &&
      other.productId == productId &&
      other.name == name &&
      other.description == description &&
      other.priceText == priceText &&
      other.stockText == stockText &&
      other.categoryId == categoryId &&
      other.condition == condition &&
      other.imageBytes?.length == imageBytes?.length &&
      other.categories.length == categories.length &&
      other.status == status &&
      other.isSaving == isSaving &&
      other.isDirty == isDirty &&
      other.errorKey == errorKey;

  @override
  int get hashCode => Object.hash(
    productId,
    name,
    description,
    priceText,
    stockText,
    categoryId,
    condition,
    imageBytes?.length,
    categories.length,
    status,
    isSaving,
    isDirty,
    errorKey,
  );

  @override
  String toString() =>
      'FormState: ${isEditing ? 'edit' : 'create'} dirty:$isDirty '
      'saving:$isSaving';
}
