import 'package:nest/domain/models/expense_category_total.dart';

/// API-facing representation of an [ExpenseCategoryTotal], with JSON mapping.
class ExpenseCategoryTotalModel {
  const ExpenseCategoryTotalModel({
    required this.categoryName,
    required this.planned,
    required this.actual,
    this.iconKey,
  });

  factory ExpenseCategoryTotalModel.fromJson(Map<String, dynamic> json) =>
      ExpenseCategoryTotalModel(
        categoryName: json['name'] as String? ?? '',
        planned: (json['planned'] as num?)?.toDouble() ?? 0,
        actual: (json['actual'] as num?)?.toDouble() ?? 0,
        iconKey: json['iconKey'] as String?,
      );

  final String categoryName;
  final double planned;
  final double actual;
  final String? iconKey;

  ExpenseCategoryTotal toDomain() => ExpenseCategoryTotal(
    categoryName: categoryName,
    planned: planned,
    actual: actual,
    iconKey: iconKey,
  );
}
