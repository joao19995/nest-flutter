import 'package:nest/domain/models/goal_year.dart';

/// One goal's slice of a person's monthly transfer.
class GoalMonthQuotaPart {
  const GoalMonthQuotaPart({
    required this.goalId,
    required this.name,
    required this.amount,
  });

  final String goalId;
  final String name;
  final double amount;
}

/// One person's quota of the month's reserved goals, and where it goes.
class GoalMonthQuota {
  const GoalMonthQuota({
    required this.personId,
    required this.name,
    required this.earning,
    required this.share,
    required this.amount,
    required this.parts,
  });

  final String personId;
  final String name;

  /// The person's earning for the month (with the Jun/Dec bonus), in euros.
  final double earning;

  /// The person's share of the total earning, as a 0..1 fraction.
  final double share;

  /// The amount the person transfers, in euros.
  final double amount;

  /// Where the transfer goes, goal by goal.
  final List<GoalMonthQuotaPart> parts;
}

/// A goal's reserved amount sent to `POST /api/goal-plan/quotas` to compute the
/// proportions without saving.
typedef GoalQuotaDraft = ({String goalId, String name, double amount});

/// The full goals month returned by `GET /api/goal-plan/{month}`: the saved
/// plan, the available amount and the per-person quotas, all computed by the
/// server so the client does not reimplement the domain.
class GoalMonthView {
  const GoalMonthView({
    required this.plan,
    required this.availableAmount,
    required this.quotas,
  });

  /// The saved plan, or `null` when the month has not been created yet.
  final GoalPlan? plan;

  /// The month's available amount, in euros (the saved snapshot, or the
  /// projection when there is no plan yet).
  final double availableAmount;

  /// Who transfers what towards the month's goals.
  final List<GoalMonthQuota> quotas;
}
