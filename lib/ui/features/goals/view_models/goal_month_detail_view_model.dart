import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/goal_year.dart';

/// Presentation state for a single month's goal detail.
///
/// The month's plan, available amount and per-person quotas all come from the
/// server (`GET /api/goal-plan/{month}`); the client only edits the reserved
/// values and asks the server to recompute the quotas.
class GoalMonthDetailViewModel extends ChangeNotifier {
  GoalMonthDetailViewModel({
    required GoalsRepository goalsRepository,
    required String month,
  }) : _goalsRepository = goalsRepository,
       _month = month;

  /// The tolerance under which an amount is treated as zero.
  static const double _epsilon = 0.005;

  final GoalsRepository _goalsRepository;

  final String _month;
  String get month => _month;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GoalMonthView? _view;

  GoalPlan? get plan => _view?.plan;

  /// Who transfers what towards this month's goals, computed by the server.
  List<GoalMonthQuota> get transfers => _view?.quotas ?? const [];

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  String? _actionError;
  String? get actionError => _actionError;

  /// True when the month is created and still open for editing.
  bool get isOpen {
    final plan = _view?.plan;
    return plan != null && !plan.closed;
  }

  /// The month's total planned, in euros.
  double get planned =>
      _view?.plan?.allocations.fold<double>(
        0,
        (sum, item) => sum + item.planned,
      ) ??
      0;

  /// The month's total reserved, in euros.
  double get reserved => _view?.plan?.reserved ?? 0;

  /// The month's available amount, in euros.
  double get available => _view?.availableAmount ?? 0;

  /// Loads the month view (plan, available amount and quotas).
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _actionError = null;
    notifyListeners();
    final month = _month;
    try {
      final view = await _goalsRepository.fetchGoalMonth(month);
      if (month != _month) {
        return;
      }
      _view = view;
    } on ApiFailure catch (failure) {
      if (month == _month) {
        _errorMessage = failure.message;
      }
    } finally {
      if (month == _month) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Creates the selected month from the applicable template.
  Future<void> createMonth() async {
    if (_isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      await _goalsRepository.createGoalPlan(_month);
      _isBusy = false;
      await load();
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Saves the reserved amount of [goalId] in the open month and refreshes the
  /// quotas from the server.
  Future<void> updateAllocationActual(String goalId, double actual) async {
    final plan = _view?.plan;
    if (plan == null || plan.closed || _isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      final updated = await _goalsRepository.updateGoalAllocation(
        _month,
        goalId,
        actual,
      );
      final quotas = await _goalsRepository.computeGoalQuotas(
        _month,
        _drafts(updated),
      );
      final view = _view;
      if (view != null) {
        _view = GoalMonthView(
          plan: updated,
          availableAmount: view.availableAmount,
          quotas: quotas,
        );
      }
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Saves untouched reserved amounts, distributes what is missing and closes
  /// the month. The reserved defaults to the planned value per goal.
  Future<void> closeMonth() async {
    final plan = _view?.plan;
    if (plan == null || plan.closed || _isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      var current = plan;
      for (final allocation in plan.allocations) {
        if (allocation.actual <= _epsilon && allocation.planned > 0) {
          current = await _goalsRepository.updateGoalAllocation(
            _month,
            allocation.goalId,
            allocation.planned,
          );
        }
      }
      final plannedTotal = current.allocations.fold<double>(
        0,
        (sum, item) => sum + item.planned,
      );
      if ((current.availableAmount - plannedTotal).abs() > _epsilon) {
        await _goalsRepository.adjustGoalPlanFromTemplate(_month);
      }
      await _goalsRepository.closeGoalPlan(_month);
      _isBusy = false;
      await load();
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      _isBusy = false;
      notifyListeners();
    }
  }

  /// The reserved value each allocation contributes to the quotas: the actual
  /// when set, otherwise the planned (the pre-fill convention, server-side).
  List<GoalQuotaDraft> _drafts(GoalPlan plan) => [
    for (final allocation in plan.allocations)
      (
        goalId: allocation.goalId,
        name: allocation.goalName,
        amount: plan.closed
            ? allocation.actual
            : allocation.actual > 0
            ? allocation.actual
            : allocation.planned,
      ),
  ];
}
