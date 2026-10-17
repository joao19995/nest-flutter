import 'package:nest/domain/models/goal_year.dart';

/// API-facing representation of a [GoalYear], with JSON mapping.
class GoalYearModel {
  const GoalYearModel({
    required this.year,
    required this.annualTotal,
    required this.plans,
    required this.months,
  });

  factory GoalYearModel.fromJson(Map<String, dynamic> json) {
    final plans = json['plans'];
    final funding = json['funding'];
    final fundingMap = funding is Map<String, dynamic>
        ? funding
        : const <String, dynamic>{};
    final months = fundingMap['months'];
    return GoalYearModel(
      year: (fundingMap['year'] as num?)?.toInt() ?? 0,
      annualTotal: (fundingMap['annualTotal'] as num?)?.toDouble() ?? 0,
      plans: plans is List
          ? plans
                .whereType<Map<String, dynamic>>()
                .map(GoalPlanModel.fromJson)
                .toList(growable: false)
          : const [],
      months: months is List
          ? months
                .whereType<Map<String, dynamic>>()
                .map(MonthFundingModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final int year;
  final double annualTotal;
  final List<GoalPlanModel> plans;
  final List<MonthFundingModel> months;

  GoalYear toDomain() => GoalYear(
    year: year,
    annualTotal: annualTotal,
    plans: plans.map((plan) => plan.toDomain()).toList(growable: false),
    months: months.map((month) => month.toDomain()).toList(growable: false),
  );
}

/// API-facing representation of a [GoalPlan], with JSON mapping.
class GoalPlanModel {
  const GoalPlanModel({
    required this.id,
    required this.month,
    required this.availableAmount,
    required this.closed,
    required this.allocations,
  });

  factory GoalPlanModel.fromJson(Map<String, dynamic> json) {
    final allocations = json['allocations'];
    return GoalPlanModel(
      id: json['id'] as String,
      month: json['month'] as String,
      availableAmount: (json['availableAmount'] as num).toDouble(),
      closed: json['closed'] as bool,
      allocations: allocations is List
          ? allocations
                .whereType<Map<String, dynamic>>()
                .map(GoalAllocationModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String month;
  final double availableAmount;
  final bool closed;
  final List<GoalAllocationModel> allocations;

  GoalPlan toDomain() => GoalPlan(
    id: id,
    month: month,
    availableAmount: availableAmount,
    closed: closed,
    allocations: allocations
        .map((allocation) => allocation.toDomain())
        .toList(growable: false),
  );
}

/// API-facing representation of a [GoalAllocation], with JSON mapping.
class GoalAllocationModel {
  const GoalAllocationModel({
    required this.goalId,
    required this.goalName,
    required this.planned,
    required this.actual,
  });

  factory GoalAllocationModel.fromJson(Map<String, dynamic> json) =>
      GoalAllocationModel(
        goalId: json['goalId'] as String,
        goalName: json['goalName'] as String,
        planned: (json['planned'] as num).toDouble(),
        actual: (json['actual'] as num).toDouble(),
      );

  final String goalId;
  final String goalName;
  final double planned;
  final double actual;

  GoalAllocation toDomain() => GoalAllocation(
    goalId: goalId,
    goalName: goalName,
    planned: planned,
    actual: actual,
  );
}

/// API-facing representation of a [MonthFunding], with JSON mapping.
class MonthFundingModel {
  const MonthFundingModel({required this.month, required this.available});

  factory MonthFundingModel.fromJson(Map<String, dynamic> json) =>
      MonthFundingModel(
        month: json['month'] as String,
        available: (json['available'] as num).toDouble(),
      );

  final String month;
  final double available;

  MonthFunding toDomain() => MonthFunding(month: month, available: available);
}
