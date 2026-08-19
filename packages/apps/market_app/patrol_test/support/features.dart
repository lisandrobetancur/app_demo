import 'package:patrol_kit/patrol_kit.dart';

import 'epics.dart';

/// The features this suite covers, each under the epic it belongs to.
///
/// The pairing lives here and only here. A scenario names a feature and the
/// epic comes with it, which is what stops one test filing `Authentication`
/// under `Access` and the next filing it under `Accounts` — the same feature
/// twice in one report, with its scenarios split between the two.
///
/// Adding a feature is one line. Moving one to another epic is one edit, and
/// every scenario under it follows.
abstract final class Features {
  /// Signing in and being rejected: the door, and the lock on it.
  static const Feature authentication = Feature(
    'Authentication',
    epic: Epics.access,
  );

  /// Browsing what is for sale, and what a seller sees on their own listing.
  static const Feature catalog = Feature('Catalog', epic: Epics.purchase);

  /// From the cart to a confirmed order, stock and all.
  static const Feature checkout = Feature(
    'Cart and checkout',
    epic: Epics.purchase,
  );

  /// Discounts, and the ones the product has to refuse.
  static const Feature coupons = Feature('Coupons', epic: Epics.purchase);
}
