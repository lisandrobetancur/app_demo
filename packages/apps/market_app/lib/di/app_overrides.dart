import 'package:app_cross/app_cross.dart';
import 'package:authentication/authentication.dart';
import 'package:cart/cart.dart';
import 'package:catalog/catalog.dart';
import 'package:dashboard/dashboard.dart';
import 'package:database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navigator/navigator.dart';
import 'package:orders/orders.dart';
import 'package:profile/profile.dart';
import 'package:typing/typing.dart';
import 'package:utilities/utilities.dart';

import '../config/app_config.dart';
import '../router/app_router.dart';

/// Dependency injection of the whole app.
///
/// The shell only *wires*: shared infrastructure gets concrete
/// implementations here, and every feature contributes the override that
/// binds its public contract (declared in `typing/`) to its private module.
final List<Override> appOverrides = <Override>[
  // Shared infrastructure.
  databaseProvider.overrideWith(
    (Ref ref) => MarketDatabase(seedMode: AppConfig.seedMode),
  ),
  idGeneratorProvider.overrideWith((Ref ref) => const UuidIdGenerator()),
  imageStorageProvider.overrideWith((Ref ref) => createImageStorage()),
  goRouterProvider.overrideWith(buildAppRouter),
  // Feature contracts → module implementations.
  authenticationServiceProviderOverride,
  cartServiceProviderOverride,
  catalogServiceProviderOverride,
  dashboardServiceProviderOverride,
  notificationsServiceProviderOverride,
  ordersServiceProviderOverride,
  profileServiceProviderOverride,
];
