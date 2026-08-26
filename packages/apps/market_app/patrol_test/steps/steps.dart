import 'package:patrol/patrol.dart';

import 'auth_steps.dart';
import 'cart_steps.dart';
import 'catalog_steps.dart';

export 'auth_steps.dart';
export 'cart_steps.dart';
export 'catalog_steps.dart';

/// Single entry point to the steps layer.
///
/// A test builds one `Steps($)` and reads as a specification:
///
/// ```dart
/// final Steps steps = Steps($);
/// await steps.auth.login(email: email, password: password);
/// await steps.auth.expectLoggedInAs(fullName);
/// await steps.catalog.openCatalog();
/// ```
///
/// The data in those calls comes from the TEST, which read it from its data
/// file inside the body: a step performs and asserts what it is handed, and
/// never reaches into `TestData` on its own.
class Steps {
  Steps(PatrolIntegrationTester $)
    : auth = AuthSteps($),
      catalog = CatalogSteps($),
      cart = CartSteps($);

  final AuthSteps auth;
  final CatalogSteps catalog;
  final CartSteps cart;
}
