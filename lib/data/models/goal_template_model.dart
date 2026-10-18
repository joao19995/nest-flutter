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
      annualTotal: (json['annualTotal'] as num?)?.toDouble() ?? 0,
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
    required this.timeline,
    required this.priority,
    required this.notes,
  });

  factory GoalTemplateEntryModel.fromJson(Map<String, dynamic> json) =>
      GoalTemplateEntryModel(
        goalId: json['goalId'] as String,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        budget: (json['budget'] as num?)?.toDouble() ?? 0,
        timeline: _timelineFromJson(json['timeline'] as String? ?? 'ANUAL'),
        priority: _priorityFromJson(
          json['priority'] as String? ?? 'NICE_TO_HAVE',
        ),
        notes: json['notes'] as String? ?? '',
      );

  final String goalId;
  final double percentage;
  final double budget;
  final GoalTimeline timeline;
  final GoalPriority priority;
  final String notes;

  GoalTemplateEntry toDomain() => GoalTemplateEntry(
    goalId: goalId,
    percentage: percentage,
    budget: budget,
    timeline: timeline,
    priority: priority,
    notes: notes,
  );

  static GoalTimeline _timelineFromJson(String value) => switch (value) {
    'T1' => GoalTimeline.t1,
    'T2' => GoalTimeline.t2,
    'T3' => GoalTimeline.t3,
    'T4' => GoalTimeline.t4,
    _ => GoalTimeline.annual,
  };

  static GoalPriority _priorityFromJson(String value) => switch (value) {
    'GRANDE' => GoalPriority.grande,
    'PEQUENO' => GoalPriority.pequeno,
    _ => GoalPriority.niceToHave,
  };
}
