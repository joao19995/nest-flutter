/// When a goal is expected to be reached.
enum GoalTimeline { t1, t2, t3, t4, annual }

/// The importance of a goal within the annual table.
enum GoalPriority { grande, pequeno, niceToHave }

/// One goal's target within an annual template version.
class GoalTemplateEntry {
  const GoalTemplateEntry({
    required this.goalId,
    required this.percentage,
    required this.budget,
    required this.timeline,
    required this.priority,
    required this.notes,
  });

  final String goalId;

  /// The goal's share of the annual table, 0–100. The entries must total 100.
  final double percentage;

  /// The goal's budget for the year, in euros — its saving target.
  final double budget;

  final GoalTimeline timeline;
  final GoalPriority priority;
  final String notes;
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

  /// An informational snapshot of the year's funding, in euros. The
  /// distribution itself runs on [entries]' percentages.
  final double annualTotal;

  final List<GoalTemplateEntry> entries;
}
