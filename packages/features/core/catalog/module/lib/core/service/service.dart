part of com.demo.market.catalog.core;

/// Concrete [ICatalogService].
///
/// Converts rows into models, hydrates product images through the
/// cross-platform [ImageStorage] and applies the business rules (logical
/// deletion, review gating, favorites counter).
class CatalogService implements ICatalogService {
  CatalogService({
    required CatalogDao dao,
    required Clock clock,
    required IdGenerator idGenerator,
    required ImageStorage imageStorage,
    required StateController<int> favoritesCount,
  }) : _dao = dao,
       _clock = clock,
       _idGenerator = idGenerator,
       _imageStorage = imageStorage,
       _favoritesCount = favoritesCount;

  final CatalogDao _dao;
  final Clock _clock;
  final IdGenerator _idGenerator;
  final ImageStorage _imageStorage;
  final StateController<int> _favoritesCount;

  @override
  Future<List<Category>> getCategories() async {
    final List<Map<String, Object?>> rows = await _dao.categories();
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<List<Product>> getProducts({
    required ProductFilters filters,
    required int limit,
    required int offset,
  }) async {
    final List<Map<String, Object?>> rows = await _dao.products(
      filters: filters,
      limit: limit,
      offset: offset,
    );
    return _hydrateAll(rows);
  }

  @override
  Future<int> countProducts({required ProductFilters filters}) =>
      _dao.countProducts(filters: filters);

  @override
  Future<Product?> getProduct(String productId) async {
    final Map<String, Object?>? row = await _dao.productById(productId);
    if (row == null) {
      return null;
    }
    return _hydrate(row);
  }

  @override
  Future<List<Product>> getRecentProducts({required int limit}) async =>
      _hydrateAll(await _dao.recentProducts(limit));

  @override
  Future<List<Review>> reviewsFor(String productId) async {
    final List<Map<String, Object?>> rows = await _dao.reviewsFor(productId);
    return rows.map(Review.fromMap).toList();
  }

  @override
  Future<Product> createProduct({
    required String ownerId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    required String conditionDbValue,
    Uint8List? imageBytes,
  }) async {
    final String id = _idGenerator.newId();
    final int now = _clock().millisecondsSinceEpoch;
    String? imagePath;
    if (imageBytes != null) {
      imagePath = await _imageStorage.save(bytes: imageBytes, imageId: id);
    }
    await _dao.insertProduct(<String, Object?>{
      'id': id,
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'image_path': imagePath,
      'condition': conditionDbValue,
      'status': ProductStatus.active.dbValue,
      'owner_id': ownerId,
      'created_at': now,
      'updated_at': now,
    });
    final Product? created = await getProduct(id);
    return created!;
  }

  @override
  Future<Product> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    required String conditionDbValue,
    Uint8List? imageBytes,
  }) async {
    final Map<String, Object?> values = <String, Object?>{
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'condition': conditionDbValue,
      'updated_at': _clock().millisecondsSinceEpoch,
    };
    if (imageBytes != null) {
      values['image_path'] = await _imageStorage.save(
        bytes: imageBytes,
        imageId: productId,
      );
    }
    await _dao.updateProduct(productId, values);
    final Product? updated = await getProduct(productId);
    return updated!;
  }

  @override
  Future<List<Product>> myProducts(String ownerId) async =>
      _hydrateAll(await _dao.productsByOwner(ownerId));

  @override
  Future<void> setProductStatus({
    required String productId,
    required ProductStatus status,
  }) => _dao.updateProduct(productId, <String, Object?>{
    'status': status.dbValue,
    'updated_at': _clock().millisecondsSinceEpoch,
  });

  @override
  Future<void> updateStock({required String productId, required int stock}) =>
      _dao.updateProduct(productId, <String, Object?>{
        'stock': stock,
        'updated_at': _clock().millisecondsSinceEpoch,
      });

  @override
  Future<Set<String>> favoriteIds(String userId) async {
    final List<Map<String, Object?>> rows = await _dao.favoriteRows(userId);
    return rows
        .map((Map<String, Object?> row) => row['product_id']! as String)
        .toSet();
  }

  @override
  Future<bool> toggleFavorite({
    required String userId,
    required String productId,
  }) async {
    final bool exists = await _dao.isFavorite(
      userId: userId,
      productId: productId,
    );
    if (exists) {
      await _dao.deleteFavorite(userId: userId, productId: productId);
    } else {
      await _dao.insertFavorite(
        userId: userId,
        productId: productId,
        createdAt: _clock().millisecondsSinceEpoch,
      );
    }
    _favoritesCount.state = await _dao.favoritesCount(userId);
    return !exists;
  }

  @override
  Future<List<Product>> favoriteProducts(String userId) async {
    _favoritesCount.state = await _dao.favoritesCount(userId);
    return _hydrateAll(await _dao.favoriteProducts(userId));
  }

  @override
  Future<bool> canReview({required String userId, required String productId}) =>
      _dao.hasDeliveredPurchase(userId: userId, productId: productId);

  @override
  Future<Review?> myReview({
    required String userId,
    required String productId,
  }) async {
    final Map<String, Object?>? row = await _dao.reviewByUser(
      userId: userId,
      productId: productId,
    );
    return row == null ? null : Review.fromMap(row);
  }

  @override
  Future<void> upsertReview({
    required String userId,
    required String productId,
    required int rating,
    String? comment,
  }) async {
    final Review? existing = await myReview(
      userId: userId,
      productId: productId,
    );
    await _dao.upsertReview(<String, Object?>{
      'id': existing?.id ?? _idGenerator.newId(),
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'comment': comment == null || comment.trim().isEmpty
          ? null
          : comment.trim(),
      'created_at': _clock().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<String>> recentSearches({
    required String userId,
    required int limit,
  }) async {
    final List<Map<String, Object?>> rows = await _dao.recentSearches(
      userId: userId,
      limit: limit,
    );
    return rows
        .map((Map<String, Object?> row) => row['term']! as String)
        .toList();
  }

  @override
  Future<void> recordSearch({
    required String userId,
    required String term,
  }) async {
    final String trimmed = term.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await _dao.insertSearch(<String, Object?>{
      'id': _idGenerator.newId(),
      'user_id': userId,
      'term': trimmed,
      'created_at': _clock().millisecondsSinceEpoch,
    });
  }

  Future<List<Product>> _hydrateAll(List<Map<String, Object?>> rows) async {
    final List<Product> products = <Product>[];
    for (final Map<String, Object?> row in rows) {
      products.add(await _hydrate(row));
    }
    return products;
  }

  Future<Product> _hydrate(Map<String, Object?> row) async {
    final Product product = Product.fromMap(row);
    if (product.imagePath == null) {
      return product;
    }
    final Uint8List? bytes = await _imageStorage.load(product.imagePath!);
    return bytes == null ? product : product.copyWith(imageBytes: bytes);
  }
}
