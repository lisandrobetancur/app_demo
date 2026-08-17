import 'package:catalog_constants/catalog_constants.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_kit/patrol_kit.dart';


/// F07 · Catalog list, search and filters.
class CatalogPage extends BasePage {
  const CatalogPage(super.$);

  @override
  PatrolFinder get root => $(CatalogListKeys.view);

  PatrolFinder get searchInput => $(CatalogListKeys.searchInput);

  PatrolFinder get filterButton => $(CatalogListKeys.filterButton);

  PatrolFinder get filterSheet => $(CatalogListKeys.filterSheet);

  PatrolFinder get sortDropdown => $(CatalogListKeys.sortDropdown);

  PatrolFinder get clearFiltersButton => $(CatalogListKeys.clearFiltersButton);

  PatrolFinder get resultsCountText => $(CatalogListKeys.resultsCountText);

  PatrolFinder get productsList => $(CatalogListKeys.productsList);

  /// A product row by entity id — never by list index.
  PatrolFinder productItem(String productId) =>
      $(CatalogListKeys.productItem(productId));

  /// Root of one of the four view states: loading, data, empty, error.
  PatrolFinder state(String name) => $(CatalogListKeys.state(name));

  /// Category filter chip inside the filter sheet, by category code.
  PatrolFinder categoryFilter(String code) =>
      $(CatalogListKeys.categoryFilter(code));

  /// Condition filter chip: `NEW` or `USED`.
  PatrolFinder conditionFilter(String value) =>
      $(CatalogListKeys.conditionFilter(value));

  Future<void> search(String term) => searchInput.enterText(term);

  Future<void> openFilters() => filterButton.tap();

  Future<void> toggleCategory(String code) => categoryFilter(code).tap();

  Future<void> toggleCondition(String value) => conditionFilter(value).tap();

  Future<void> clearFilters() => clearFiltersButton.tap();

  /// Scrolls the (virtualized) list until the row is built and taps it.
  ///
  /// The seed has 15 products ordered by recency, so most rows are off-screen
  /// and would not exist in the widget tree without scrolling first.
  Future<void> openProduct(String productId) async {
    await productItem(productId).scrollTo(view: productsList.finder);
    await productItem(productId).tap();
  }
}
