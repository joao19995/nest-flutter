import 'package:nest/domain/models/goal_template.dart';

/// API-facing representation of a [GoalTemplate], with JSON mapping.
class GoalTemplateModel {
  const GoalTemplateModel({
    required this.id,
    required this.validFrom,
    required this.annualTotal,
    required this.entries,
  });

  factory GoalTemplateModel.fromJson(Map<String, dynamic> json) {
    final entries = json['entries'];
    return GoalTemplateModel(
      id: json['id'] as String,
      validFrom: json['validFrom'] as String,
      annualTotal: (json['annualTotal'] as num).toDouble(),
      entries: entries is List
          ? entries
                .whereType<Map<String, dynamic>>()
                .map(GoalTemplateEntryModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String validFrom;
  final double annualTotal;
  final List<GoalTemplateEntryModel> entries;

  GoalTemplate toDomain() => GoalTemplate(
    id: id,
    validFrom: validFrom,
    annualTotal: annualTotal,
    entries: entries.map((entry) => entry.toDomain()).toList(growable: false),
  );
}

/// API-facing representation of a [GoalTemplateEntry], with JSON mapping.
class GoalTemplateEntryModel {
  const GoalTemplateEntryModel({
    required this.goalId,
    required this.percentage,
    required this.budget,
  });

  factory GoalTemplateEntryModel.fromJson(Map<String, dynamic> json) =>
      GoalTemplateEntryModel(
        goalId: json['goalId'] as String,
        percentage: (json['percentage'] as num).toDouble(),
        budget: (json['budget'] as num).toDouble(),
      );

  final String goalId;
  final double percentage;
  final double budget;

  GoalTemplateEntry toDomain() =>
      GoalTemplateEntry(goalId: goalId, percentage: percentage, budget: budget);
}
