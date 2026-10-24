import 'package:nest/domain/models/expense_category_total.dart';

/// The lifecycle state of a month within the yearly expense panorama.
enum ExpenseMonthStatus {
  /// No plan exists for the month yet.
  missing,

  /// The month has a plan but has not been settled.
  open,

  /// The month has been settled.
  closed,
}

/// One month in the yearly expense panorama: what was planned versus spent.
class ExpenseMonthSummary {
  const ExpenseMonthSummary({
    required this.month,
    required this.status,
    required this.planned,
    required this.actual,
    required this.progressPct,
    required this.over,
    required this.filledEntries,
    required this.totalEntries,
  });

  /// The month, formatted `YYYY-MM`.
  final String month;

  /// Whether the month is missing, open or closed.
  final ExpenseMonthStatus status;

  /// The amount planned for the month, in euros.
  final double planned;

  /// The amount actually spent in the month, in euros.
  final double actual;

  /// How much of the plan was consumed, as a percentage.
  final double progressPct;

  /// True when the actual spend exceeded the planned amount.
  final bool over;

  /// How many lines already have a real amount entered (server rule).
  final int filledEntries;

  /// How many lines the month has (server rule).
  final int totalEntries;
}

/// The annual expense panorama for a given year.
class ExpenseYearSummary {
  const ExpenseYearSummary({
    required this.year,
    required this.planned,
    required this.actual,
    required this.diff,
    required this.diffPct,
    required this.over,
    required this.remainingMonths,
    required this.perRemainingMonth,
    required this.hasData,
    required this.byCategory,
    required this.months,
  });

  /// The year the summary describes.
  final int year;

  /// The total amount planned across the year, in euros.
  final double planned;

  /// The total amount actually spent across the year, in euros.
  final double actual;

  /// `actual - planned`, in euros. Positive means over plan.
  final double diff;

  /// How far the actual spend deviates from the plan, as a percentage.
  final double diffPct;

  /// True when the actual spend exceeds the planned amount.
  final bool over;

  /// The number of months in the year without a settled plan.
  final int remainingMonths;

  /// The amount to set aside each remaining month to balance the year.
  final double perRemainingMonth;

  /// False when the year has no plan or spend recorded at all.
  final bool hasData;

  /// The year's spend grouped by category, as supplied by the API.
  final List<ExpenseCategoryTotal> byCategory;

  /// The twelve months of the year, in calendar order.
  final List<ExpenseMonthSummary> months;
}
