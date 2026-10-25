/// How many settled months in a row a category spent above its plan.
class ExpenseCategoryOverPlanStreak {
  const ExpenseCategoryOverPlanStreak({
    required this.current,
    required this.longest,
    required this.suggestAdjustment,
  });

  /// Settled months above plan up to the last settled month of the year.
  final int current;

  /// The longest run of settled months above plan in the year.
  final int longest;

  /// True when the server says the template budget should be reviewed.
  final bool suggestAdjustment;
}

/// The year's planned and actual spend for one expense category.
class ExpenseCategoryTotal {
  const ExpenseCategoryTotal({
    required this.categoryName,
    required this.planned,
    required this.actual,
    this.iconKey,
    this.overPlanStreak,
  });

  final String categoryName;

  /// The category's stored semantic icon key, when it has one.
  final String? iconKey;

  /// The amount planned for the year, in euros.
  final double planned;

  /// The amount actually spent in the year, in euros.
  final double actual;

  /// The server's run of settled months spent above plan, when supplied.
  final ExpenseCategoryOverPlanStreak? overPlanStreak;
}
