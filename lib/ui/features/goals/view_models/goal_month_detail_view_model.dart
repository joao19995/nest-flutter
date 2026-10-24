import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/domain/models/goal_close_preview.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/goal_year.dart';

/// Presentation state for a single month's goal detail.
///
/// The month's plan, available amount and per-person quotas all come from the
/// server (`GET /api/goal-plan/{month}` and the writes that return the same
/// view); the client only edits the reserved values.
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
  Map<String, String?> _iconKeyByGoal = const {};

  GoalPlan? get plan => _view?.plan;

  /// The catalogue's semantic icon keys, by goal id, for the month's rows.
  Map<String, String?> get iconKeyByGoal => _iconKeyByGoal;

  /// Who transfers what towards this month's goals, computed by the server.
  List<GoalMonthQuota> get transfers => _view?.quotas ?? const [];

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  String? _actionError;
  String? get actionError => _actionError;

  /// The current funding breakdown, with the available projection.
  MonthFunding? get funding => _view?.funding;

  /// The server-derived month totals, including the effective reserved.
  GoalMonthTotals? get totals => _view?.totals;

  /// The close preview, loaded without writing anything.
  GoalClosePreview? _closePreview;
  GoalClosePreview? get closePreview => _closePreview;

  /// The last preview failure, shown inside the close dialog.
  String? _previewError;
  String? get previewError => _previewError;

  bool _isPreviewLoading = false;
  bool get isPreviewLoading => _isPreviewLoading;

  /// True when the month is created and still open for editing.
  bool get isOpen {
    final plan = _view?.plan;
    return plan != null && !plan.closed;
  }

  /// The month's total planned, in euros.
  double get planned => _view?.totals.planned ?? 0;

  /// The month's effective reserved total, in euros.
  double get reserved => _view?.totals.reserved ?? 0;

  /// The month's available amount, in euros.
  double get available => _view?.availableAmount ?? 0;

  /// What the current plan leaves to allocate, in euros.
  double get unallocated => available - planned;

  /// Loads the month view (plan, available amount and quotas).
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _actionError = null;
    _closePreview = null;
    _previewError = null;
    notifyListeners();
    final month = _month;
    try {
      final view = await _goalsRepository.fetchGoalMonth(month);
      final goals = view?.plan == null
          ? <Goal>[]
          : await _goalsRepository.fetchGoals(includeInactive: true);
      if (month != _month) {
        return;
      }
      _view = view;
      _iconKeyByGoal = {for (final goal in goals) goal.id: goal.iconKey};
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
      _closePreview = null;
      _isBusy = false;
      await load();
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Saves the reserved amount of [goalId] in the open month; the server
  /// returns the fresh view with the recomputed quotas.
  Future<void> updateAllocationActual(String goalId, double actual) async {
    final plan = _view?.plan;
    if (plan == null || plan.closed || _isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      _view = await _goalsRepository.updateGoalAllocation(
        _month,
        goalId,
        actual,
      );
      _closePreview = null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Loads what closing the month would do, without writing anything.
  Future<void> loadClosePreview() async {
    if (_isPreviewLoading) {
      return;
    }
    _isPreviewLoading = true;
    _previewError = null;
    _closePreview = null;
    notifyListeners();
    try {
      _closePreview = await _goalsRepository.fetchGoalClosePreview(_month);
    } on ApiFailure catch (failure) {
      _previewError = failure.message;
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  /// Saves untouched reserved amounts, distributes what is missing and closes
  /// the month. The reserved defaults to the planned value per goal.
  ///
  /// When [preview] is given, its server-computed defaulted lines and
  /// adjustment decision drive the close, so the dialog's numbers are what
  /// actually happens.
  Future<void> closeMonth({GoalClosePreview? preview}) async {
    final initial = _view;
    final startPlan = initial?.plan;
    if (initial == null || startPlan == null || startPlan.closed || _isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      if (preview != null) {
        for (final item in preview.defaulted) {
          _view = await _goalsRepository.updateGoalAllocation(
            _month,
            item.goalId,
            item.amount,
          );
        }
        if (preview.adjustedFromTemplate) {
          await _goalsRepository.adjustGoalPlanFromTemplate(_month);
        }
      } else {
        var view = initial;
        for (final allocation in startPlan.allocations) {
          if (allocation.actual <= _epsilon && allocation.planned > 0) {
            view = await _goalsRepository.updateGoalAllocation(
              _month,
              allocation.goalId,
              allocation.planned,
            );
          }
        }
        final current = view.plan;
        if (current != null) {
          final plannedTotal = current.allocations.fold<double>(
            0,
            (sum, item) => sum + item.planned,
          );
          if ((current.availableAmount - plannedTotal).abs() > _epsilon) {
            await _goalsRepository.adjustGoalPlanFromTemplate(_month);
          }
        }
        _view = view;
      }
      _view = await _goalsRepository.closeGoalPlan(_month);
      _closePreview = null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
