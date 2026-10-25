/// How the server reports a category's settled months above plan in a year.
class ExpenseCategoryOverPlanMonths {
  const ExpenseCategoryOverPlanMonths({
    required this.count,
    required this.suggestAdjustment,
  });

  /// Number of settled months in the year the category spent above plan.
  final int count;

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
    this.overPlanMonths,
  });

  final String categoryName;

  /// The category's stored semantic icon key, when it has one.
  final String? iconKey;

  /// The amount planned for the year, in euros.
  final double planned;

  /// The amount actually spent in the year, in euros.
  final double actual;

  /// The server's count of settled months spent above plan, when supplied.
  final ExpenseCategoryOverPlanMonths? overPlanMonths;
}
