import 'package:equatable/equatable.dart';

/// A row of the `reviews` table plus the reviewer's display name.
class Review extends Equatable {
  const Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    required this.createdAt,
    this.userName = '',
    this.comment,
  });

  factory Review.fromMap(Map<String, Object?> map) => Review(
    id: map['id']! as String,
    productId: map['product_id']! as String,
    userId: map['user_id']! as String,
    rating: map['rating']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    userName: (map['user_name'] as String?) ?? '',
    comment: map['comment'] as String?,
  );

  final String id;
  final String productId;
  final String userId;
  final int rating;
  final DateTime createdAt;
  final String userName;
  final String? comment;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'product_id': productId,
    'user_id': userId,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  @override
  List<Object?> get props => <Object?>[
    id,
    productId,
    userId,
    rating,
    createdAt,
    userName,
    comment,
  ];
}
