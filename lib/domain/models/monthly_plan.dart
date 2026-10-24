import 'package:nest/domain/models/category.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/domain/models/month_settlement.dart';

/// A single planned expense line inside a month.
class MonthlyPlanEntry {
  const MonthlyPlanEntry({
    required this.id,
    required this.categoryName,
    required this.type,
    required this.accountName,
    required this.planned,
    required this.actual,
    required this.actualSet,
    this.categoryIconKey,
  });

  final String id;

  /// The expense category name.
  final String categoryName;

  /// The category's stored semantic icon key, when it has one.
  final String? categoryIconKey;

  /// Whether the category is fixed or variable.
  final CategoryType type;

  /// The account the expense is charged to.
  final String accountName;

  /// The amount planned for the line, in euros.
  final double planned;

  /// The amount actually spent on the line, in euros.
  final double actual;

  /// Whether [actual] has been entered. A `0` may mean "not filled in yet".
  final bool actualSet;
}

/// A month of expenses: its planned lines, the server-derived summary and,
/// once closed, its settlement.
///
/// The month totals, progress and over/under flag are computed by the server
/// (`summary`) — the client never recalculates them.
class MonthlyPlan {
  const MonthlyPlan({
    required this.id,
    required this.month,
    required this.closed,
    required this.entries,
    required this.summary,
    required this.settlement,
  });

  final String id;

  /// The month, formatted `YYYY-MM`.
  final String month;

  /// True once the month has been settled and can no longer be edited.
  final bool closed;

  final List<MonthlyPlanEntry> entries;

  /// The server-derived month summary (status, totals, progress).
  final ExpenseMonthSummary summary;

  /// The contributions snapshot, present only once the month is closed.
  final MonthSettlement? settlement;

  /// Total planned for the month, in euros.
  double get planned => summary.planned;

  /// Total actually spent in the month, in euros.
  double get actual => summary.actual;

  /// Whether the actual spend exceeds the planned amount (server rule).
  bool get isOver => summary.over;

  /// How much of the plan was consumed, as a percentage (server rule).
  double get progressPct => summary.progressPct;

  bool get isEmpty => entries.isEmpty;
}
