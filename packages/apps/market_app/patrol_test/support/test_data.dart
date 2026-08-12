/// Fixed data the tests rely on.
///
/// Everything here mirrors the deterministic seed in `shared/database`, so a
/// test never has to guess an id, a price or a coupon code. If the seed
/// changes, this file is the single place to update.
class TestData {
  const TestData._();

  // --- Demo accounts (see `Seed` in shared/database) ---
  static const String demoEmail = 'ana@market.demo';
  static const String demoPassword = 'Demo1234';
  static const String demoFullName = 'Ana Marín';

  static const String secondUserEmail = 'bruno@market.demo';

  /// Ana owns 5 publications in the seed.
  static const int demoUserPublications = 5;

  // --- Products ---
  /// Owned by Ana: the detail shows the seller actions, not the buy CTA.
  static const String ownProductId = 'product_car_001';
  static const String ownProductName = 'Sedán compacto 2022';

  /// Owned by Bruno, stock 2: the detail shows the buy CTA.
  static const String buyableProductId = 'product_car_002';
  static const String buyableProductName = 'SUV familiar 2024';
  static const double buyableProductPrice = 62500000;

  /// Owned by Bruno, stock 0: the CTA must be disabled.
  static const String outOfStockProductId = 'product_scooter_003';

  /// Total number of active products in the seed.
  static const int seedProductCount = 15;

  // --- Coupons ---
  static const String validCoupon = 'DEMO10';
  static const double validCouponDiscountPct = 10;
  static const String expiredCoupon = 'PAST20';
  static const String inactiveCoupon = 'FROZEN15';
  static const String unknownCoupon = 'NOPE404';

  /// VAT applied by the cart, mirrors `CartLimits.taxRate`.
  static const double taxRate = 0.19;
}
