import 'package:nest/domain/models/goal_month_view.dart';

/// A goal that will assume its planned amount when the month is closed.
class GoalClosePreviewDefaulted {
  const GoalClosePreviewDefaulted({
    required this.goalId,
    required this.goalName,
    required this.amount,
  });

  final String goalId;
  final String goalName;

  /// The planned amount that will be reserved, in euros.
  final double amount;
}

/// What closing a goals month would do, computed without writing anything.
class GoalClosePreview {
  const GoalClosePreview({
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

  final String month;

  /// The current available amount used by the close, in euros.
  final double availableAmount;

  /// The planned total after the optional template adjustment, in euros.
  final double plannedTotal;

  /// The total that will be stored as reserved by the atomic close, in euros.
  final double reservedTotal;

  /// What is left to allocate: [availableAmount] minus [plannedTotal].
  final double unallocated;

  /// Whether closing would redistribute the month from the template.
  final bool adjustedFromTemplate;

  /// Future open months that the adjustment would recalculate or create.
  final List<String> affectedFutureMonths;

  /// The goals that will assume their planned amount.
  final List<GoalClosePreviewDefaulted> defaulted;

  /// Who transfers what, computed over the reserved total the close stores.
  final List<GoalMonthQuota> quotas;
}
