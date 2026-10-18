import 'package:nest/domain/models/category.dart';
import 'package:nest/domain/models/category_template.dart';

/// API-facing representation of a [CategoryTemplate], with JSON mapping.
class CategoryTemplateModel {
  const CategoryTemplateModel({
    required this.id,
    required this.validFrom,
    required this.entries,
  });

  factory CategoryTemplateModel.fromJson(Map<String, dynamic> json) {
    final entries = json['entries'];
    return CategoryTemplateModel(
      id: json['id'] as String,
      validFrom: json['validFrom'] as String,
      entries: entries is List
          ? entries
                .whereType<Map<String, dynamic>>()
                .map(CategoryTemplateEntryModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String validFrom;
  final List<CategoryTemplateEntryModel> entries;

  CategoryTemplate toDomain() => CategoryTemplate(
    id: id,
    validFrom: validFrom,
    entries: entries.map((entry) => entry.toDomain()).toList(growable: false),
  );
}

/// API-facing representation of a [CategoryTemplateEntry], with JSON mapping.
class CategoryTemplateEntryModel {
  const CategoryTemplateEntryModel({
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

  factory CategoryTemplateEntryModel.fromJson(Map<String, dynamic> json) =>
      CategoryTemplateEntryModel(
        categoryId: json['categoryId'] as String,
        accountId: json['accountId'] as String,
        expectedAmount: (json['expectedAmount'] as num).toDouble(),
        active: json['active'] as bool? ?? true,
        categoryName: json['categoryName'] as String? ?? '',
        categoryType: _typeFromJson(json['categoryType'] as String? ?? ''),
        categoryActive: json['categoryActive'] as bool? ?? true,
        accountName: json['accountName'] as String? ?? '',
        accountActive: json['accountActive'] as bool? ?? true,
      );

  final String categoryId;
  final String accountId;
  final double expectedAmount;
  final bool active;
  final String categoryName;
  final CategoryType categoryType;
  final bool categoryActive;
  final String accountName;
  final bool accountActive;

  CategoryTemplateEntry toDomain() => CategoryTemplateEntry(
    categoryId: categoryId,
    accountId: accountId,
    expectedAmount: expectedAmount,
    active: active,
    categoryName: categoryName,
    categoryType: categoryType,
    categoryActive: categoryActive,
    accountName: accountName,
    accountActive: accountActive,
  );

  static CategoryType _typeFromJson(String value) => switch (value) {
    'FIXED' => CategoryType.fixed,
    'VARIABLE' => CategoryType.variable,
    _ => CategoryType.variable,
  };
}
