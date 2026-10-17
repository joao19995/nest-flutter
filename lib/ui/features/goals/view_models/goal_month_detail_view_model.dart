import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal_transfer.dart';
import 'package:nest/domain/models/goal_year.dart';
import 'package:nest/domain/models/person_income.dart';

/// Presentation state for a single month's goal detail.
class GoalMonthDetailViewModel extends ChangeNotifier {
  GoalMonthDetailViewModel({
    required GoalsRepository goalsRepository,
    required PeopleRepository peopleRepository,
    required String month,
  }) : _goalsRepository = goalsRepository,
       _peopleRepository = peopleRepository,
       _month = month;

  /// Months with a fixed bonus (June and December allowances).
  static const List<int> _bonusMonths = [6, 12];

  /// The tolerance under which an amount is treated as zero.
  static const double _epsilon = 0.005;

  final GoalsRepository _goalsRepository;
  final PeopleRepository _peopleRepository;

  final String _month;
  String get month => _month;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GoalPlan? _plan;
  GoalPlan? get plan => _plan;

  List<GoalTransfer> _transfers = const [];

  /// Who transfers what towards this month's goals.
  List<GoalTransfer> get transfers => _transfers;

  List<GoalEarning> _earnings = const [];

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  String? _actionError;
  String? get actionError => _actionError;

  /// True when the month is created and still open for editing.
  bool get isOpen {
    final plan = _plan;
    return plan != null && !plan.closed;
  }

  /// The month's total planned, in euros.
  double get planned =>
      _plan?.allocations.fold<double>(0, (sum, item) => sum + item.planned) ??
      0;

  /// The month's total reserved, in euros.
  double get reserved => _plan?.reserved ?? 0;

  /// The month's available amount, in euros.
  double get available => _plan?.availableAmount ?? 0;

  /// Loads the plan of the selected month and the monthly transfers.
  ///
  /// Reads run sequentially: the API shares a single database connection.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _actionError = null;
    notifyListeners();
    final month = _month;
    try {
      final plan = await _goalsRepository.fetchGoalMonth(month);
      final earnings = plan == null
          ? const <GoalEarning>[]
          : await _loadEarnings(month);
      final transfers = plan == null
          ? const <GoalTransfer>[]
          : _distribute(plan, earnings);
      if (month != _month) {
        return;
      }
      _earnings = earnings;
      _plan = plan;
      _transfers = transfers;
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

  /// Saves the reserved amount of [goalId] in the open month.
  Future<void> updateAllocationActual(String goalId, double actual) async {
    final plan = _plan;
    if (plan == null || plan.closed || _isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      final updated = await _goalsRepository.updateGoalAllocation(
        plan.id,
        goalId,
        actual,
      );
      _plan = updated;
      _transfers = _distribute(updated, _earnings);
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
    final plan = _plan;
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
            current.id,
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
      final closed = await _goalsRepository.closeGoalPlan(current.id);
      _plan = closed;
      _transfers = _distribute(closed, _earnings);
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  List<GoalTransfer> _distribute(GoalPlan plan, List<GoalEarning> earnings) {
    if (plan.reserved <= 0) {
      return const [];
    }
    return GoalTransfer.distribute(
      reservedTotal: plan.reserved,
      earnings: earnings,
      goals: <GoalTransferPart>[
        for (final allocation in plan.allocations)
          GoalTransferPart(
            goalId: allocation.goalId,
            name: allocation.goalName,
            amount: allocation.actual,
          ),
      ],
    );
  }

  Future<List<GoalEarning>> _loadEarnings(String month) async {
    final people = await _peopleRepository.fetchPeople();
    final bonus = _bonusMonths.contains(_monthNumber(month));
    final earnings = <GoalEarning>[];
    for (final person in people) {
      final incomes = await _peopleRepository.fetchIncomes(person.id);
      final salary =
          PersonIncome.applicableFor(incomes, person.id, month)?.amount ?? 0;
      earnings.add(
        GoalEarning(
          personId: person.id,
          name: person.name,
          earning: bonus ? salary * 2 : salary,
        ),
      );
    }
    return earnings;
  }

  static int _monthNumber(String month) =>
      int.tryParse(month.length >= 7 ? month.substring(5, 7) : '') ?? 0;
}
