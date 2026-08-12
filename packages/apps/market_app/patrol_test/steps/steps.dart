import 'package:patrol/patrol.dart';

import 'auth_steps.dart';
import 'cart_steps.dart';
import 'catalog_steps.dart';

export 'auth_steps.dart';
export 'base_steps.dart';
export 'cart_steps.dart';
export 'catalog_steps.dart';

/// Single entry point to the steps layer.
///
/// A test builds one `Steps($)` and reads as a specification:
///
/// ```dart
/// final Steps steps = Steps($);
/// await steps.auth.loginAsDemoUser();
/// await steps.catalog.openCatalog();
/// ```
class Steps {
  Steps(PatrolIntegrationTester $)
    : auth = AuthSteps($),
      catalog = CatalogSteps($),
      cart = CartSteps($);

  final AuthSteps auth;
  final CatalogSteps catalog;
  final CartSteps cart;
}
