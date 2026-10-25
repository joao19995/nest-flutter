import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/domain/models/goal_year.dart';
import 'package:nest/domain/models/goal_year_summary.dart';
import 'package:nest/ui/core/month_key.dart';

/// One month in the yearly goals overview.
class GoalMonthSummary {
  const GoalMonthSummary({
    required this.month,
    required this.reserved,
    required this.planned,
    required this.available,
    required this.fundedCount,
    required this.hasPlan,
    required this.closed,
  });

  /// The month, formatted `YYYY-MM`.
  final String month;

  /// The amount reserved for goals in the month, in euros.
  final double reserved;

  /// The amount planned for goals in the month, in euros.
  final double planned;

  /// The amount available for goals in the month, in euros.
  final double available;

  /// How many goals received an allocation this month.
  final int fundedCount;

  /// False when the month has no saved plan yet.
  final bool hasPlan;

  /// True once the month is closed.
  final bool closed;
}

/// A goal's total across the year.
class GoalSummary {
  const GoalSummary({
    required this.name,
    required this.reserved,
    required this.target,
    this.iconKey,
    this.timeline,
    this.priority,
    this.projection,
  });

  final String name;

  /// The goal's semantic icon key, when the catalogue supplies one.
  final String? iconKey;

  /// The amount reserved for the goal across the year, in euros.
  final double reserved;

  /// The goal's annual saving target, in euros. Zero when none is defined.
  final double target;

  /// The timeline from the applicable template, when there is one.
  final GoalTimeline? timeline;

  /// The priority from the applicable template, when there is one.
  final GoalPriority? priority;

  /// The server's completion projection, or null when there is no basis.
  final GoalCompletionProjection? projection;

  /// True when the goal has a saving target.
  bool get hasTarget => target > 0;

  /// The share of the target already reserved, clamped to a 0..1 fraction.
  double get progress {
    if (target <= 0) {
      return 0;
    }
    return (reserved / target).clamp(0.0, 1.0).toDouble();
  }

  /// What is still missing to reach the target, in euros.
  double get missing => target - reserved;
}

/// Presentation state for the yearly goals overview.
class GoalsViewModel extends ChangeNotifier {
  GoalsViewModel({required GoalsRepository goalsRepository, int? year})
    : _goalsRepository = goalsRepository,
      _selectedYear = year ?? DateTime.now().year;

  /// The earliest year the API accepts.
  static const int _minYear = 2000;

  /// The latest selectable year: the current one plus the next.
  static int get _maxYear => DateTime.now().year + 1;

  final GoalsRepository _goalsRepository;

  int _selectedYear;
  int get selectedYear => _selectedYear;

  bool get canGoToPreviousYear => _selectedYear > _minYear;

  bool get canGoToNextYear => _selectedYear < _maxYear;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GoalYear? _goalYear;
  List<Goal> _catalogue = const [];
  GoalTemplate? _applicableTemplate;
  Map<String, GoalCompletionProjection> _projections = const {};

  bool get isEmpty {
    final year = _goalYear;
    return year == null || year.plans.isEmpty;
  }

  /// The total reserved for goals across the year, in euros.
  double get totalReserved {
    final year = _goalYear;
    if (year == null) {
      return 0;
    }
    return year.plans.fold<double>(0, (sum, plan) => sum + plan.reserved);
  }

  /// The total available for goals across the year, in euros.
  double get annualAvailable => _goalYear?.annualTotal ?? 0;

  /// What is still to allocate. Positive means there is money left to
  /// allocate; negative means the year is allocated beyond what is available.
  double get unallocated => annualAvailable - totalReserved;

  /// The twelve months of the selected year, in calendar order.
  List<GoalMonthSummary> get months {
    final year = _goalYear;
    if (year == null) {
      return const [];
    }
    final planByMonth = <String, GoalPlan>{
      for (final plan in year.plans) plan.month: plan,
    };
    final availableByMonth = <String, double>{
      for (final month in year.months) month.month: month.available,
    };
    final summaries = <GoalMonthSummary>[];
    for (var index = 1; index <= 12; index++) {
      final key = MonthKey.of(_selectedYear, index);
      final plan = planByMonth[key];
      summaries.add(
        GoalMonthSummary(
          month: key,
          reserved: plan?.reserved ?? 0,
          planned:
              plan?.allocations.fold<double>(
                0,
                (sum, item) => sum + item.planned,
              ) ??
              0,
          available: availableByMonth[key] ?? 0,
          fundedCount: plan?.fundedCount ?? 0,
          hasPlan: plan != null,
          closed: plan?.closed ?? false,
        ),
      );
    }
    return summaries;
  }

  /// Every goal's total for the year, most funded first.
  List<GoalSummary> get goals {
    final reservedByGoal = <String, double>{};
    final nameByGoal = <String, String>{};
    final year = _goalYear;
    if (year != null) {
      for (final plan in year.plans) {
        for (final allocation in plan.allocations) {
          reservedByGoal.update(
            allocation.goalId,
            (value) => value + allocation.actual,
            ifAbsent: () => allocation.actual,
          );
          nameByGoal[allocation.goalId] = allocation.goalName;
        }
      }
    }
    final entries = _templateEntryByGoal();
    final summaries = <GoalSummary>[
      for (final goal in _catalogue)
        if (goal.active)
          GoalSummary(
            name: nameByGoal[goal.id] ?? goal.name,
            reserved: reservedByGoal[goal.id] ?? 0,
            target: entries[goal.id]?.budget ?? 0,
            iconKey: goal.iconKey,
            timeline: entries[goal.id]?.timeline,
            priority: entries[goal.id]?.priority,
            projection: _projections[goal.id],
          ),
    ];
    for (final entry in reservedByGoal.entries) {
      final known = _catalogue.any((goal) => goal.id == entry.key);
      if (!known) {
        summaries.add(
          GoalSummary(
            name: nameByGoal[entry.key] ?? 'Objetivo',
            reserved: entry.value,
            target: entries[entry.key]?.budget ?? 0,
            timeline: entries[entry.key]?.timeline,
            priority: entries[entry.key]?.priority,
            projection: _projections[entry.key],
          ),
        );
      }
    }
    summaries.sort((a, b) {
      final byReserved = b.reserved.compareTo(a.reserved);
      return byReserved != 0
          ? byReserved
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return summaries;
  }

  /// The template entries in force at the year's start, resolved by the server.
  Map<String, GoalTemplateEntry> _templateEntryByGoal() {
    final template = _applicableTemplate;
    if (template == null) {
      return const {};
    }
    return <String, GoalTemplateEntry>{
      for (final entry in template.entries) entry.goalId: entry,
    };
  }

  /// Loads the goal plans and catalogue for the selected year.
  ///
  /// Reads run sequentially: the API shares a single database connection, so
  /// concurrent requests gain nothing and can stall.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _projections = const {};
    notifyListeners();
    final year = _selectedYear;
    try {
      final goalYear = await _goalsRepository.fetchGoalYear(year);
      final catalogue = await _goalsRepository.fetchGoals();
      final template = await _goalsRepository.fetchApplicableGoalTemplate(
        '$year-01',
      );
      final summary = await _fetchProjections(year);
      if (year != _selectedYear) {
        return;
      }
      final projections = <String, GoalCompletionProjection>{};
      if (summary != null) {
        for (final row in summary.rows) {
          final projection = row.projection;
          if (projection != null) {
            projections[row.goalId] = projection;
          }
        }
      }
      _goalYear = goalYear;
      _catalogue = catalogue;
      _applicableTemplate = template;
      _projections = projections;
    } on ApiFailure catch (failure) {
      if (year == _selectedYear) {
        _errorMessage = failure.message;
      }
    } finally {
      if (year == _selectedYear) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Reads the projections from the yearly summary. A failure here only hides
  /// the projection lines; the rest of the overview still loads.
  Future<GoalYearSummary?> _fetchProjections(int year) async {
    try {
      return await _goalsRepository.fetchGoalYearSummary(year);
    } on ApiFailure {
      return null;
    }
  }

  /// Selects the previous year and reloads.
  void showPreviousYear() {
    if (!canGoToPreviousYear) {
      return;
    }
    _selectedYear--;
    _goalYear = null;
    _projections = const {};
    load();
  }

  /// Selects the next year and reloads.
  void showNextYear() {
    if (!canGoToNextYear) {
      return;
    }
    _selectedYear++;
    _goalYear = null;
    _projections = const {};
    load();
  }
}
