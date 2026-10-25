import 'package:nest/domain/models/expense_category_total.dart';

/// API-facing representation of an [ExpenseCategoryTotal], with JSON mapping.
class ExpenseCategoryTotalModel {
  const ExpenseCategoryTotalModel({
    required this.categoryName,
    required this.planned,
    required this.actual,
    this.iconKey,
    this.overPlanMonths,
  });

  factory ExpenseCategoryTotalModel.fromJson(Map<String, dynamic> json) {
    final overPlanMonths = json['overPlanMonths'];
    return ExpenseCategoryTotalModel(
      categoryName: json['name'] as String? ?? '',
      planned: (json['planned'] as num?)?.toDouble() ?? 0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0,
      iconKey: json['iconKey'] as String?,
      overPlanMonths: overPlanMonths is Map<String, dynamic>
          ? ExpenseCategoryOverPlanMonthsModel.fromJson(overPlanMonths)
          : null,
    );
  }

  final String categoryName;
  final double planned;
  final double actual;
  final String? iconKey;
  final ExpenseCategoryOverPlanMonthsModel? overPlanMonths;

  ExpenseCategoryTotal toDomain() => ExpenseCategoryTotal(
    categoryName: categoryName,
    planned: planned,
    actual: actual,
    iconKey: iconKey,
    overPlanMonths: overPlanMonths?.toDomain(),
  );
}

/// API-facing representation of an [ExpenseCategoryOverPlanMonths].
class ExpenseCategoryOverPlanMonthsModel {
  const ExpenseCategoryOverPlanMonthsModel({
    required this.count,
    required this.suggestAdjustment,
  });

  factory ExpenseCategoryOverPlanMonthsModel.fromJson(
    Map<String, dynamic> json,
  ) => ExpenseCategoryOverPlanMonthsModel(
    count: (json['count'] as num?)?.toInt() ?? 0,
    suggestAdjustment: json['suggestAdjustment'] as bool? ?? false,
  );

  final int count;
  final bool suggestAdjustment;

  ExpenseCategoryOverPlanMonths toDomain() => ExpenseCategoryOverPlanMonths(
    count: count,
    suggestAdjustment: suggestAdjustment,
  );
}
