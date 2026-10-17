/// A household member.
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.dailySpendingPercentage,
    required this.emergencyFundMonths,
  });

  final String id;
  final String name;
  final double dailySpendingPercentage;
  final int emergencyFundMonths;
}
