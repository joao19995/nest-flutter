import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/calendar_event.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/domain/models/goal_template.dart';
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

/// The loading/error state of one dashboard section.
///
/// Each section loads and fails on its own, so a failing events request never
/// hides the hero or the alerts.
class DashboardSectionState {
  const DashboardSectionState({this.isLoading = false, this.errorMessage});

  /// True while the section is being fetched.
  final bool isLoading;

  /// The failure to surface in the section, or null.
  final String? errorMessage;
}

/// The state of one month's closing ritual.
class DashboardRitual {
  const DashboardRitual({
    required this.month,
    required this.expensesStatus,
    required this.filledEntries,
    required this.totalEntries,
    required this.goalsStatus,
    required this.goalsReserved,
    required this.goalsPlanned,
  });

  /// The month, formatted `YYYY-MM`.
  final String month;

  final ExpenseMonthStatus expensesStatus;

  /// Lines already filled in the month (server rule).
  final int filledEntries;

  /// Lines the month has (server rule).
  final int totalEntries;

  /// The goals month status; null while its plan data is not loaded.
  final ExpenseMonthStatus? goalsStatus;

  /// The amount reserved for goals in the month, in euros.
  final double goalsReserved;

  /// The amount planned for goals in the month, in euros.
  final double goalsPlanned;

  /// True when both areas are closed (or goals have no plan to close).
  bool get isClosed =>
      expensesStatus == ExpenseMonthStatus.closed &&
      (goalsStatus == null || goalsStatus == ExpenseMonthStatus.closed);

  /// True when the month has nothing to close yet.
  bool get isMissing =>
      expensesStatus == ExpenseMonthStatus.missing &&
      (goalsStatus == null || goalsStatus == ExpenseMonthStatus.missing);
}

/// Presentation state for the dashboard: the household's at-a-glance summary.
///
/// Each section loads sequentially — the API shares a single database
/// connection, so concurrent requests gain nothing and can stall — but their
/// loading and failure states are independent.
class DashboardViewModel extends ChangeNotifier {
  factory DashboardViewModel({
    required ExpensesRepository expensesRepository,
    required GoalsRepository goalsRepository,
    required EventsRepository eventsRepository,
    DateTime? now,
    DateTime Function()? clock,
  }) {
    final resolvedNow = now ?? (clock ?? DateTime.now)();
    return DashboardViewModel._(
      expensesRepository: expensesRepository,
      goalsRepository: goalsRepository,
      eventsRepository: eventsRepository,
      now: resolvedNow,
      clock: clock ?? (now == null ? DateTime.now : () => resolvedNow),
    );
  }

  DashboardViewModel._({
    required ExpensesRepository expensesRepository,
    required GoalsRepository goalsRepository,
    required EventsRepository eventsRepository,
    required DateTime now,
    required DateTime Function() clock,
  }) : _expensesRepository = expensesRepository,
       _goalsRepository = goalsRepository,
       _eventsRepository = eventsRepository,
       _now = now,
       _clock = clock,
       _month = MonthKey.of(now.year, now.month),
       _goalsYear = now.year,
       _goals = GoalsViewModel(
         goalsRepository: goalsRepository,
         year: now.year,
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

  /// Supplies the current time. Tests pin it with [DashboardViewModel.new].
  final DateTime Function() _clock;

  DateTime _now;

  GoalsViewModel _goals;
  String _month;
  int _goalsYear;

  /// True once the user has stepped away from the current month/year, so a
  /// refresh does not yank the selection back.
  bool _monthSelected = false;
  bool _goalsYearSelected = false;

  bool _isFetching = false;

  /// True while any dashboard section is being fetched.
  bool get isLoading => _isFetching;

  DashboardSectionState _monthSection = const DashboardSectionState(
    isLoading: true,
  );
  DashboardSectionState _alertsSection = const DashboardSectionState(
    isLoading: true,
  );
  DashboardSectionState _stripSection = const DashboardSectionState(
    isLoading: true,
  );
  DashboardSectionState _eventsSection = const DashboardSectionState(
    isLoading: true,
  );
  DashboardSectionState _goalsSection = const DashboardSectionState(
    isLoading: true,
  );

  List<DashboardAlert> _alerts = const [];
  List<CalendarEvent> _upcomingEvents = const [];
  List<GoalSummary> _goalsList = const [];
  List<ExpenseMonthSummary> _yearMonths = const [];
  ExpenseMonthSummary? _monthSummary;

  /// The header hero's loading state.
  DashboardSectionState get monthSection => _monthSection;

  /// The alerts card's loading state.
  DashboardSectionState get alertsSection => _alertsSection;

  /// The year strip's loading state.
  DashboardSectionState get stripSection => _stripSection;

  /// The upcoming events section's loading state.
  DashboardSectionState get eventsSection => _eventsSection;

  /// The goals section's loading state.
  DashboardSectionState get goalsSection => _goalsSection;

  /// Warnings worth surfacing at the top of the dashboard.
  List<DashboardAlert> get alerts => _alerts;

  /// The events happening today and over the next few days, earliest first.
  List<CalendarEvent> get upcomingEvents => _upcomingEvents;

  /// The goals ordered by timeline, priority and what is still missing.
  List<GoalSummary> get goals => _goalsList;

  /// The selected year's twelve months, for the year strip.
  List<ExpenseMonthSummary> get yearMonths => _yearMonths;

  /// The goals month matching [month], when its year is loaded.
  GoalMonthSummary? get goalMonth {
    final year = int.tryParse(_month.split('-').first);
    if (year == null || year != _goalsYear) {
      return null;
    }
    for (final month in _goals.months) {
      if (month.month == _month) {
        return month;
      }
    }
    return null;
  }

  /// The month's closing state: expenses, goals and their totals. Null while
  /// the month data is loading.
  DashboardRitual? get ritual {
    final expense = _monthSummary ?? _stripMonth;
    if (expense == null && _monthSection.isLoading) {
      return null;
    }
    final goal = goalMonth;
    return DashboardRitual(
      month: _month,
      expensesStatus: expense?.status ?? ExpenseMonthStatus.missing,
      filledEntries: expense?.filledEntries ?? 0,
      totalEntries: expense?.totalEntries ?? 0,
      goalsStatus: goal == null
          ? null
          : !goal.hasPlan
          ? ExpenseMonthStatus.missing
          : goal.closed
          ? ExpenseMonthStatus.closed
          : ExpenseMonthStatus.open,
      goalsReserved: goal?.reserved ?? 0,
      goalsPlanned: goal?.planned ?? 0,
    );
  }

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

  /// Today, at midnight, in the current clock.
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

  /// Loads every dashboard section, showing skeletons.
  Future<void> load() => _load(showSkeleton: true);

  /// Reloads without showing the loading skeleton (pull-to-refresh, tab and
  /// app resume). Keeps the previous data on screen until each refresh lands.
  Future<void> refresh() => _load(showSkeleton: false);

  Future<void> _load({required bool showSkeleton}) async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    try {
      final wasCurrent = MonthKey.of(_now.year, _now.month);
      _now = _clock();
      if (!_monthSelected || _month == wasCurrent) {
        _month = MonthKey.of(_now.year, _now.month);
      }
      if (!_goalsYearSelected && _goalsYear != _now.year) {
        _goalsYear = _now.year;
        _replaceGoals();
      }

      _monthSection = DashboardSectionState(isLoading: showSkeleton);
      _alertsSection = DashboardSectionState(isLoading: showSkeleton);
      _stripSection = DashboardSectionState(isLoading: showSkeleton);
      _eventsSection = DashboardSectionState(isLoading: showSkeleton);
      _goalsSection = DashboardSectionState(isLoading: showSkeleton);
      notifyListeners();

      await _loadMonth(showLoading: showSkeleton && _monthSummary == null);
      await _loadYear(showLoading: showSkeleton);
      await _loadEvents(showLoading: showSkeleton);
      await _loadGoals(showLoading: showSkeleton);
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Retries the header hero after a failure.
  Future<void> retryMonth() => _runSection(_loadMonth);

  /// Retries the alerts year summary after a failure.
  Future<void> retryAlerts() => _runSection(() => _loadYear(showLoading: true));

  /// Retries the year strip after a failure.
  Future<void> retryStrip() => _runSection(_loadStrip);

  /// Retries the upcoming events after a failure.
  Future<void> retryEvents() => _runSection(_loadEvents);

  /// Retries the goals after a failure.
  Future<void> retryGoals() => _runSection(_loadGoals);

  Future<void> _runSection(Future<void> Function() action) async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    try {
      await action();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Steps the header hero back a month and reloads its summary.
  Future<void> showPreviousMonth() async {
    if (!canGoToPreviousMonth) {
      return;
    }
    _monthSelected = true;
    final previousYear = _stripYear;
    _month = MonthKey.shift(_month, -1);
    await _loadMonth(showLoading: false);
    if (_stripYear != previousYear) {
      await _loadStrip();
    }
  }

  /// Steps the header hero forward a month and reloads its summary.
  Future<void> showNextMonth() async {
    if (!canGoToNextMonth) {
      return;
    }
    _monthSelected = true;
    final previousYear = _stripYear;
    _month = MonthKey.shift(_month, 1);
    await _loadMonth(showLoading: false);
    if (_stripYear != previousYear) {
      await _loadStrip();
    }
  }

  Future<void> _loadMonth({bool showLoading = true}) async {
    if (showLoading) {
      _monthSection = const DashboardSectionState(isLoading: true);
      notifyListeners();
    }
    try {
      final plan = await _expensesRepository.fetchMonth(_month);
      _monthSummary = plan?.summary;
      _monthSection = const DashboardSectionState();
    } on ApiFailure catch (failure) {
      _monthSection = DashboardSectionState(errorMessage: failure.message);
    }
    notifyListeners();
  }

  Future<void> _loadYear({required bool showLoading}) async {
    final displayYear = _stripYear;
    if (showLoading) {
      _alertsSection = const DashboardSectionState(isLoading: true);
      _stripSection = const DashboardSectionState(isLoading: true);
      notifyListeners();
    }
    try {
      final current = await _expensesRepository.fetchYearSummary(_now.year);
      _alerts = _alertsFrom(current);
      _alertsSection = const DashboardSectionState();
      if (displayYear == _now.year) {
        _yearMonths = current.months;
        _stripSection = const DashboardSectionState();
      }
    } on ApiFailure catch (failure) {
      _alertsSection = DashboardSectionState(errorMessage: failure.message);
      if (displayYear == _now.year) {
        _stripSection = DashboardSectionState(errorMessage: failure.message);
      }
    }
    notifyListeners();

    if (displayYear != _now.year) {
      await _loadStrip(showLoading: false);
    }
  }

  Future<void> _loadStrip({bool showLoading = true}) async {
    if (showLoading) {
      _stripSection = const DashboardSectionState(isLoading: true);
      notifyListeners();
    }
    try {
      final display = await _expensesRepository.fetchYearSummary(_stripYear);
      _yearMonths = display.months;
      _stripSection = const DashboardSectionState();
    } on ApiFailure catch (failure) {
      _stripSection = DashboardSectionState(errorMessage: failure.message);
    }
    notifyListeners();
  }

  Future<void> _loadEvents({bool showLoading = true}) async {
    if (showLoading) {
      _eventsSection = const DashboardSectionState(isLoading: true);
      notifyListeners();
    }
    try {
      _upcomingEvents = await _eventsRepository.fetchEvents(
        from: today,
        to: today.add(const Duration(days: _upcomingDays)),
      );
      _eventsSection = const DashboardSectionState();
    } on ApiFailure catch (failure) {
      _eventsSection = DashboardSectionState(errorMessage: failure.message);
    }
    notifyListeners();
  }

  Future<void> _loadGoals({bool showLoading = true}) async {
    if (showLoading) {
      _goalsSection = const DashboardSectionState(isLoading: true);
      notifyListeners();
    }
    await _goals.load();
    _readGoals();
    final message = _goals.errorMessage;
    _goalsSection = message == null
        ? const DashboardSectionState()
        : DashboardSectionState(errorMessage: message);
    notifyListeners();
  }

  /// Steps the goals panel back a year and reloads it.
  Future<void> showPreviousGoalsYear() async {
    if (!canGoToPreviousGoalsYear) {
      return;
    }
    _goalsYearSelected = true;
    _goalsYear--;
    _replaceGoals();
    await _loadGoals();
  }

  /// Steps the goals panel forward a year and reloads it.
  Future<void> showNextGoalsYear() async {
    if (!canGoToNextGoalsYear) {
      return;
    }
    _goalsYearSelected = true;
    _goalsYear++;
    _replaceGoals();
    await _loadGoals();
  }

  void _replaceGoals() {
    _goals.dispose();
    _goals = GoalsViewModel(
      goalsRepository: _goalsRepository,
      year: _goalsYear,
    );
  }

  void _readGoals() {
    final goals = [..._goals.goals];
    goals.sort(_compareGoals);
    _goalsList = goals;
  }

  int _compareGoals(GoalSummary a, GoalSummary b) {
    final target = (a.hasTarget ? 0 : 1) - (b.hasTarget ? 0 : 1);
    if (target != 0) return target;
    final timeline = _timelineRank(
      a.timeline,
    ).compareTo(_timelineRank(b.timeline));
    if (timeline != 0) return timeline;
    final priority = _priorityRank(
      a.priority,
    ).compareTo(_priorityRank(b.priority));
    if (priority != 0) return priority;
    final missing = b.missing.compareTo(a.missing);
    if (missing != 0) return missing;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _timelineRank(GoalTimeline? timeline) => switch (timeline) {
    GoalTimeline.t1 => 0,
    GoalTimeline.t2 => 1,
    GoalTimeline.t3 => 2,
    GoalTimeline.t4 => 3,
    GoalTimeline.annual => 4,
    null => 5,
  };

  int _priorityRank(GoalPriority? priority) => switch (priority) {
    GoalPriority.grande => 0,
    GoalPriority.pequeno => 1,
    GoalPriority.niceToHave => 2,
    null => 3,
  };

  ExpenseMonthSummary? get _stripMonth {
    for (final month in _yearMonths) {
      if (month.month == _month) {
        return month;
      }
    }
    return null;
  }

  int get _stripYear {
    final year = int.tryParse(_month.split('-').first);
    return year ?? _now.year;
  }

  /// The alerts implied by the current year's month statuses: the current
  /// month left open or uncreated, and the next month not created yet.
  List<DashboardAlert> _alertsFrom(ExpenseYearSummary summary) {
    final current = MonthKey.of(_now.year, _now.month);
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
