import 'package:nest/domain/models/person_income.dart';

/// API-facing representation of a [PersonIncome], with JSON mapping.
class PersonIncomeModel {
  const PersonIncomeModel({
    required this.id,
    required this.personId,
    required this.amount,
    required this.validFrom,
  });

  factory PersonIncomeModel.fromJson(Map<String, dynamic> json) =>
      PersonIncomeModel(
        id: json['id'] as String,
        personId: json['personId'] as String,
        amount: (json['amount'] as num).toDouble(),
        validFrom: json['validFrom'] as String,
      );

  final String id;
  final String personId;
  final double amount;
  final String validFrom;

  PersonIncome toDomain() => PersonIncome(
    id: id,
    personId: personId,
    amount: amount,
    validFrom: validFrom,
  );
}

/// API-facing representation of a [PersonIncomeRaise], with JSON mapping.
class PersonIncomeRaiseModel {
  const PersonIncomeRaiseModel({
    required this.year,
    required this.extra,
    required this.annualTotal,
    required this.validFromMonth,
  });

  factory PersonIncomeRaiseModel.fromJson(Map<String, dynamic> json) =>
      PersonIncomeRaiseModel(
        year: (json['year'] as num).toInt(),
        extra: (json['extra'] as num).toDouble(),
        annualTotal: (json['annualTotal'] as num).toDouble(),
        validFromMonth: json['validFromMonth'] as String,
      );

  final int year;
  final double extra;
  final double annualTotal;
  final String validFromMonth;

  PersonIncomeRaise toDomain() => PersonIncomeRaise(
    year: year,
    extra: extra,
    annualTotal: annualTotal,
    validFromMonth: validFromMonth,
  );
}
