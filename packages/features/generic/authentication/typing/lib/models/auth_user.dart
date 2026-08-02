import 'package:equatable/equatable.dart';

/// A row of the `users` table without credential material.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
    this.phone,
    this.avatarPath,
  });

  factory AuthUser.fromMap(Map<String, Object?> map) => AuthUser(
    id: map['id']! as String,
    fullName: map['full_name']! as String,
    email: map['email']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    phone: map['phone'] as String?,
    avatarPath: map['avatar_path'] as String?,
  );

  final String id;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final String? phone;

  /// Image reference (file path on mobile, data URI on web).
  final String? avatarPath;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'avatar_path': avatarPath,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  AuthUser copyWith({String? fullName, String? phone, String? avatarPath}) =>
      AuthUser(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        createdAt: createdAt,
        phone: phone ?? this.phone,
        avatarPath: avatarPath ?? this.avatarPath,
      );

  @override
  List<Object?> get props => <Object?>[
    id,
    fullName,
    email,
    createdAt,
    phone,
    avatarPath,
  ];
}
