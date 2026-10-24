import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/ui/features/expenses/view_models/month_detail_view_model.dart';
import 'package:nest/ui/features/goals/view_models/goal_month_detail_view_model.dart';

/// Coordinates the two month-end balances behind a single close flow.
///
/// It owns the existing expenses and goals month view models, so the wizard
/// reuses their loading, preview and close logic instead of reimplementing it.
class CloseMonthWizardViewModel extends ChangeNotifier {
  CloseMonthWizardViewModel({
    required ExpensesRepository expensesRepository,
    required GoalsRepository goalsRepository,
    required String month,
  }) : _month = month,
       expenses = MonthDetailViewModel(
         expensesRepository: expensesRepository,
         month: month,
       ),
       goals = GoalMonthDetailViewModel(
         goalsRepository: goalsRepository,
         month: month,
       ) {
    expenses.addListener(_onChildChanged);
    goals.addListener(_onChildChanged);
  }

  final String _month;
  final MonthDetailViewModel expenses;
  final GoalMonthDetailViewModel goals;

  String get month => _month;

  bool get expensesClosed => expenses.plan?.closed ?? false;

  bool get goalsClosed => goals.plan?.closed ?? false;

  /// The settlement to show: the recorded one after a close, or the preview
  /// while the expenses month is open.
  MonthSettlement? get expenseSettlement =>
      expenses.plan?.settlement ?? expenses.settlementPreview;

  /// The goals transfers: the close preview while open, the recorded quotas
  /// after the close.
  List<GoalMonthQuota> get goalTransfers =>
      goals.closePreview?.quotas ?? goals.transfers;

  /// Loads both months and their reviews.
  Future<void> load() async {
    await Future.wait([expenses.load(), goals.load()]);
    await _loadPreviews();
  }

  Future<void> retryExpenses() async {
    await expenses.load();
    final plan = expenses.plan;
    if (plan != null && !plan.closed) {
      await expenses.loadSettlementPreview();
    }
  }

  Future<void> retryGoals() async {
    await goals.load();
    final plan = goals.plan;
    if (plan != null && !plan.closed) {
      await goals.loadClosePreview();
    }
  }

  Future<void> createExpenses() async {
    await expenses.createMonth();
    final plan = expenses.plan;
    if (plan != null && !plan.closed) {
      await expenses.loadSettlementPreview();
    }
  }

  Future<void> createGoals() async {
    await goals.createMonth();
    final plan = goals.plan;
    if (plan != null && !plan.closed) {
      await goals.loadClosePreview();
    }
  }

  /// Closes the expenses month; true when it actually ended up closed.
  Future<bool> closeExpenses() async {
    await expenses.closeMonth();
    return expenses.actionError == null && expensesClosed;
  }

  /// Closes the goals month; true when it actually ended up closed.
  Future<bool> closeGoals() async {
    await goals.closeMonth(preview: goals.closePreview);
    return goals.actionError == null && goalsClosed;
  }

  Future<void> _loadPreviews() async {
    final expensePlan = expenses.plan;
    final goalPlan = goals.plan;
    await Future.wait([
      if (expensePlan != null && !expensePlan.closed)
        expenses.loadSettlementPreview(),
      if (goalPlan != null && !goalPlan.closed) goals.loadClosePreview(),
    ]);
  }

  void _onChildChanged() => notifyListeners();

  @override
  void dispose() {
    expenses.removeListener(_onChildChanged);
    goals.removeListener(_onChildChanged);
    expenses.dispose();
    goals.dispose();
    super.dispose();
  }
}
