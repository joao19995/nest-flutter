/// A household member.
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.dailySpendingPercentage,
  });

  final String id;
  final String name;
  final double dailySpendingPercentage;
}
