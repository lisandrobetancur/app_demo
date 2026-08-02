import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/i_catalog_service.dart';

/// Catalog contract provider; the module overrides it.
final Provider<ICatalogService> catalogServiceProvider =
    Provider<ICatalogService>(
      (Ref ref) => throw UnimplementedError('catalogServiceProvider'),
    );

/// Shared favorites counter, kept fresh by the catalog service after every
/// toggle (dashboard and detail badges derive from it).
final StateProvider<int> favoritesCountProvider = StateProvider<int>(
  (Ref ref) => 0,
);
