import 'package:equatable/equatable.dart';

/// A row of the `categories` table.
class Category extends Equatable {
  const Category({required this.id, required this.code, required this.name});

  factory Category.fromMap(Map<String, Object?> map) => Category(
    id: map['id']! as String,
    code: map['code']! as String,
    name: map['name']! as String,
  );

  final String id;

  /// Stable code (CAR, MOTORCYCLE, SCOOTER, BICYCLE, TRUCK) used for icons
  /// and translations; [name] is only the seed fallback.
  final String code;

  final String name;

  /// Translation key of the display label.
  String get labelKey => 'catalog.categories.${code.toLowerCase()}';

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'code': code,
    'name': name,
  };

  @override
  List<Object?> get props => <Object?>[id, code, name];
}
