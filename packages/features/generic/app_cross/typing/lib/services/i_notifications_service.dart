import '../enums/notification_type.dart';
import '../models/app_notification.dart';

/// Notifications contract.
///
/// Other features (authentication, cart, orders) create notifications
/// through this interface; the tray UI lives in the app_cross module.
abstract interface class INotificationsService {
  /// Inserts a notification. [titleKey]/[bodyKey] are i18n keys and
  /// [payload] is an optional JSON string with translation args and a
  /// deep-link route.
  Future<void> create({
    required String userId,
    required NotificationType type,
    required String titleKey,
    required String bodyKey,
    String? payload,
  });

  /// All notifications for [userId], newest first.
  Future<List<AppNotification>> forUser(String userId);

  /// Marks one notification as read and refreshes the unread counter.
  Future<void> markRead(String notificationId);

  /// Marks every notification of [userId] as read.
  Future<void> markAllRead(String userId);

  /// Recomputes the shared unread counter for [userId].
  Future<int> refreshUnreadCount(String userId);
}
