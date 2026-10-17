import 'package:nest/domain/models/person.dart';

/// API-facing representation of a [Person], with JSON mapping.
class PersonModel {
  const PersonModel({
    required this.id,
    required this.name,
    required this.dailySpendingPercentage,
    required this.emergencyFundMonths,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) => PersonModel(
    id: json['id'] as String,
    name: json['name'] as String,
    dailySpendingPercentage: (json['dailySpendingPercentage'] as num)
        .toDouble(),
    emergencyFundMonths: (json['emergencyFundMonths'] as num).toInt(),
  );

  final String id;
  final String name;
  final double dailySpendingPercentage;
  final int emergencyFundMonths;

  Person toDomain() => Person(
    id: id,
    name: name,
    dailySpendingPercentage: dailySpendingPercentage,
    emergencyFundMonths: emergencyFundMonths,
  );
}
