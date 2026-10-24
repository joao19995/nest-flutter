import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/month_transfers.dart';
import 'package:nest/domain/models/monthly_plan.dart';

/// Loads the two closed month views and builds the definitive transfers.
class MonthTransfersViewModel extends ChangeNotifier {
  MonthTransfersViewModel({
    required ExpensesRepository expensesRepository,
    required GoalsRepository goalsRepository,
    required String month,
  }) : _expensesRepository = expensesRepository,
       _goalsRepository = goalsRepository,
       _month = month;

  final ExpensesRepository _expensesRepository;
  final GoalsRepository _goalsRepository;
  final String _month;

  String get month => _month;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MonthlyPlan? _expenses;
  GoalMonthView? _goals;
  Map<String, String?> _iconKeyByGoal = const {};

  bool get expensesClosed => _expenses?.closed ?? false;

  bool get expensesMissing => _expenses == null;

  bool get goalsClosed => _goals?.plan?.closed ?? false;

  bool get goalsMissing => _goals?.plan == null;

  Map<String, String?> get iconKeyByGoal => _iconKeyByGoal;

  MonthTransfers get transfers => MonthTransfers.fromMonths(
    month: _month,
    expenses: _expenses,
    goals: _goals,
  );

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _expenses = await _expensesRepository.fetchMonth(_month);
      _goals = await _goalsRepository.fetchGoalMonth(_month);
      if (_goals?.plan != null) {
        try {
          final catalogue = await _goalsRepository.fetchGoals(
            includeInactive: true,
          );
          _iconKeyByGoal = {
            for (final goal in catalogue) goal.id: goal.iconKey,
          };
        } on ApiFailure {
          _iconKeyByGoal = const {};
        }
      } else {
        _iconKeyByGoal = const {};
      }
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
