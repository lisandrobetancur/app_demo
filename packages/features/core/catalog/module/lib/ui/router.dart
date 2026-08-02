import 'package:navigator/navigator.dart';

import 'views/detail/detail.dart';
import 'views/favorites/favorites.dart';
import 'views/form/form.dart';
import 'views/list/list.dart';
import 'views/my_products/my_products.dart';
import 'views/review_form/review_form.dart';

/// Routes of this feature that live inside the navigation shell.
final List<AppRoute> catalogShellRoutes = <AppRoute>[
  const AppRoute(
    CatalogListView.route,
    name: CatalogListView.name,
    widget: CatalogListView(),
  ),
];

/// Full-screen routes of the catalog feature.
final List<AppRoute> catalogRoutes = <AppRoute>[
  const AppRoute(DetailView.route, name: DetailView.name, widget: DetailView()),
  const AppRoute(
    ProductCreateView.route,
    name: ProductCreateView.name,
    widget: ProductCreateView(),
  ),
  const AppRoute(
    ProductEditView.route,
    name: ProductEditView.name,
    widget: ProductEditView(),
  ),
  const AppRoute(
    MyProductsView.route,
    name: MyProductsView.name,
    widget: MyProductsView(),
  ),
  const AppRoute(
    FavoritesView.route,
    name: FavoritesView.name,
    widget: FavoritesView(),
  ),
  const AppRoute(
    ReviewFormView.route,
    name: ReviewFormView.name,
    widget: ReviewFormView(),
  ),
];
