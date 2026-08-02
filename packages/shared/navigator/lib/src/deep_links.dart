/// Helpers for the `market://` custom scheme.
///
/// A deep link like `market://catalog/detail/product_car_001` carries the
/// route in `host + path`; [normalize] converts it into the in-app location
/// `/catalog/detail/product_car_001`. Web uses plain URLs, so it never needs
/// normalization.
class DeepLinks {
  const DeepLinks._();

  /// Custom scheme registered in AndroidManifest.xml and Info.plist.
  static const String scheme = 'market';

  /// Converts a deep-link URI into an in-app location.
  static String normalize(Uri uri) =>
      uri.scheme == scheme ? '/${uri.host}${uri.path}' : uri.toString();

  /// Builds the shareable deep link for an in-app [location]
  /// (e.g. `/catalog/detail/x` → `market://catalog/detail/x`).
  static String toDeepLink(String location) => '$scheme:/$location';
}
