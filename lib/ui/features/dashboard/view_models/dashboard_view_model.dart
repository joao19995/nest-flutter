import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/calendar_event.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/app_formatters.dart';
import 'package:nest/ui/features/goals/view_models/goals_view_model.dart';

/// The action a dashboard alert invites.
enum DashboardAlertKind {
  /// The month exists but is still open.
  toClose,

  /// The month has not been created yet.
  toCreate,
}

/// A month that needs attention, with the action that resolves it.
class DashboardAlert {
  const DashboardAlert({
    required this.message,
    required this.month,
    required this.kind,
  });

  /// The sentence shown in the dashboard.
  final String message;

  /// The month to open, formatted `YYYY-MM`.
  final String month;

  final DashboardAlertKind kind;
}

/// Presentation state for the dashboard: the household's at-a-glance summary.
///
/// Reads run sequentially — the API shares a single database connection, so
/// concurrent requests gain nothing and can stall.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required ExpensesRepository expensesRepository,
    required GoalsRepository goalsRepository,
    required EventsRepository eventsRepository,
    DateTime? now,
  }) : _expensesRepository = expensesRepository,
       _goalsRepository = goalsRepository,
       _eventsRepository = eventsRepository,
       _now = now ?? DateTime.now(),
       _month = MonthKey.current(),
       _goalsYear = (now ?? DateTime.now()).year,
       _goals = GoalsViewModel(
         goalsRepository: goalsRepository,
         year: (now ?? DateTime.now()).year,
       );

  /// How many days ahead the "Hoje e próximos" list looks.
  static const int _upcomingDays = 6;

  /// The earliest month the stepper can reach.
  static const String _minMonth = '2000-01';

  /// The earliest year the goals stepper can reach.
  static const int _minYear = 2000;

  final ExpensesRepository _expensesRepository;
  final GoalsRepository _goalsRepository;
  final EventsRepository _eventsRepository;
  final DateTime _now;

  GoalsViewModel _goals;
  String _month;
  int _goalsYear;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<DashboardAlert> _alerts = const [];
  List<CalendarEvent> _upcomingEvents = const [];
  List<GoalSummary> _goalsList = const [];
  ExpenseMonthSummary? _monthSummary;

  /// Warnings worth surfacing at the top of the dashboard.
  List<DashboardAlert> get alerts => _alerts;

  /// The events happening today and over the next few days, earliest first.
  List<CalendarEvent> get upcomingEvents => _upcomingEvents;

  /// The goals ordered by reserved amount, most funded first.
  List<GoalSummary> get goals => _goalsList;

  /// The month shown in the header hero, formatted `YYYY-MM`.
  String get month => _month;

  /// The header hero's month summary, or null when the month is not created.
  ExpenseMonthSummary? get monthSummary => _monthSummary;

  /// True while the header can step back a month.
  bool get canGoToPreviousMonth => _month.compareTo(_minMonth) > 0;

  /// True while the header can step forward a month.
  bool get canGoToNextMonth => _month.compareTo('${_now.year + 1}-12') < 0;

  /// The year shown in the goals panel.
  int get goalsYear => _goalsYear;

  /// True while the goals panel can step back a year.
  bool get canGoToPreviousGoalsYear => _goalsYear > _minYear;

  /// True while the goals panel can step forward a year.
  bool get canGoToNextGoalsYear => _goalsYear < _now.year + 1;

  /// Today, at midnight, fixed at construction.
  DateTime get today => DateTime(_now.year, _now.month, _now.day);

  /// The time-of-day greeting for the header.
  String get greeting {
    final hour = _now.hour;
    if (hour < 12) {
      return 'Bom dia';
    }
    if (hour < 20) {
      return 'Boa tarde';
    }
    return 'Boa noite';
  }

  /// Loads every dashboard section.
  Future<void> load() => _load(showSkeleton: true);

  /// Reloads without showing the loading skeleton (pull-to-refresh).
  Future<void> refresh() => _load(showSkeleton: false);

  Future<void> _load({required bool showSkeleton}) async {
    if (showSkeleton) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();
    try {
      final summary = await _expensesRepository.fetchYearSummary(_now.year);
      _alerts = _alertsFrom(summary);

      _upcomingEvents = await _eventsRepository.fetchEvents(
        from: today,
        to: today.add(const Duration(days: _upcomingDays)),
      );

      await _goals.load();
      _readGoals();

      await _loadMonth();
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Steps the header hero back a month and reloads its summary.
  Future<void> showPreviousMonth() async {
    if (!canGoToPreviousMonth) {
      return;
    }
    _month = MonthKey.shift(_month, -1);
    await _reloadMonth();
  }

  /// Steps the header hero forward a month and reloads its summary.
  Future<void> showNextMonth() async {
    if (!canGoToNextMonth) {
      return;
    }
    _month = MonthKey.shift(_month, 1);
    await _reloadMonth();
  }

  Future<void> _reloadMonth() async {
    try {
      await _loadMonth();
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    }
    notifyListeners();
  }

  Future<void> _loadMonth() async {
    final plan = await _expensesRepository.fetchMonth(_month);
    _monthSummary = plan?.summary;
  }

  /// Steps the goals panel back a year and reloads it.
  Future<void> showPreviousGoalsYear() async {
    if (!canGoToPreviousGoalsYear) {
      return;
    }
    _goalsYear--;
    await _reloadGoals();
  }

  /// Steps the goals panel forward a year and reloads it.
  Future<void> showNextGoalsYear() async {
    if (!canGoToNextGoalsYear) {
      return;
    }
    _goalsYear++;
    await _reloadGoals();
  }

  Future<void> _reloadGoals() async {
    _goals.dispose();
    _goals = GoalsViewModel(
      goalsRepository: _goalsRepository,
      year: _goalsYear,
    );
    await _goals.load();
    _readGoals();
    notifyListeners();
  }

  void _readGoals() => _goalsList = _goals.goals;

  /// The alerts implied by the year's month statuses: the current month left
  /// open or uncreated, and the next month not created yet.
  List<DashboardAlert> _alertsFrom(ExpenseYearSummary summary) {
    final current = MonthKey.current();
    final next = MonthKey.shift(current, 1);
    final alerts = <DashboardAlert>[];
    for (final month in summary.months) {
      final name = AppFormatters.monthName(month.month);
      if (month.month == current && month.status == ExpenseMonthStatus.open) {
        alerts.add(
          DashboardAlert(
            message: '$name por fechar',
            month: month.month,
            kind: DashboardAlertKind.toClose,
          ),
        );
      } else if (month.month == current &&
          month.status == ExpenseMonthStatus.missing) {
        alerts.add(
          DashboardAlert(
            message: '$name ainda não criado',
            month: month.month,
            kind: DashboardAlertKind.toCreate,
          ),
        );
      } else if (month.month == next &&
          month.status == ExpenseMonthStatus.missing) {
        alerts.add(
          DashboardAlert(
            message: '$name ainda não criado',
            month: month.month,
            kind: DashboardAlertKind.toCreate,
          ),
        );
      }
    }
    return alerts;
  }

  @override
  void dispose() {
    _goals.dispose();
    super.dispose();
  }
}
