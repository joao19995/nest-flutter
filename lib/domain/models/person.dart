/// A household member.
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.dailySpendingPercentage,
    this.applicableIncome,
  });

  final String id;
  final String name;

  /// The share of the income allocated to daily spending, as a percentage.
  final double dailySpendingPercentage;

  /// The income applicable to the requested month, in euros. Only present when
  /// people are fetched with `?incomeMonth=YYYY-MM` (server-side rule).
  final double? applicableIncome;
}
