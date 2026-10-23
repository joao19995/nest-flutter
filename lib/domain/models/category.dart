/// Whether a category is a fixed or a variable expense.
enum CategoryType { fixed, variable }

/// An expense category.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
    this.iconKey,
  });

  final String id;
  final String name;
  final CategoryType type;

  /// Whether the category is visible (soft-deleted categories are inactive).
  final bool active;

  /// Semantic icon key chosen by the user (e.g. `cart`, `bolt`).
  ///
  /// `null` means the icon is derived from [name].
  final String? iconKey;

  /// Whether this is a fixed expense category.
  bool get isFixed => type == CategoryType.fixed;
}
