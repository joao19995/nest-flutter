/// One goal's allocation within a month.
class GoalAllocation {
  const GoalAllocation({
    required this.goalId,
    required this.goalName,
    required this.planned,
    required this.actual,
  });

  final String goalId;
  final String goalName;

  /// The amount planned for the goal, in euros.
  final double planned;

  /// The amount actually reserved for the goal, in euros.
  final double actual;
}

/// A saved month of goal allocations.
class GoalPlan {
  const GoalPlan({
    required this.id,
    required this.month,
    required this.availableAmount,
    required this.closed,
    required this.allocations,
  });

  final String id;

  /// The month, formatted `YYYY-MM`.
  final String month;

  /// The amount available to allocate in the month, in euros.
  final double availableAmount;

  final bool closed;
  final List<GoalAllocation> allocations;

  /// Total actually reserved across the month's goals, in euros.
  double get reserved =>
      allocations.fold<double>(0, (sum, item) => sum + item.actual);

  /// The number of goals that received an allocation this month.
  int get fundedCount => allocations.where((item) => item.actual > 0).length;
}

/// The money available for goals in one month, with its breakdown.
class MonthFunding {
  const MonthFunding({
    required this.month,
    required this.incomeNormal,
    required this.bonus,
    required this.dailyAllowance,
    required this.contributionRequired,
    required this.available,
  });

  final String month;

  /// The household's normal income for the month, in euros.
  final double incomeNormal;

  /// The June/December bonus added on top, in euros.
  final double bonus;

  /// The daily-spending allowance kept aside, in euros.
  final double dailyAllowance;

  /// The planned expense contribution from the applicable template, in euros.
  final double contributionRequired;

  /// The amount available for goals in the month, in euros.
  final double available;
}

/// A year of goal plans plus the funding available for them.
class GoalYear {
  const GoalYear({
    required this.year,
    required this.annualTotal,
    required this.plans,
    required this.months,
  });

  final int year;

  /// The total amount available for goals across the year, in euros.
  final double annualTotal;

  /// The saved months, in calendar order.
  final List<GoalPlan> plans;

  /// The twelve months of funding, in calendar order.
  final List<MonthFunding> months;
}
