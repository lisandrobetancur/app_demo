import 'dart:typed_data';

import '../enums/product_status.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_filters.dart';
import '../models/review.dart';

/// Catalog contract: listing, search, publications, favorites and reviews.
abstract interface class ICatalogService {
  /// All categories, ordered by name.
  Future<List<Category>> getCategories();

  /// Active-catalog page for [filters] (deterministic order, stable
  /// tie-breaker). Only `ACTIVE` publications appear.
  Future<List<Product>> getProducts({
    required ProductFilters filters,
    required int limit,
    required int offset,
  });

  /// Result count for [filters] (drives the results counter).
  Future<int> countProducts({required ProductFilters filters});

  /// One product with joined data, regardless of status (detail of paused
  /// or deleted products is still reachable from history). `null` when the
  /// id does not exist.
  Future<Product?> getProduct(String productId);

  /// Newest active products (dashboard carousel).
  Future<List<Product>> getRecentProducts({required int limit});

  /// Reviews of a product, newest first.
  Future<List<Review>> reviewsFor(String productId);

  /// Creates a publication owned by [ownerId] and returns it.
  Future<Product> createProduct({
    required String ownerId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    required String conditionDbValue,
    Uint8List? imageBytes,
  });

  /// Updates an existing publication and returns the fresh row.
  Future<Product> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    required String conditionDbValue,
    Uint8List? imageBytes,
  });

  /// Publications of [ownerId] (any status except deleted), newest first.
  Future<List<Product>> myProducts(String ownerId);

  /// Pauses/reactivates/logically-deletes a publication.
  Future<void> setProductStatus({
    required String productId,
    required ProductStatus status,
  });

  /// Quick stock adjustment from the my-products list.
  Future<void> updateStock({required String productId, required int stock});

  // --- Favorites (F14) ---

  /// Ids of the products [userId] marked as favorite.
  Future<Set<String>> favoriteIds(String userId);

  /// Toggles a favorite; returns the new state (true = favorite).
  Future<bool> toggleFavorite({
    required String userId,
    required String productId,
  });

  /// Favorite products with joined data (including paused/deleted ones, so
  /// the UI can flag them).
  Future<List<Product>> favoriteProducts(String userId);

  // --- Reviews (F15) ---

  /// True when [userId] received a DELIVERED order containing [productId].
  Future<bool> canReview({required String userId, required String productId});

  /// The user's own review of the product, if any.
  Future<Review?> myReview({required String userId, required String productId});

  /// Creates or updates the user's review (one per user per product).
  Future<void> upsertReview({
    required String userId,
    required String productId,
    required int rating,
    String? comment,
  });

  // --- Search history (F07) ---

  /// Last distinct search terms of [userId], newest first.
  Future<List<String>> recentSearches({
    required String userId,
    required int limit,
  });

  /// Records a search term for suggestions.
  Future<void> recordSearch({required String userId, required String term});
}
