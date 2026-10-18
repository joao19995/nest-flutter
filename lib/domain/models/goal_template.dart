/// One goal's target within an annual template version.
class GoalTemplateEntry {
  const GoalTemplateEntry({required this.goalId, required this.budget});

  final String goalId;

  /// The goal's budget for the year, in euros — its saving target.
  final double budget;
}

/// A version of the annual goals template.
class GoalTemplate {
  const GoalTemplate({
    required this.id,
    required this.validFrom,
    required this.entries,
  });

  final String id;

  /// The first month the version applies to, formatted `YYYY-MM`.
  final String validFrom;

  final List<GoalTemplateEntry> entries;
}
