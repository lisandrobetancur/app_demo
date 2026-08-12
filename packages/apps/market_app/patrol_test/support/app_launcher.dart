import 'package:app_cross_constants/app_cross_constants.dart';
import 'package:database/database.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_app/di/app_overrides.dart';
import 'package:market_app/i18n/market_translations_loader.dart';
import 'package:market_app/market_app.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real application inside a Patrol test.
///
/// This mirrors `lib/main.dart` but pumps the widget tree instead of calling
/// `runApp`, and it forces the three things a test needs to be repeatable:
///
///  * **its own database** — a per-run file name, wiped before the first
///    frame, so leftovers from a previous run (IndexedDB on web survives
///    between sessions) never leak into a test;
///  * **clean preferences** — no remembered session and, by default, the
///    onboarding flag already set, so tests land on login instead of
///    replaying the intro;
///  * **zero-length animations** — `AppDurations.fastMode`, the same switch
///    the `FAST_ANIMATIONS` dart-define flips, so the UI reaches steady state
///    immediately and `pumpAndSettle` never waits on a shimmer.
Future<void> launchMarketApp(
  PatrolIntegrationTester $, {
  SeedMode seedMode = SeedMode.demo,
  bool onboardingSeen = true,
}) async {
  // Real preferences, cleared through the public API: on the web they are
  // backed by local storage and survive between runs, so a stale "remember
  // me" session would otherwise skip the login screen.
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.clear();
  if (onboardingSeen) {
    await preferences.setBool(AppCrossLimits.onboardingSeenPrefKey, true);
  }

  await EasyLocalization.ensureInitialized();
  AppDurations.fastMode = true;

  final MarketDatabase database = MarketDatabase(
    seedMode: seedMode,
    fileName: 'market_patrol_test.db',
  );
  // The seed only runs inside `onCreate`, and on the web IndexedDB keeps the
  // file between runs — so the state is forced explicitly instead of trusting
  // a fresh creation.
  await database.db;
  if (seedMode.isDemo) {
    await database.resetToSeed();
  } else {
    await database.wipe();
  }

  await $.pumpWidgetAndSettle(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('es'), Locale('en')],
      fallbackLocale: const Locale('es'),
      startLocale: const Locale('es'),
      path: 'i18n',
      assetLoader: const MarketTranslationsLoader(),
      child: ProviderScope(
        overrides: <Override>[
          ...appOverrides,
          databaseProvider.overrideWithValue(database),
        ],
        child: const MarketApp(),
      ),
    ),
  );
}
