import 'package:nest/domain/models/category.dart';

/// A row of an expense template, with the server-filled names and flags.
class CategoryTemplateEntry {
  const CategoryTemplateEntry({
    required this.categoryId,
    required this.accountId,
    required this.expectedAmount,
    required this.active,
    required this.categoryName,
    required this.categoryType,
    required this.categoryActive,
    required this.accountName,
    required this.accountActive,
  });

  final String categoryId;
  final String accountId;

  /// The expected monthly amount for the category, in euros.
  final double expectedAmount;

  final bool active;
  final String categoryName;
  final CategoryType categoryType;
  final bool categoryActive;
  final String accountName;
  final bool accountActive;
}

/// A version of the expense template.
class CategoryTemplate {
  const CategoryTemplate({
    required this.id,
    required this.validFrom,
    required this.entries,
  });

  final String id;

  /// The first month the version applies to, formatted `YYYY-MM`.
  final String validFrom;

  final List<CategoryTemplateEntry> entries;
}

/// The version in force for a month and the account suggested for new rows.
class ApplicableCategoryTemplate {
  const ApplicableCategoryTemplate({
    required this.template,
    required this.defaultAccountId,
  });

  /// The version applicable to the month, or null when none applies.
  final CategoryTemplate? template;

  /// The joint account (or first active one) to suggest for new rows.
  final String? defaultAccountId;
}

/// A row to write: only the fields the API accepts.
class CategoryTemplateEntryDraft {
  const CategoryTemplateEntryDraft({
    required this.categoryId,
    required this.accountId,
    required this.expectedAmount,
    this.active = true,
  });

  final String categoryId;
  final String accountId;
  final double expectedAmount;
  final bool active;
}
