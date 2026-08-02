/// Public contract of the app_cross feature.
///
/// Cross-cutting concerns every other feature may depend on: notifications,
/// app settings signals (theme, display currency) and the boot/session
/// bridge. Implementations live in the private `app_cross` module.
library;

export 'package:app_cross_constants/app_cross_constants.dart'
    show AppCrossRoutes;

export 'enums/display_currency.dart';
export 'enums/notification_type.dart';
export 'models/app_notification.dart';
export 'provider/provider.dart';
export 'services/i_notifications_service.dart';
