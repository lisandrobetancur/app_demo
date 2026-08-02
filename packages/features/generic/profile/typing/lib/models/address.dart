import 'package:equatable/equatable.dart';

/// A row of the `addresses` table.
class Address extends Equatable {
  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.line1,
    required this.city,
    required this.state,
    required this.isDefault,
    this.notes,
  });

  factory Address.fromMap(Map<String, Object?> map) => Address(
    id: map['id']! as String,
    userId: map['user_id']! as String,
    label: map['label']! as String,
    line1: map['line1']! as String,
    city: map['city']! as String,
    state: map['state']! as String,
    isDefault: (map['is_default']! as int) == 1,
    notes: map['notes'] as String?,
  );

  final String id;
  final String userId;
  final String label;
  final String line1;
  final String city;
  final String state;
  final bool isDefault;
  final String? notes;

  /// One-line display form.
  String get display => '$line1, $city, $state';

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'user_id': userId,
    'label': label,
    'line1': line1,
    'city': city,
    'state': state,
    'notes': notes,
    'is_default': isDefault ? 1 : 0,
  };

  Address copyWith({
    String? label,
    String? line1,
    String? city,
    String? state,
    String? notes,
    bool? isDefault,
  }) => Address(
    id: id,
    userId: userId,
    label: label ?? this.label,
    line1: line1 ?? this.line1,
    city: city ?? this.city,
    state: state ?? this.state,
    isDefault: isDefault ?? this.isDefault,
    notes: notes ?? this.notes,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    label,
    line1,
    city,
    state,
    isDefault,
    notes,
  ];
}
