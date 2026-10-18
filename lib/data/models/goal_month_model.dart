import 'package:nest/data/models/goal_year_model.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/goal_year.dart';

/// API-facing representation of the goals month view
/// (`GET /api/goal-plan/{month}`), with JSON mapping.
///
/// The view is self-sufficient: it carries the saved plan (`planId`, null when
/// the month has not been created), the available amount, the allocations and
/// the per-person quotas.
class GoalMonthModel {
  const GoalMonthModel({
    required this.month,
    required this.planId,
    required this.closed,
    required this.availableAmount,
    required this.allocations,
    required this.quotas,
  });

  factory GoalMonthModel.fromJson(Map<String, dynamic> json) {
    final allocations = json['allocations'];
    final quotas = json['quotas'];
    return GoalMonthModel(
      month: json['month'] as String? ?? '',
      planId: json['planId'] as String?,
      closed: json['closed'] as bool? ?? false,
      availableAmount: (json['availableAmount'] as num?)?.toDouble() ?? 0,
      allocations: allocations is List
          ? allocations
                .whereType<Map<String, dynamic>>()
                .map(GoalAllocationModel.fromJson)
                .toList(growable: false)
          : const [],
      quotas: quotas is List
          ? quotas
                .whereType<Map<String, dynamic>>()
                .map(GoalMonthQuotaModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String month;
  final String? planId;
  final bool closed;
  final double availableAmount;
  final List<GoalAllocationModel> allocations;
  final List<GoalMonthQuotaModel> quotas;

  GoalMonthView toDomain() {
    final id = planId;
    return GoalMonthView(
      plan: id == null
          ? null
          : GoalPlan(
              id: id,
              month: month,
              availableAmount: availableAmount,
              closed: closed,
              allocations: allocations
                  .map((allocation) => allocation.toDomain())
                  .toList(growable: false),
            ),
      availableAmount: availableAmount,
      quotas: quotas.map((quota) => quota.toDomain()).toList(growable: false),
    );
  }
}

/// API-facing representation of a [GoalMonthQuotaPart], with JSON mapping.
class GoalMonthQuotaPartModel {
  const GoalMonthQuotaPartModel({
    required this.goalId,
    required this.name,
    required this.amount,
  });

  factory GoalMonthQuotaPartModel.fromJson(Map<String, dynamic> json) =>
      GoalMonthQuotaPartModel(
        goalId: json['goalId'] as String,
        name: json['name'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
      );

  final String goalId;
  final String name;
  final double amount;

  GoalMonthQuotaPart toDomain() =>
      GoalMonthQuotaPart(goalId: goalId, name: name, amount: amount);
}

/// API-facing representation of a [GoalMonthQuota], with JSON mapping.
class GoalMonthQuotaModel {
  const GoalMonthQuotaModel({
    required this.personId,
    required this.name,
    required this.earning,
    required this.share,
    required this.amount,
    required this.parts,
  });

  factory GoalMonthQuotaModel.fromJson(Map<String, dynamic> json) {
    final parts = json['parts'];
    return GoalMonthQuotaModel(
      personId: json['personId'] as String,
      name: json['name'] as String? ?? '',
      earning: (json['earning'] as num?)?.toDouble() ?? 0,
      share: (json['share'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      parts: parts is List
          ? parts
                .whereType<Map<String, dynamic>>()
                .map(GoalMonthQuotaPartModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String personId;
  final String name;
  final double earning;
  final double share;
  final double amount;
  final List<GoalMonthQuotaPartModel> parts;

  GoalMonthQuota toDomain() => GoalMonthQuota(
    personId: personId,
    name: name,
    earning: earning,
    share: share,
    amount: amount,
    parts: parts.map((part) => part.toDomain()).toList(growable: false),
  );
}
