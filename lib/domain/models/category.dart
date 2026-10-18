/// Whether a category is a fixed or a variable expense.
enum CategoryType { fixed, variable }

/// An expense category.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
  });

  final String id;
  final String name;
  final CategoryType type;

  /// Whether the category is visible (soft-deleted categories are inactive).
  final bool active;

  /// Whether this is a fixed expense category.
  bool get isFixed => type == CategoryType.fixed;
}
