import 'package:nest/domain/models/category.dart';

/// API-facing representation of a [Category], with JSON mapping.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
    this.iconKey,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    type: _typeFromJson(json['type'] as String),
    active: json['active'] as bool? ?? true,
    iconKey: json['iconKey'] as String?,
  );

  final String id;
  final String name;
  final CategoryType type;
  final bool active;
  final String? iconKey;

  Category toDomain() => Category(
    id: id,
    name: name,
    type: type,
    active: active,
    iconKey: iconKey,
  );

  static CategoryType _typeFromJson(String value) => switch (value) {
    'FIXED' => CategoryType.fixed,
    'VARIABLE' => CategoryType.variable,
    _ => CategoryType.variable,
  };
}
