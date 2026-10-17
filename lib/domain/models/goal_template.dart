/// One goal's target within an annual template version.
class GoalTemplateEntry {
  const GoalTemplateEntry({
    required this.goalId,
    required this.percentage,
    required this.budget,
  });

  final String goalId;

  /// The goal's share of the annual total, as a percentage.
  final double percentage;

  /// The goal's budget for the year, in euros — its saving target.
  final double budget;
}

/// A version of the annual goals template.
class GoalTemplate {
  const GoalTemplate({
    required this.id,
    required this.validFrom,
    required this.annualTotal,
    required this.entries,
  });

  final String id;

  /// The first month the version applies to, formatted `YYYY-MM`.
  final String validFrom;

  /// The annual available used as the template's reference, in euros.
  final double annualTotal;

  final List<GoalTemplateEntry> entries;
}
