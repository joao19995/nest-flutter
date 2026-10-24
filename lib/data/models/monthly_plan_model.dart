import 'package:nest/data/models/expense_year_summary_model.dart';
import 'package:nest/domain/models/category.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/monthly_plan.dart';

/// API-facing representation of a [MonthlyPlan], with JSON mapping.
class MonthlyPlanModel {
  const MonthlyPlanModel({
    required this.id,
    required this.month,
    required this.closed,
    required this.entries,
    required this.summary,
    required this.settlement,
  });

  factory MonthlyPlanModel.fromJson(Map<String, dynamic> json) {
    final entries = json['entries'];
    final summary = json['summary'];
    final settlement = json['settlement'];
    return MonthlyPlanModel(
      id: json['id'] as String,
      month: json['month'] as String,
      closed: json['closed'] as bool,
      entries: entries is List
          ? entries
                .whereType<Map<String, dynamic>>()
                .map(MonthlyPlanEntryModel.fromJson)
                .toList(growable: false)
          : const [],
      summary: summary is Map<String, dynamic>
          ? ExpenseMonthSummaryModel.fromJson(summary)
          : ExpenseMonthSummaryModel.empty(json['month'] as String? ?? ''),
      settlement: settlement is Map<String, dynamic>
          ? MonthSettlementModel.fromJson(settlement)
          : null,
    );
  }

  final String id;
  final String month;
  final bool closed;
  final List<MonthlyPlanEntryModel> entries;
  final ExpenseMonthSummaryModel summary;
  final MonthSettlementModel? settlement;

  MonthlyPlan toDomain() => MonthlyPlan(
    id: id,
    month: month,
    closed: closed,
    entries: entries.map((entry) => entry.toDomain()).toList(growable: false),
    summary: summary.toDomain(),
    settlement: settlement?.toDomain(),
  );
}

/// API-facing representation of a [MonthlyPlanEntry], with JSON mapping.
class MonthlyPlanEntryModel {
  const MonthlyPlanEntryModel({
    required this.id,
    required this.categoryName,
    required this.type,
    required this.accountName,
    required this.planned,
    required this.actual,
    required this.actualSet,
    this.categoryIconKey,
  });

  factory MonthlyPlanEntryModel.fromJson(Map<String, dynamic> json) {
    final actual = (json['actual'] as num).toDouble();
    return MonthlyPlanEntryModel(
      id: json['id'] as String,
      categoryName: json['categoryName'] as String,
      type: _typeFromJson(json['categoryType']),
      accountName: json['accountName'] as String,
      planned: (json['planned'] as num).toDouble(),
      actual: actual,
      actualSet: json['actualSet'] as bool? ?? actual != 0,
      categoryIconKey: json['categoryIconKey'] as String?,
    );
  }

  final String id;
  final String categoryName;
  final CategoryType type;
  final String accountName;
  final double planned;
  final double actual;
  final bool actualSet;
  final String? categoryIconKey;

  MonthlyPlanEntry toDomain() => MonthlyPlanEntry(
    id: id,
    categoryName: categoryName,
    type: type,
    accountName: accountName,
    planned: planned,
    actual: actual,
    actualSet: actualSet,
    categoryIconKey: categoryIconKey,
  );

  static CategoryType _typeFromJson(Object? value) => switch (value) {
    'FIXED' => CategoryType.fixed,
    _ => CategoryType.variable,
  };
}

/// API-facing representation of a [MonthSettlement], with JSON mapping.
class MonthSettlementModel {
  const MonthSettlementModel({
    required this.status,
    required this.contributionRequired,
    required this.jointSurplus,
    required this.people,
    this.message,
  });

  factory MonthSettlementModel.fromJson(Map<String, dynamic> json) {
    final people = json['people'];
    return MonthSettlementModel(
      status: json['status'] == 'ok'
          ? SettlementStatus.ok
          : SettlementStatus.noIncome,
      contributionRequired:
          (json['contributionRequired'] as num?)?.toDouble() ?? 0,
      jointSurplus: (json['jointSurplus'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String?,
      people: people is List
          ? people
                .whereType<Map<String, dynamic>>()
                .map(MonthSettlementPersonModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final SettlementStatus status;
  final double contributionRequired;
  final double jointSurplus;
  final List<MonthSettlementPersonModel> people;
  final String? message;

  MonthSettlement toDomain() => MonthSettlement(
    status: status,
    contributionRequired: contributionRequired,
    jointSurplus: jointSurplus,
    people: people.map((person) => person.toDomain()).toList(growable: false),
    message: message,
  );
}

/// API-facing representation of a [MonthSettlementPerson], with JSON mapping.
class MonthSettlementPersonModel {
  const MonthSettlementPersonModel({
    required this.personName,
    required this.income,
    required this.quota,
    required this.personalActual,
    required this.transferToJoint,
    required this.transferToPerson,
  });

  factory MonthSettlementPersonModel.fromJson(Map<String, dynamic> json) =>
      MonthSettlementPersonModel(
        personName: json['personName'] as String,
        income: (json['income'] as num).toDouble(),
        quota: (json['quota'] as num).toDouble(),
        personalActual: (json['personalActual'] as num).toDouble(),
        transferToJoint: (json['transferToJoint'] as num).toDouble(),
        transferToPerson: (json['transferToPerson'] as num).toDouble(),
      );

  final String personName;
  final double income;
  final double quota;
  final double personalActual;
  final double transferToJoint;
  final double transferToPerson;

  MonthSettlementPerson toDomain() => MonthSettlementPerson(
    personName: personName,
    income: income,
    quota: quota,
    personalActual: personalActual,
    transferToJoint: transferToJoint,
    transferToPerson: transferToPerson,
  );
}
