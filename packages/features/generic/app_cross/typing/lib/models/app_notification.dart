import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../enums/notification_type.dart';

/// A row of the `notifications` table.
///
/// [titleKey] and [bodyKey] are i18n keys — the database never stores
/// translated text. [payloadRaw] is a JSON string carrying translation args
/// and an optional deep-link route.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.titleKey,
    required this.bodyKey,
    required this.isRead,
    required this.createdAt,
    this.payloadRaw,
  });

  factory AppNotification.fromMap(Map<String, Object?> map) => AppNotification(
    id: map['id']! as String,
    userId: map['user_id']! as String,
    type: NotificationType.parse(map['type']! as String),
    titleKey: map['title_key']! as String,
    bodyKey: map['body_key']! as String,
    isRead: (map['is_read']! as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    payloadRaw: map['payload'] as String?,
  );

  final String id;
  final String userId;
  final NotificationType type;
  final String titleKey;
  final String bodyKey;
  final bool isRead;
  final DateTime createdAt;
  final String? payloadRaw;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'user_id': userId,
    'type': type.dbValue,
    'title_key': titleKey,
    'body_key': bodyKey,
    'payload': payloadRaw,
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  Map<String, Object?> get _payload {
    if (payloadRaw == null || payloadRaw!.isEmpty) {
      return const <String, Object?>{};
    }
    final Object? decoded = jsonDecode(payloadRaw!);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    return const <String, Object?>{};
  }

  /// Deep-link route carried in the payload, if any.
  String? get route => _payload['route'] as String?;

  /// Translation arguments carried in the payload.
  Map<String, String> get translationArgs {
    final Object? args = _payload['args'];
    if (args is Map<String, Object?>) {
      return args.map(
        (String key, Object? value) => MapEntry<String, String>(key, '$value'),
      );
    }
    return const <String, String>{};
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    userId: userId,
    type: type,
    titleKey: titleKey,
    bodyKey: bodyKey,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    payloadRaw: payloadRaw,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    type,
    titleKey,
    bodyKey,
    isRead,
    createdAt,
  ];
}
