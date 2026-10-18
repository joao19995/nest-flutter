import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/domain/models/goal_year.dart';
import 'package:nest/ui/core/month_key.dart';

/// One month in the yearly goals overview.
class GoalMonthSummary {
  const GoalMonthSummary({
    required this.month,
    required this.reserved,
    required this.available,
    required this.fundedCount,
    required this.hasPlan,
  });

  /// The month, formatted `YYYY-MM`.
  final String month;

  /// The amount reserved for goals in the month, in euros.
  final double reserved;

  /// The amount available for goals in the month, in euros.
  final double available;

  /// How many goals received an allocation this month.
  final int fundedCount;

  /// False when the month has no saved plan yet.
  final bool hasPlan;
}

/// A goal's total across the year.
class GoalSummary {
  const GoalSummary({
    required this.name,
    required this.reserved,
    required this.target,
  });

  final String name;

  /// The amount reserved for the goal across the year, in euros.
  final double reserved;

  /// The goal's annual saving target, in euros. Zero when none is defined.
  final double target;

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
  List<GoalTemplate> _templates = const [];

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
          available: availableByMonth[key] ?? 0,
          fundedCount: plan?.fundedCount ?? 0,
          hasPlan: plan != null,
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
    final targets = _targetByGoal();
    final summaries = <GoalSummary>[
      for (final goal in _catalogue)
        if (goal.active)
          GoalSummary(
            name: nameByGoal[goal.id] ?? goal.name,
            reserved: reservedByGoal[goal.id] ?? 0,
            target: targets[goal.id] ?? 0,
          ),
    ];
    for (final entry in reservedByGoal.entries) {
      final known = _catalogue.any((goal) => goal.id == entry.key);
      if (!known) {
        summaries.add(
          GoalSummary(
            name: nameByGoal[entry.key] ?? 'Objetivo',
            reserved: entry.value,
            target: targets[entry.key] ?? 0,
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

  /// The goal budgets of the template version in force at the year's start,
  /// falling back to the latest version — matching the annual plan semantics.
  Map<String, double> _targetByGoal() {
    if (_templates.isEmpty) {
      return const {};
    }
    final sorted = [..._templates]
      ..sort((a, b) => a.validFrom.compareTo(b.validFrom));
    final start = '$_selectedYear-01';
    GoalTemplate? applicable;
    for (final template in sorted) {
      if (template.validFrom.compareTo(start) <= 0) {
        applicable = template;
      }
    }
    final template = applicable ?? sorted.last;
    return <String, double>{
      for (final entry in template.entries) entry.goalId: entry.budget,
    };
  }

  /// Loads the goal plans and catalogue for the selected year.
  ///
  /// Reads run sequentially: the API shares a single database connection, so
  /// concurrent requests gain nothing and can stall.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final year = _selectedYear;
    try {
      final goalYear = await _goalsRepository.fetchGoalYear(year);
      final catalogue = await _goalsRepository.fetchGoals();
      final templates = await _goalsRepository.fetchGoalTemplates();
      if (year != _selectedYear) {
        return;
      }
      _goalYear = goalYear;
      _catalogue = catalogue;
      _templates = templates;
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

  /// Selects the previous year and reloads.
  void showPreviousYear() {
    if (!canGoToPreviousYear) {
      return;
    }
    _selectedYear--;
    _goalYear = null;
    load();
  }

  /// Selects the next year and reloads.
  void showNextYear() {
    if (!canGoToNextYear) {
      return;
    }
    _selectedYear++;
    _goalYear = null;
    load();
  }
}
