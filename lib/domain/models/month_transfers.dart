import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/monthly_plan.dart';

/// One goal slice of a person's final transfer.
class MonthTransfersGoalPart {
  const MonthTransfersGoalPart({
    required this.goalId,
    required this.name,
    required this.amount,
  });

  final String goalId;
  final String name;
  final double amount;
}

/// A person's combined final transfers for a closed month.
class MonthTransfersPerson {
  const MonthTransfersPerson({
    required this.personId,
    required this.personName,
    required this.toJoint,
    required this.fromJoint,
    required this.toGoals,
    required this.goals,
  });

  final String personId;
  final String personName;

  /// Amount the person transfers to the joint account, in euros.
  final double toJoint;

  /// Amount the person receives from the joint account, in euros.
  final double fromJoint;

  /// Amount the person transfers to goals, in euros.
  final double toGoals;

  /// Where the goals transfer goes, goal by goal.
  final List<MonthTransfersGoalPart> goals;
}

/// The combined totals of a closed month.
class MonthTransfersTotals {
  const MonthTransfersTotals({
    required this.toJoint,
    required this.fromJoint,
    required this.toGoals,
  });

  final double toJoint;
  final double fromJoint;
  final double toGoals;
}

/// The definitive transfers of a closed month: the recorded expenses
/// settlement plus the frozen goals quotas, merged per person.
class MonthTransfers {
  const MonthTransfers({
    required this.month,
    required this.closed,
    required this.expenses,
    required this.goals,
    required this.goalsReserved,
    required this.goalsHasIncome,
    required this.totals,
    required this.people,
  });

  /// Builds the combined view from the two month views. The goals quotas are
  /// expected to be the server's frozen snapshot for a closed month.
  factory MonthTransfers.fromMonths({
    required String month,
    required MonthlyPlan? expenses,
    required GoalMonthView? goals,
  }) {
    final settlement = expenses?.settlement;
    final quotas = goals?.quotas ?? const <GoalMonthQuota>[];
    final funding = goals?.funding;
    final accumulators = <String, _PersonAccumulator>{};

    if (settlement != null && settlement.status == SettlementStatus.ok) {
      for (final person in settlement.people) {
        final key = person.personId.isNotEmpty
            ? person.personId
            : person.personName;
        final accumulator = accumulators.putIfAbsent(
          key,
          () => _PersonAccumulator(
            personId: person.personId,
            personName: person.personName,
          ),
        );
        accumulator.toJoint += person.transferToJoint;
        accumulator.fromJoint += person.transferToPerson;
      }
    }

    for (final quota in quotas) {
      final key = quota.personId.isNotEmpty ? quota.personId : quota.name;
      final accumulator = accumulators.putIfAbsent(
        key,
        () => _PersonAccumulator(
          personId: quota.personId,
          personName: quota.name,
        ),
      );
      accumulator.toGoals += quota.amount;
      for (final part in quota.parts) {
        accumulator.goals.add(
          MonthTransfersGoalPart(
            goalId: part.goalId,
            name: part.name,
            amount: part.amount,
          ),
        );
      }
    }

    final people =
        accumulators.values
            .map((accumulator) => accumulator.build())
            .toList(growable: false)
          ..sort((a, b) => a.personName.compareTo(b.personName));

    var toJoint = 0.0;
    var fromJoint = 0.0;
    var toGoals = 0.0;
    for (final person in people) {
      toJoint += person.toJoint;
      fromJoint += person.fromJoint;
      toGoals += person.toGoals;
    }

    return MonthTransfers(
      month: month,
      closed: (expenses?.closed ?? false) && (goals?.plan?.closed ?? false),
      expenses: settlement,
      goals: quotas,
      goalsReserved: goals?.totals.reserved ?? 0,
      goalsHasIncome:
          ((funding?.incomeNormal ?? 0) + (funding?.bonus ?? 0)) > 0.005,
      totals: MonthTransfersTotals(
        toJoint: toJoint,
        fromJoint: fromJoint,
        toGoals: toGoals,
      ),
      people: people,
    );
  }

  final String month;

  /// True when both the expenses and goals months are closed.
  final bool closed;

  /// The recorded expenses settlement, when the month is closed.
  final MonthSettlement? expenses;

  /// The frozen goals quotas of the month.
  final List<GoalMonthQuota> goals;

  /// The effective reserved total of the goals month, in euros.
  final double goalsReserved;

  /// Whether the goals month has income recorded.
  final bool goalsHasIncome;

  final MonthTransfersTotals totals;

  /// The merged per-person summary, sorted by name.
  final List<MonthTransfersPerson> people;
}

class _PersonAccumulator {
  _PersonAccumulator({required this.personId, required this.personName});

  final String personId;
  final String personName;
  double toJoint = 0;
  double fromJoint = 0;
  double toGoals = 0;
  final List<MonthTransfersGoalPart> goals = [];

  MonthTransfersPerson build() => MonthTransfersPerson(
    personId: personId,
    personName: personName,
    toJoint: toJoint,
    fromJoint: fromJoint,
    toGoals: toGoals,
    goals: List.unmodifiable(goals),
  );
}
