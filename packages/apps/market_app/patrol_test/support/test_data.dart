import 'package:patrol_kit/patrol_kit.dart';

/// Typed access to the data in `patrol_test/data/`.
///
/// A thin façade and nothing more: the values live in JSON, this class only
/// names them. It exists so a test reads `TestData.demoEmail` instead of
/// `TestDataStore.dataset('users').record('demo').string('email')` — the
/// second says where the value is stored, the first says what it is.
///
/// Everything here is a getter over the loaded store, so reading a value
/// before [TestDataStore.load] has run throws with that as the message rather
/// than returning a stale constant. `launchMarketApp` does the loading.
///
/// The data still mirrors the deterministic seed in `shared/database`. What
/// changed is who edits it: `patrol_test/data/*.json` is a file QA can open,
/// not Dart that has to be compiled.
class TestData {
  const TestData._();

  static DataSet get users => TestDataStore.dataset('users');
  static DataSet get products => TestDataStore.dataset('products');
  static DataSet get coupons => TestDataStore.dataset('coupons');
  static DataSet get seed => TestDataStore.dataset('seed');

  /// The invalid-credentials cases, keyed by name — one test per key.
  ///
  /// Keyed rather than a list on purpose: each rejection is its own test, and
  /// a test that asks for `invalidLogin('wrongPassword')` still reads its case
  /// when somebody inserts a fourth one above it. A list would hand out rows
  /// by position, which is exactly how an inserted row silently re-points
  /// every test below it.
  static DataSet get invalidLogins => TestDataStore.dataset('invalid_logins');

  /// The invalid-credentials case filed under [key].
  static DataRecord invalidLogin(String key) => invalidLogins.record(key);

  // --- Demo accounts ---
  static DataRecord get demoUser => users.record('demo');
  static DataRecord get secondUser => users.record('second');

  static String get demoEmail => demoUser.string('email');
  static String get demoPassword => demoUser.string('password');
  static String get demoFullName => demoUser.string('fullName');
  static String get secondUserEmail => secondUser.string('email');

  /// Ana's publications in the seed.
  static int get demoUserPublications => demoUser.integer('publications');

  // --- Products ---
  /// Owned by Ana: the detail shows the seller actions, not the buy CTA.
  static DataRecord get ownProduct => products.record('own');
  static String get ownProductId => ownProduct.string('id');
  static String get ownProductName => ownProduct.string('name');

  /// Owned by Bruno, in stock: the detail shows the buy CTA.
  static DataRecord get buyableProduct => products.record('buyable');
  static String get buyableProductId => buyableProduct.string('id');
  static String get buyableProductName => buyableProduct.string('name');
  static double get buyableProductPrice => buyableProduct.number('price');

  /// Owned by Bruno, stock 0: the CTA must be disabled.
  static String get outOfStockProductId =>
      products.record('outOfStock').string('id');

  /// Total number of active products in the seed.
  static int get seedProductCount =>
      seed.record('catalog').integer('activeProducts');

  // --- Coupons ---
  static String get validCoupon => coupons.record('valid').string('code');
  static double get validCouponDiscountPct =>
      coupons.record('valid').number('discountPct');
  static String get expiredCoupon => coupons.record('expired').string('code');
  static String get inactiveCoupon => coupons.record('inactive').string('code');
  static String get unknownCoupon => coupons.record('unknown').string('code');

  /// VAT applied by the cart, mirrors `CartLimits.taxRate`.
  static double get taxRate => seed.record('cart').number('taxRate');
}
