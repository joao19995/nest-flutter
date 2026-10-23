import 'package:nest/domain/models/expense_category_total.dart';

/// API-facing representation of an [ExpenseCategoryTotal], with JSON mapping.
class ExpenseCategoryTotalModel {
  const ExpenseCategoryTotalModel({
    required this.categoryName,
    required this.planned,
    required this.actual,
  });

  factory ExpenseCategoryTotalModel.fromJson(Map<String, dynamic> json) =>
      ExpenseCategoryTotalModel(
        categoryName: json['name'] as String? ?? '',
        planned: (json['planned'] as num?)?.toDouble() ?? 0,
        actual: (json['actual'] as num?)?.toDouble() ?? 0,
      );

  final String categoryName;
  final double planned;
  final double actual;

  ExpenseCategoryTotal toDomain() => ExpenseCategoryTotal(
    categoryName: categoryName,
    planned: planned,
    actual: actual,
  );
}
