import 'package:flutter_web_plugins/url_strategy.dart';

/// Web implementation: switches from the default hash URLs (`/#/catalog`) to
/// real paths (`/catalog`), which is what makes a pasted deep link such as
/// `/catalog/detail/product_car_001` reach the router.
///
/// The host must serve `index.html` for unknown paths (SPA fallback); the
/// README documents it.
void configureUrlStrategy() => usePathUrlStrategy();
