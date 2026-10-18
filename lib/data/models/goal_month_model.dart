import 'package:nest/data/models/goal_year_model.dart';
import 'package:nest/domain/models/goal_year.dart';

/// API-facing representation of the single-month goal view
/// (`GET /api/goal-plan/{month}`), with JSON mapping.
///
/// The month endpoint is self-sufficient: it carries the plan's [planId]
/// directly, so the month screen no longer has to load the whole year.
/// [planId] is null when the month has not been created yet, in which case
/// [toDomain] returns null.
class GoalMonthModel {
  const GoalMonthModel({
    required this.month,
    required this.planId,
    required this.availableAmount,
    required this.closed,
    required this.allocations,
  });

  factory GoalMonthModel.fromJson(Map<String, dynamic> json) {
    final allocations = json['allocations'];
    return GoalMonthModel(
      month: json['month'] as String? ?? '',
      planId: json['planId'] as String?,
      availableAmount: (json['availableAmount'] as num?)?.toDouble() ?? 0,
      closed: json['closed'] as bool? ?? false,
      allocations: allocations is List
          ? allocations
                .whereType<Map<String, dynamic>>()
                .map(GoalAllocationModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  /// The month, formatted `YYYY-MM`.
  final String month;

  /// The saved plan's id, or null when the month does not exist yet.
  final String? planId;

  /// The amount available to allocate in the month, in euros.
  final double availableAmount;

  final bool closed;
  final List<GoalAllocationModel> allocations;

  /// The saved plan, or null when the month has not been created.
  GoalPlan? toDomain() {
    final id = planId;
    if (id == null) {
      return null;
    }
    return GoalPlan(
      id: id,
      month: month,
      availableAmount: availableAmount,
      closed: closed,
      allocations: allocations
          .map((allocation) => allocation.toDomain())
          .toList(growable: false),
    );
  }
}
