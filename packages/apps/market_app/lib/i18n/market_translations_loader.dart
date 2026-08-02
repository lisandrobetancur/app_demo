import 'dart:ui';

import 'package:app_cross/app_cross.dart';
import 'package:authentication/authentication.dart';
import 'package:cart/cart.dart';
import 'package:catalog/catalog.dart';
import 'package:dashboard/dashboard.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:orders/orders.dart';
import 'package:profile/profile.dart';

import 'shell_languages.dart';

/// Merges every feature's in-code translation map into the single map
/// easy_localization consumes per locale. No JSON assets involved: each
/// module owns its strings in `ui/languages.dart`.
class MarketTranslationsLoader extends AssetLoader {
  const MarketTranslationsLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool isEnglish = locale.languageCode == 'en';
    final List<Map<String, dynamic>> maps = isEnglish
        ? <Map<String, dynamic>>[
            AppCrossLanguages.en,
            AuthenticationLanguages.en,
            CartLanguages.en,
            CatalogLanguages.en,
            DashboardLanguages.en,
            OrdersLanguages.en,
            ProfileLanguages.en,
            ShellLanguages.en,
          ]
        : <Map<String, dynamic>>[
            AppCrossLanguages.es,
            AuthenticationLanguages.es,
            CartLanguages.es,
            CatalogLanguages.es,
            DashboardLanguages.es,
            OrdersLanguages.es,
            ProfileLanguages.es,
            ShellLanguages.es,
          ];
    final Map<String, dynamic> merged = <String, dynamic>{};
    for (final Map<String, dynamic> map in maps) {
      merged.addAll(map);
    }
    return merged;
  }
}
