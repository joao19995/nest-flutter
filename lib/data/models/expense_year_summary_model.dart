import 'package:nest/domain/models/expense_year_summary.dart';

/// API-facing representation of an [ExpenseYearSummary], with JSON mapping.
class ExpenseYearSummaryModel {
  const ExpenseYearSummaryModel({
    required this.year,
    required this.planned,
    required this.actual,
    required this.diff,
    required this.diffPct,
    required this.over,
    required this.remainingMonths,
    required this.perRemainingMonth,
    required this.hasData,
    required this.months,
  });

  factory ExpenseYearSummaryModel.fromJson(Map<String, dynamic> json) {
    final months = json['months'];
    return ExpenseYearSummaryModel(
      year: (json['year'] as num).toInt(),
      planned: (json['planned'] as num).toDouble(),
      actual: (json['actual'] as num).toDouble(),
      diff: (json['diff'] as num).toDouble(),
      diffPct: (json['diffPct'] as num).toDouble(),
      over: json['over'] as bool,
      remainingMonths: (json['remainingMonths'] as num).toInt(),
      perRemainingMonth: (json['perRemainingMonth'] as num).toDouble(),
      hasData: json['hasData'] as bool,
      months: months is List
          ? months
                .whereType<Map<String, dynamic>>()
                .map(ExpenseMonthSummaryModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final int year;
  final double planned;
  final double actual;
  final double diff;
  final double diffPct;
  final bool over;
  final int remainingMonths;
  final double perRemainingMonth;
  final bool hasData;
  final List<ExpenseMonthSummaryModel> months;

  ExpenseYearSummary toDomain() => ExpenseYearSummary(
    year: year,
    planned: planned,
    actual: actual,
    diff: diff,
    diffPct: diffPct,
    over: over,
    remainingMonths: remainingMonths,
    perRemainingMonth: perRemainingMonth,
    hasData: hasData,
    months: months.map((month) => month.toDomain()).toList(growable: false),
  );
}

/// API-facing representation of an [ExpenseMonthSummary], with JSON mapping.
class ExpenseMonthSummaryModel {
  const ExpenseMonthSummaryModel({
    required this.month,
    required this.status,
    required this.planned,
    required this.actual,
    required this.progressPct,
    required this.over,
  });

  factory ExpenseMonthSummaryModel.fromJson(Map<String, dynamic> json) =>
      ExpenseMonthSummaryModel(
        month: json['month'] as String,
        status: _statusFromJson(json['status']),
        planned: (json['planned'] as num).toDouble(),
        actual: (json['actual'] as num).toDouble(),
        progressPct: (json['progressPct'] as num).toDouble(),
        over: json['over'] as bool,
      );

  /// A zeroed summary, used when a payload omits it.
  factory ExpenseMonthSummaryModel.empty(String month) =>
      ExpenseMonthSummaryModel(
        month: month,
        status: ExpenseMonthStatus.missing,
        planned: 0,
        actual: 0,
        progressPct: 0,
        over: false,
      );

  final String month;
  final ExpenseMonthStatus status;
  final double planned;
  final double actual;
  final double progressPct;
  final bool over;

  static ExpenseMonthStatus _statusFromJson(Object? value) => switch (value) {
    'open' => ExpenseMonthStatus.open,
    'closed' => ExpenseMonthStatus.closed,
    _ => ExpenseMonthStatus.missing,
  };

  ExpenseMonthSummary toDomain() => ExpenseMonthSummary(
    month: month,
    status: status,
    planned: planned,
    actual: actual,
    progressPct: progressPct,
    over: over,
  );
}
