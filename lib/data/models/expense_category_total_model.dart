import 'package:nest/domain/models/expense_category_total.dart';

/// API-facing representation of an [ExpenseCategoryTotal], with JSON mapping.
class ExpenseCategoryTotalModel {
  const ExpenseCategoryTotalModel({
    required this.categoryName,
    required this.planned,
    required this.actual,
    this.iconKey,
    this.overPlanStreak,
  });

  factory ExpenseCategoryTotalModel.fromJson(Map<String, dynamic> json) {
    final streak = json['overPlanStreak'];
    return ExpenseCategoryTotalModel(
      categoryName: json['name'] as String? ?? '',
      planned: (json['planned'] as num?)?.toDouble() ?? 0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0,
      iconKey: json['iconKey'] as String?,
      overPlanStreak: streak is Map<String, dynamic>
          ? ExpenseCategoryOverPlanStreakModel.fromJson(streak)
          : null,
    );
  }

  final String categoryName;
  final double planned;
  final double actual;
  final String? iconKey;
  final ExpenseCategoryOverPlanStreakModel? overPlanStreak;

  ExpenseCategoryTotal toDomain() => ExpenseCategoryTotal(
    categoryName: categoryName,
    planned: planned,
    actual: actual,
    iconKey: iconKey,
    overPlanStreak: overPlanStreak?.toDomain(),
  );
}

/// API-facing representation of an [ExpenseCategoryOverPlanStreak].
class ExpenseCategoryOverPlanStreakModel {
  const ExpenseCategoryOverPlanStreakModel({
    required this.current,
    required this.longest,
    required this.suggestAdjustment,
  });

  factory ExpenseCategoryOverPlanStreakModel.fromJson(
    Map<String, dynamic> json,
  ) => ExpenseCategoryOverPlanStreakModel(
    current: (json['current'] as num?)?.toInt() ?? 0,
    longest: (json['longest'] as num?)?.toInt() ?? 0,
    suggestAdjustment: json['suggestAdjustment'] as bool? ?? false,
  );

  final int current;
  final int longest;
  final bool suggestAdjustment;

  ExpenseCategoryOverPlanStreak toDomain() => ExpenseCategoryOverPlanStreak(
    current: current,
    longest: longest,
    suggestAdjustment: suggestAdjustment,
  );
}
