import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utilities/utilities.dart';

import 'config/app_config.dart';
import 'di/app_overrides.dart';
import 'i18n/market_translations_loader.dart';
import 'market_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Real paths instead of hash URLs on the web, so `/catalog/detail/<id>`
  // is a working deep link there too. No-op on mobile.
  configureUrlStrategy();
  await EasyLocalization.ensureInitialized();
  AppDurations.fastMode = AppConfig.fastAnimations;
  runApp(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('es'), Locale('en')],
      fallbackLocale: const Locale('es'),
      startLocale: const Locale('es'),
      // Translations live in code (one map per feature); the path is a
      // placeholder required by the API and never read.
      path: 'i18n',
      assetLoader: const MarketTranslationsLoader(),
      child: ProviderScope(overrides: appOverrides, child: const MarketApp()),
    ),
  );
}
