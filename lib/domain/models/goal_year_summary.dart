/// A goal's projected completion, as computed by the server.
class GoalCompletionProjection {
  const GoalCompletionProjection({
    required this.asOfMonth,
    required this.pacePerMonth,
    required this.remainingMonths,
    required this.projectedAmount,
    required this.projectedMonth,
    required this.reachesBudget,
    required this.completionMonth,
  });

  /// The last settled month used as the pace's base, formatted `YYYY-MM`.
  final String asOfMonth;

  /// The average reserved amount per settled month, in euros.
  final double pacePerMonth;

  /// Months left until the timeline's deadline (zero once it has passed).
  final int remainingMonths;

  /// The amount expected at the deadline, capped at the goal's budget.
  final double projectedAmount;

  /// The deadline month the projected amount refers to, formatted `YYYY-MM`.
  final String projectedMonth;

  /// True when the budget is reached by the deadline.
  final bool reachesBudget;

  /// The month the budget is reached, or null when it is not reached in time.
  final String? completionMonth;
}

/// One goal's row in the server's yearly goals summary.
class GoalYearSummaryRow {
  const GoalYearSummaryRow({required this.goalId, required this.projection});

  final String goalId;

  /// The goal's completion projection, or null when the server has no basis.
  final GoalCompletionProjection? projection;
}

/// The yearly goals panorama, narrowed to the rows that carry a projection.
class GoalYearSummary {
  const GoalYearSummary({required this.year, required this.rows});

  final int year;

  final List<GoalYearSummaryRow> rows;
}
