/// The year's planned and actual spend for one expense category.
class ExpenseCategoryTotal {
  const ExpenseCategoryTotal({
    required this.categoryName,
    required this.planned,
    required this.actual,
    this.iconKey,
  });

  final String categoryName;

  /// The category's stored semantic icon key, when it has one.
  final String? iconKey;

  /// The amount planned for the year, in euros.
  ///
  /// The API's category summary currently omits this, so it defaults to zero
  /// until the field is exposed.
  final double planned;

  /// The amount actually spent in the year, in euros.
  final double actual;
}
