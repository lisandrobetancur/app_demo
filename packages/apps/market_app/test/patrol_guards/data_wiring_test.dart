import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

import '../../patrol_test/support/test_data.dart';

/// The data files this app actually ships to its tests.
///
/// Under `test/` and not with the scenarios it protects, which looks wrong
/// until you try it: `patrol test` compiles every `*_test.dart` under
/// `patrol_test/` into the native bundle, so this would be run on a device it
/// has no use for — and `flutter test` only looks in `test/`, so moving it
/// would leave the guard silently unrun. A guard that stops guarding without
/// turning anything red is the failure this file exists to prevent, so it
/// stays here, in a folder named after what it watches.
///
/// The kit's own tests prove the loader; this one proves the wiring, which is
/// the part that breaks silently. Three things can go wrong without anyone
/// noticing until an E2E run fails for what looks like a product reason:
///
///  * the folder is not declared under `flutter: assets:`, so `rootBundle`
///    finds nothing;
///  * the index names a file that was renamed or never committed;
///  * a field the façade reads was spelled differently in the JSON.
///
/// All three surface here, in a suite that needs no browser and no device.
void main() {
  // `rootBundle` reads through the binding, so it has to exist first. In a
  // `testWidgets` body this is implicit; a plain `test` has to ask.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => TestDataStore.load());
  tearDownAll(TestDataStore.reset);

  test('the index loads every data set it lists', () {
    for (final String name in <String>[
      'users',
      'products',
      'coupons',
      'seed',
      'invalid_logins',
    ]) {
      expect(
        TestDataStore.dataset(name).length,
        greaterThan(0),
        reason: 'data set "$name" came out empty',
      );
    }
  });

  test('every value the façade exposes is readable', () {
    // Reading them all is the point: each getter is a field name in a JSON
    // file, and a typo in either half only shows up when something reads it.
    expect(TestData.demoEmail, 'ana@market.demo');
    expect(TestData.demoPassword, isNotEmpty);
    expect(TestData.demoFullName, 'Ana Marín');
    expect(TestData.secondUserEmail, 'bruno@market.demo');
    expect(TestData.demoUserPublications, greaterThan(0));

    expect(TestData.ownProductId, startsWith('product_'));
    expect(TestData.ownProductName, isNotEmpty);
    expect(TestData.buyableProductId, startsWith('product_'));
    expect(TestData.buyableProductName, isNotEmpty);
    expect(TestData.buyableProductPrice, greaterThan(0));
    expect(TestData.outOfStockProductId, startsWith('product_'));
    expect(TestData.seedProductCount, greaterThan(0));

    expect(TestData.validCoupon, isNotEmpty);
    expect(TestData.validCouponDiscountPct, greaterThan(0));
    expect(TestData.expiredCoupon, isNotEmpty);
    expect(TestData.inactiveCoupon, isNotEmpty);
    expect(TestData.unknownCoupon, isNotEmpty);
    expect(TestData.taxRate, greaterThan(0));
  });

  test('the data still mirrors the seed in shared/database', () {
    // The JSON is a copy of what `Seed` writes. A copy that drifts is worse
    // than no copy, so the numbers the suite asserts on are pinned here.
    expect(TestData.demoUserPublications, 5);
    expect(TestData.seedProductCount, 15);
    expect(TestData.taxRate, 0.19);
    expect(TestData.buyableProductPrice, 62500000);
    expect(TestData.validCouponDiscountPct, 10);
  });

  test('every invalid-login record carries the fields the test reads', () {
    // The keys are load-bearing: each login test asks for its case by name,
    // so a renamed key breaks here, headless, instead of as a broken E2E run.
    expect(
      TestData.invalidLogins.keys,
      containsAll(<String>['wrongPassword', 'unknownEmail', 'foreignPassword']),
    );

    for (final String key in TestData.invalidLogins.keys) {
      final DataRecord row = TestData.invalidLogin(key);
      expect(row.string('case'), isNotEmpty);
      expect(row.string('email'), contains('@'));
      expect(row.string('password'), isNotEmpty);
    }
  });
}
