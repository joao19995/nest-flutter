import 'package:nest/domain/models/goal_year_summary.dart';

/// API-facing representation of a [GoalYearSummary], with JSON mapping.
class GoalYearSummaryModel {
  const GoalYearSummaryModel({required this.year, required this.rows});

  factory GoalYearSummaryModel.fromJson(Map<String, dynamic> json) {
    final matrix = json['matrix'];
    final rows = matrix is Map<String, dynamic> ? matrix['rows'] : null;
    return GoalYearSummaryModel(
      year: (json['year'] as num?)?.toInt() ?? 0,
      rows: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(GoalYearSummaryRowModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final int year;
  final List<GoalYearSummaryRowModel> rows;

  GoalYearSummary toDomain() => GoalYearSummary(
    year: year,
    rows: rows.map((row) => row.toDomain()).toList(growable: false),
  );
}

/// API-facing representation of a [GoalYearSummaryRow].
class GoalYearSummaryRowModel {
  const GoalYearSummaryRowModel({
    required this.goalId,
    required this.projection,
  });

  factory GoalYearSummaryRowModel.fromJson(Map<String, dynamic> json) {
    final projection = json['projection'];
    return GoalYearSummaryRowModel(
      goalId: json['goalId'] as String? ?? '',
      projection: projection is Map<String, dynamic>
          ? GoalCompletionProjectionModel.fromJson(projection)
          : null,
    );
  }

  final String goalId;
  final GoalCompletionProjectionModel? projection;

  GoalYearSummaryRow toDomain() =>
      GoalYearSummaryRow(goalId: goalId, projection: projection?.toDomain());
}

/// API-facing representation of a [GoalCompletionProjection].
class GoalCompletionProjectionModel {
  const GoalCompletionProjectionModel({
    required this.asOfMonth,
    required this.pacePerMonth,
    required this.remainingMonths,
    required this.projectedAmount,
    required this.projectedMonth,
    required this.reachesBudget,
    required this.completionMonth,
  });

  factory GoalCompletionProjectionModel.fromJson(Map<String, dynamic> json) =>
      GoalCompletionProjectionModel(
        asOfMonth: json['asOfMonth'] as String? ?? '',
        pacePerMonth: (json['pacePerMonth'] as num?)?.toDouble() ?? 0,
        remainingMonths: (json['remainingMonths'] as num?)?.toInt() ?? 0,
        projectedAmount: (json['projectedAmount'] as num?)?.toDouble() ?? 0,
        projectedMonth: json['projectedMonth'] as String? ?? '',
        reachesBudget: json['reachesBudget'] as bool? ?? false,
        completionMonth: json['completionMonth'] as String?,
      );

  final String asOfMonth;
  final double pacePerMonth;
  final int remainingMonths;
  final double projectedAmount;
  final String projectedMonth;
  final bool reachesBudget;
  final String? completionMonth;

  GoalCompletionProjection toDomain() => GoalCompletionProjection(
    asOfMonth: asOfMonth,
    pacePerMonth: pacePerMonth,
    remainingMonths: remainingMonths,
    projectedAmount: projectedAmount,
    projectedMonth: projectedMonth,
    reachesBudget: reachesBudget,
    completionMonth: completionMonth,
  );
}
