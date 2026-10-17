import 'package:nest/domain/models/goal.dart';

/// API-facing representation of a [Goal], with JSON mapping.
class GoalModel {
  const GoalModel({required this.id, required this.name, required this.active});

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
    id: json['id'] as String,
    name: json['name'] as String,
    active: json['active'] as bool,
  );

  final String id;
  final String name;
  final bool active;

  Goal toDomain() => Goal(id: id, name: name, active: active);
}
