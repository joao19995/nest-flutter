/// The status of a month's settlement snapshot.
enum SettlementStatus {
  /// Contributions were computed and recorded.
  ok,

  /// The month was closed without any registered income.
  noIncome,
}

/// One person's settlement within a closed month.
class MonthSettlementPerson {
  const MonthSettlementPerson({
    required this.personName,
    required this.income,
    required this.quota,
    required this.personalActual,
    required this.transferToJoint,
    required this.transferToPerson,
  });

  final String personName;

  /// The person's income for the month, in euros.
  final double income;

  /// The person's share of the joint expenses, in euros.
  final double quota;

  /// What the person actually paid towards their quota, in euros.
  final double personalActual;

  /// Amount to transfer to the joint account, in euros. Zero otherwise.
  final double transferToJoint;

  /// Amount to receive from the joint account, in euros. Zero otherwise.
  final double transferToPerson;

  /// True when a transfer to the joint account is due.
  bool get transfersToJoint => transferToJoint > 0.005;

  /// True when a transfer from the joint account is due.
  bool get transfersToPerson => transferToPerson > 0.005;
}

/// Snapshot of the contributions recorded when a month is closed.
class MonthSettlement {
  const MonthSettlement({
    required this.status,
    required this.contributionRequired,
    required this.jointSurplus,
    required this.people,
    this.message,
  });

  final SettlementStatus status;

  /// Total contribution required for the month, in euros.
  final double contributionRequired;

  /// What is left in the joint account after settlement, in euros.
  final double jointSurplus;

  final List<MonthSettlementPerson> people;

  /// Explanation, present when [status] is [SettlementStatus.noIncome].
  final String? message;
}
