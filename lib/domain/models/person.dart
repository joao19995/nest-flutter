/// A household member.
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.dailySpendingPercentage,
    required this.emergencyFundMonths,
    this.applicableIncome,
    this.applicableIncomeId,
  });

  final String id;
  final String name;

  /// The share of the income allocated to daily spending, as a percentage.
  final double dailySpendingPercentage;

  /// How many months of expenses the emergency fund should cover.
  final int emergencyFundMonths;

  /// The income applicable to the requested month, in euros. Only present when
  /// people are fetched with `?incomeMonth=YYYY-MM` (server-side rule).
  final double? applicableIncome;

  /// The id of the income record [applicableIncome] comes from, when requested.
  final String? applicableIncomeId;
}
