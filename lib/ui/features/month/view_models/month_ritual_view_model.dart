import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/monthly_plan.dart';
import 'package:nest/ui/core/month_focus.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/features/month/month_ritual.dart';

/// Presentation state for the Mês tab's closing ritual.
///
/// Reads the displayed month's expense plan, goals month and year strip
/// sequentially (the API shares one database connection) and maps the values
/// the API already computed onto [MonthRitual]. It fetches nothing else and
/// derives no financial rule.
class MonthRitualViewModel extends ChangeNotifier {
  factory MonthRitualViewModel({
    required ExpensesRepository expensesRepository,
    required GoalsRepository goalsRepository,
    DateTime? now,
    DateTime Function()? clock,
  }) {
    final resolvedNow = now ?? (clock ?? DateTime.now)();
    return MonthRitualViewModel._(
      expensesRepository: expensesRepository,
      goalsRepository: goalsRepository,
      now: resolvedNow,
      clock: clock ?? (now == null ? DateTime.now : () => resolvedNow),
    );
  }

  MonthRitualViewModel._({
    required ExpensesRepository expensesRepository,
    required GoalsRepository goalsRepository,
    required DateTime now,
    required DateTime Function() clock,
  }) : _expensesRepository = expensesRepository,
       _goalsRepository = goalsRepository,
       _now = now,
       _clock = clock,
       _month = MonthKey.of(now.year, now.month);

  /// The earliest month the stepper can reach.
  static const String _minMonth = '2000-01';

  final ExpensesRepository _expensesRepository;
  final GoalsRepository _goalsRepository;

  /// Supplies the current time. Tests pin it through [MonthRitualViewModel.new].
  final DateTime Function() _clock;

  DateTime _now;
  String _month;

  /// True once the user has stepped away from the current month, so a refresh
  /// does not yank the selection back.
  bool _monthSelected = false;

  bool _isLoading = true;
  String? _errorMessage;

  MonthlyPlan? _expenseMonth;
  GoalMonthView? _goalMonth;
  List<ExpenseMonthSummary> _yearMonths = const [];

  /// The displayed month, formatted `YYYY-MM`.
  String get month => _month;

  /// True when the ritual is showing the previous month because its balance
  /// is still due.
  bool get isBalanceFocus {
    if (!MonthFocus.isBalanceWindow(_now)) {
      return false;
    }
    if (_month != MonthFocus.previousMonth(_now)) {
      return false;
    }
    final status = _expenseMonth?.summary.status ?? _statusOfMonths(_month);
    return status != null && status != ExpenseMonthStatus.closed;
  }

  /// The year of the displayed month.
  int get year => int.tryParse(_month.split('-').first) ?? _now.year;

  /// True while the month can step back.
  bool get canGoToPreviousMonth => _month.compareTo(_minMonth) > 0;

  /// True while the month can step forward.
  bool get canGoToNextMonth => _month.compareTo('${_now.year + 1}-12') < 0;

  /// True while the ritual is being fetched.
  bool get isLoading => _isLoading;

  /// The failure to surface for the displayed month, or null.
  String? get errorMessage => _errorMessage;

  /// The displayed month's year, for the year strip.
  List<ExpenseMonthSummary> get yearMonths => _yearMonths;

  /// The closing ritual of the displayed month, built from the API values.
  ///
  /// Never null: a missing expense month reads as missing with zero counters,
  /// and a missing goals month as missing with zero totals.
  MonthRitual get ritual {
    final expense = _expenseMonth?.summary;
    final goalView = _goalMonth;
    final goalPlan = goalView?.plan;
    return MonthRitual(
      month: _month,
      expensesStatus: expense?.status ?? ExpenseMonthStatus.missing,
      filledEntries: expense?.filledEntries ?? 0,
      totalEntries: expense?.totalEntries ?? 0,
      expensesPlanned: expense?.planned ?? 0,
      expensesActual: expense?.actual ?? 0,
      goalsStatus: goalPlan == null
          ? ExpenseMonthStatus.missing
          : goalPlan.closed
          ? ExpenseMonthStatus.closed
          : ExpenseMonthStatus.open,
      goalsReserved: goalView?.totals.reserved ?? 0,
      goalsPlanned: goalView?.totals.planned ?? 0,
    );
  }

  /// Loads the displayed month, its goals month and its year strip, showing the
  /// loading skeleton.
  Future<void> load() => _load(showSkeleton: true);

  /// Reloads without showing the loading skeleton (pull-to-refresh, returning
  /// from the close wizard and the shell's refresh signal). Keeps the current
  /// data on screen until the new payload lands.
  Future<void> refresh() => _load(showSkeleton: false);

  Future<void> _load({required bool showSkeleton}) async {
    _now = _clock();
    if (!_monthSelected) {
      _month = MonthKey.of(_now.year, _now.month);
    }
    var month = _month;
    if (showSkeleton) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();
    try {
      final (focusedMonth, summary) = await _resolveFocusedMonth();
      month = focusedMonth;
      if (month != _month) {
        return;
      }
      final expense = await _expensesRepository.fetchMonth(month);
      if (month != _month) {
        return;
      }
      final goals = await _goalsRepository.fetchGoalMonth(month);
      if (month != _month) {
        return;
      }
      _expenseMonth = expense;
      _goalMonth = goals;
      _yearMonths = summary.months;
    } on ApiFailure catch (failure) {
      if (month != _month) {
        return;
      }
      _errorMessage = failure.message;
    } finally {
      if (month == _month) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// The month to load plus the year summary that backs its strip.
  ///
  /// While the previous month's balance is due, it moves the ritual to that
  /// month; once the user steps away, their choice wins.
  Future<(String, ExpenseYearSummary)> _resolveFocusedMonth() async {
    final current = MonthKey.of(_now.year, _now.month);
    final month = _monthSelected ? _month : current;
    var summary = await _expensesRepository.fetchYearSummary(_yearOf(month));
    if (month != _month) {
      // The user stepped while the summary was loading; let the newer load own
      // the state.
      return (month, summary);
    }
    if (_monthSelected ||
        !MonthFocus.isBalanceWindow(_now) ||
        month != current) {
      return (month, summary);
    }
    final previous = MonthFocus.previousMonth(_now);
    var status = _statusOf(summary, previous);
    if (status == null && _now.month == DateTime.january) {
      // January: the balance due is December of the previous year.
      final previousYear = int.tryParse(previous.substring(0, 4));
      if (previousYear != null) {
        final previousSummary = await _expensesRepository.fetchYearSummary(
          previousYear,
        );
        summary = previousSummary;
        status = _statusOf(summary, previous);
        if (month != _month) {
          return (month, summary);
        }
      }
    }
    if (MonthFocus.resolve(now: _now, previousStatus: status) == current) {
      return (current, summary);
    }
    _month = previous;
    return (previous, summary);
  }

  ExpenseMonthStatus? _statusOf(ExpenseYearSummary summary, String month) {
    for (final candidate in summary.months) {
      if (candidate.month == month) {
        return candidate.status;
      }
    }
    return null;
  }

  ExpenseMonthStatus? _statusOfMonths(String month) {
    for (final candidate in _yearMonths) {
      if (candidate.month == month) {
        return candidate.status;
      }
    }
    return null;
  }

  int _yearOf(String month) =>
      int.tryParse(month.split('-').first) ?? _now.year;

  /// Steps back a month and reloads the ritual.
  Future<void> showPreviousMonth() async {
    if (!canGoToPreviousMonth) {
      return;
    }
    _monthSelected = true;
    _month = MonthKey.shift(_month, -1);
    await load();
  }

  /// Steps forward a month and reloads the ritual.
  Future<void> showNextMonth() async {
    if (!canGoToNextMonth) {
      return;
    }
    _monthSelected = true;
    _month = MonthKey.shift(_month, 1);
    await load();
  }
}
