import 'package:nest/domain/models/month_settlement.dart';

/// A single planned expense line inside a month.
class MonthlyPlanEntry {
  const MonthlyPlanEntry({
    required this.id,
    required this.categoryName,
    required this.accountName,
    required this.planned,
    required this.actual,
  });

  final String id;

  /// The expense category name.
  final String categoryName;

  /// The account the expense is charged to.
  final String accountName;

  /// The amount planned for the line, in euros.
  final double planned;

  /// The amount actually spent on the line, in euros.
  final double actual;

  /// `actual - planned`, in euros. Positive means over plan.
  double get diff => actual - planned;

  /// True when the actual spend exceeds the planned amount.
  bool get isOver => diff > 0.005;

  /// The share of the plan consumed, clamped to a 0..1 fraction.
  double get progress {
    if (planned <= 0) {
      return actual > 0 ? 1 : 0;
    }
    return (actual / planned).clamp(0.0, 1.0).toDouble();
  }
}

/// A month of expenses: its planned lines and, once closed, its settlement.
class MonthlyPlan {
  const MonthlyPlan({
    required this.id,
    required this.month,
    required this.closed,
    required this.entries,
    required this.settlement,
  });

  final String id;

  /// The month, formatted `YYYY-MM`.
  final String month;

  /// True once the month has been settled and can no longer be edited.
  final bool closed;

  final List<MonthlyPlanEntry> entries;

  /// The contributions snapshot, present only once the month is closed.
  final MonthSettlement? settlement;

  /// Total planned for the month, in euros.
  double get planned =>
      entries.fold<double>(0, (sum, entry) => sum + entry.planned);

  /// Total actually spent in the month, in euros.
  double get actual =>
      entries.fold<double>(0, (sum, entry) => sum + entry.actual);

  /// `actual - planned`, in euros. Positive means over plan.
  double get diff => actual - planned;

  /// True when the actual spend exceeds the planned amount.
  bool get isOver => diff > 0.005;

  bool get isEmpty => entries.isEmpty;
}
