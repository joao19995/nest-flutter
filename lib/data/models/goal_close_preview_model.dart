import 'package:nest/data/models/goal_month_model.dart';
import 'package:nest/domain/models/goal_close_preview.dart';

/// API-facing representation of a [GoalClosePreview], with JSON mapping.
class GoalClosePreviewModel {
  const GoalClosePreviewModel({
    required this.month,
    required this.availableAmount,
    required this.plannedTotal,
    required this.reservedTotal,
    required this.unallocated,
    required this.adjustedFromTemplate,
    required this.affectedFutureMonths,
    required this.defaulted,
    required this.quotas,
  });

  factory GoalClosePreviewModel.fromJson(Map<String, dynamic> json) {
    final futureMonths = json['affectedFutureMonths'];
    final defaulted = json['defaulted'];
    final quotas = json['quotas'];
    return GoalClosePreviewModel(
      month: json['month'] as String? ?? '',
      availableAmount: (json['availableAmount'] as num?)?.toDouble() ?? 0,
      plannedTotal: (json['plannedTotal'] as num?)?.toDouble() ?? 0,
      reservedTotal: (json['reservedTotal'] as num?)?.toDouble() ?? 0,
      unallocated: (json['unallocated'] as num?)?.toDouble() ?? 0,
      adjustedFromTemplate: json['adjustedFromTemplate'] as bool? ?? false,
      affectedFutureMonths: futureMonths is List
          ? futureMonths.whereType<String>().toList(growable: false)
          : const [],
      defaulted: defaulted is List
          ? defaulted
                .whereType<Map<String, dynamic>>()
                .map(GoalClosePreviewDefaultedModel.fromJson)
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
  final double availableAmount;
  final double plannedTotal;
  final double reservedTotal;
  final double unallocated;
  final bool adjustedFromTemplate;
  final List<String> affectedFutureMonths;
  final List<GoalClosePreviewDefaultedModel> defaulted;
  final List<GoalMonthQuotaModel> quotas;

  GoalClosePreview toDomain() => GoalClosePreview(
    month: month,
    availableAmount: availableAmount,
    plannedTotal: plannedTotal,
    reservedTotal: reservedTotal,
    unallocated: unallocated,
    adjustedFromTemplate: adjustedFromTemplate,
    affectedFutureMonths: affectedFutureMonths,
    defaulted: defaulted.map((item) => item.toDomain()).toList(growable: false),
    quotas: quotas.map((quota) => quota.toDomain()).toList(growable: false),
  );
}

/// API-facing representation of a [GoalClosePreviewDefaulted].
class GoalClosePreviewDefaultedModel {
  const GoalClosePreviewDefaultedModel({
    required this.goalId,
    required this.goalName,
    required this.amount,
  });

  factory GoalClosePreviewDefaultedModel.fromJson(Map<String, dynamic> json) =>
      GoalClosePreviewDefaultedModel(
        goalId: json['goalId'] as String? ?? '',
        goalName: json['goalName'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );

  final String goalId;
  final String goalName;
  final double amount;

  GoalClosePreviewDefaulted toDomain() => GoalClosePreviewDefaulted(
    goalId: goalId,
    goalName: goalName,
    amount: amount,
  );
}
