import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enums/display_currency.dart';
import '../services/i_notifications_service.dart';

/// Notifications contract provider; the app_cross module overrides it.
final Provider<INotificationsService> notificationsServiceProvider =
    Provider<INotificationsService>(
      (Ref ref) => throw UnimplementedError('notificationsServiceProvider'),
    );

/// Theme mode chosen in settings; persisted by the app_cross module and
/// watched by the shell's `MaterialApp`.
final StateProvider<ThemeMode> themeModeProvider = StateProvider<ThemeMode>(
  (Ref ref) => ThemeMode.system,
);

/// Display currency chosen in settings; watched by every price render.
final StateProvider<DisplayCurrency> displayCurrencyProvider =
    StateProvider<DisplayCurrency>((Ref ref) => DisplayCurrency.cop);

/// Shared unread-notifications counter (dashboard badge, tray). Owned and
/// refreshed by the app_cross module's notifications service.
final StateProvider<int> unreadNotificationsCountProvider = StateProvider<int>(
  (Ref ref) => 0,
);
