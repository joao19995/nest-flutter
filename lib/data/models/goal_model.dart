import 'package:nest/domain/models/goal.dart';

/// API-facing representation of a [Goal], with JSON mapping.
class GoalModel {
  const GoalModel({
    required this.id,
    required this.name,
    required this.active,
    this.iconKey,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
    id: json['id'] as String,
    name: json['name'] as String,
    active: json['active'] as bool,
    iconKey: json['iconKey'] as String?,
  );

  final String id;
  final String name;
  final bool active;
  final String? iconKey;

  Goal toDomain() => Goal(id: id, name: name, active: active, iconKey: iconKey);
}
