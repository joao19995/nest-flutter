import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/calendar_event.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/ui/core/month_focus.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/app_formatters.dart';

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
    this.showInAttentionCard = false,
  });

  /// The sentence shown in the dashboard.
  final String message;

  /// The month to open, formatted `YYYY-MM`.
  final String month;

  final DashboardAlertKind kind;

  /// True to keep the alert in the attention card even when [month] is the one
  /// already displayed by the hero.
  final bool showInAttentionCard;
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

  /// The goals month status.
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
       _month = MonthKey.of(now.year, now.month);

  /// How many days ahead the "Hoje e próximos" list looks.
  static const int _upcomingDays = 6;

  /// After this day of the month, an open current month keeps nagging.
  static const int _closingReminderAfterDay = 7;

  /// The earliest month the stepper can reach.
  static const String _minMonth = '2000-01';

  final ExpensesRepository _expensesRepository;
  final GoalsRepository _goalsRepository;
  final EventsRepository _eventsRepository;

  /// Supplies the current time. Tests pin it with [DashboardViewModel.new].
  final DateTime Function() _clock;

  DateTime _now;

  String _month;

  /// The displayed month's goal plan, read from
  /// `GET /api/goal-plan/{month}`; null when the month has none or the read
  /// failed.
  GoalMonthView? _goalMonth;

  /// True once the user has stepped away from the current month, so a refresh
  /// does not yank the selection back.
  bool _monthSelected = false;

  bool _isFetching = false;

  /// True while any dashboard section is being fetched.
  bool get isLoading => _isFetching;

  DashboardSectionState _monthSection = const DashboardSectionState(
    isLoading: true,
  );
  DashboardSectionState _alertsSection = const DashboardSectionState(
    isLoading: true,
  );
  DashboardSectionState _eventsSection = const DashboardSectionState(
    isLoading: true,
  );

  List<DashboardAlert> _alerts = const [];
  List<CalendarEvent> _upcomingEvents = const [];
  List<ExpenseMonthSummary> _yearMonths = const [];
  ExpenseMonthSummary? _monthSummary;

  /// The header hero's loading state.
  DashboardSectionState get monthSection => _monthSection;

  /// The alerts card's loading state.
  DashboardSectionState get alertsSection => _alertsSection;

  /// The upcoming events section's loading state.
  DashboardSectionState get eventsSection => _eventsSection;

  /// Warnings worth surfacing at the top of the dashboard.
  List<DashboardAlert> get alerts => _alerts;

  /// The events happening today and over the next few days, earliest first.
  List<CalendarEvent> get upcomingEvents => _upcomingEvents;

  /// The selected year's twelve months, for the year strip.
  List<ExpenseMonthSummary> get yearMonths => _yearMonths;

  /// The month's closing state: expenses, goals and their totals. Null while
  /// the month data is loading.
  DashboardRitual? get ritual {
    final expense = _monthSummary ?? _stripMonth;
    if (expense == null && _monthSection.isLoading) {
      return null;
    }
    final goalView = _goalMonth;
    final goalPlan = goalView?.plan;
    return DashboardRitual(
      month: _month,
      expensesStatus: expense?.status ?? ExpenseMonthStatus.missing,
      filledEntries: expense?.filledEntries ?? 0,
      totalEntries: expense?.totalEntries ?? 0,
      goalsStatus: goalPlan == null
          ? ExpenseMonthStatus.missing
          : goalPlan.closed
          ? ExpenseMonthStatus.closed
          : ExpenseMonthStatus.open,
      goalsReserved: goalView?.totals.reserved ?? 0,
      goalsPlanned: goalView?.totals.planned ?? 0,
    );
  }

  /// The month shown in the header hero, formatted `YYYY-MM`.
  String get month => _month;

  /// True when the card is showing the previous month because its balance is
  /// still due.
  bool get isBalanceFocus {
    if (!MonthFocus.isBalanceWindow(_now)) {
      return false;
    }
    if (_month != MonthFocus.previousMonth(_now)) {
      return false;
    }
    final status = (_monthSummary ?? _stripMonth)?.status;
    return status != null && status != ExpenseMonthStatus.closed;
  }

  /// True when the month card should stand out: the first days of the month
  /// (the previous balance is due), whenever the user stepped away from the
  /// current month (so the stepper stays available), or after the closing
  /// reminder day while the current month is not fully closed.
  bool get highlightMonth {
    if (_monthSelected || _month != MonthKey.of(_now.year, _now.month)) {
      return true;
    }
    if (MonthFocus.isBalanceWindow(_now)) {
      return true;
    }
    if (_now.day <= _closingReminderAfterDay) {
      return false;
    }
    final current = ritual;
    return current == null || !current.isClosed;
  }

  /// The header hero's month summary, or null when the month is not created.
  ExpenseMonthSummary? get monthSummary => _monthSummary;

  /// True while the header can step back a month.
  bool get canGoToPreviousMonth => _month.compareTo(_minMonth) > 0;

  /// True while the header can step forward a month.
  bool get canGoToNextMonth => _month.compareTo('${_now.year + 1}-12') < 0;

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

      _monthSection = DashboardSectionState(isLoading: showSkeleton);
      _alertsSection = DashboardSectionState(isLoading: showSkeleton);
      _eventsSection = DashboardSectionState(isLoading: showSkeleton);
      notifyListeners();

      await _loadYear(showLoading: showSkeleton);
      await _focusBalanceMonthIfDue();
      await _loadMonth(showLoading: showSkeleton && _monthSummary == null);
      await _loadGoalMonth();
      await _loadEvents(showLoading: showSkeleton);
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Moves the card to the previous month while its balance is due.
  Future<void> _focusBalanceMonthIfDue() async {
    if (_monthSelected || !MonthFocus.isBalanceWindow(_now)) {
      return;
    }
    final current = MonthKey.of(_now.year, _now.month);
    if (_month != current) {
      return;
    }
    final previous = MonthFocus.previousMonth(_now);
    var status = _summaryOf(previous)?.status;
    ExpenseYearSummary? previousYearSummary;
    final previousYear = int.tryParse(previous.substring(0, 4));
    if (status == null && previousYear != null && previousYear != _now.year) {
      // January: the balance due is December of the previous year.
      try {
        previousYearSummary = await _expensesRepository.fetchYearSummary(
          previousYear,
        );
        status = _statusOf(previousYearSummary, previous);
      } on ApiFailure {
        return;
      }
    }
    if (MonthFocus.resolve(now: _now, previousStatus: status) == current) {
      return;
    }
    _month = previous;
    _monthSummary = null;
    final summary = previousYearSummary;
    if (summary != null) {
      _yearMonths = summary.months;
    }
  }

  ExpenseMonthSummary? _summaryOf(String month) {
    for (final entry in _yearMonths) {
      if (entry.month == month) {
        return entry;
      }
    }
    return null;
  }

  /// Retries the header hero after a failure.
  Future<void> retryMonth() => _runSection(() async {
    await _loadMonth();
    await _loadGoalMonth();
  });

  /// Retries the alerts year summary after a failure.
  Future<void> retryAlerts() => _runSection(() => _loadYear(showLoading: true));

  /// Retries the upcoming events after a failure.
  Future<void> retryEvents() => _runSection(_loadEvents);

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
    await _loadGoalMonth();
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
    await _loadGoalMonth();
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
      notifyListeners();
    }
    try {
      final current = await _expensesRepository.fetchYearSummary(_now.year);
      _alerts = _alertsFrom(current);
      _alertsSection = const DashboardSectionState();
      if (displayYear == _now.year) {
        _yearMonths = current.months;
      }
    } on ApiFailure catch (failure) {
      _alertsSection = DashboardSectionState(errorMessage: failure.message);
    }
    notifyListeners();

    if (displayYear != _now.year) {
      await _loadStrip();
    }
  }

  /// Loads the twelve months of the displayed month's year.
  ///
  /// Only [ritual] reads it as a fallback; a failure keeps the previous months.
  Future<void> _loadStrip() async {
    try {
      final display = await _expensesRepository.fetchYearSummary(_stripYear);
      _yearMonths = display.months;
    } on ApiFailure {
      // Keep the months already loaded; nothing else depends on this read.
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

  /// Loads the displayed month's goal plan from
  /// `GET /api/goal-plan/{month}`.
  ///
  /// A failure leaves the goals line missing; the rest of the dashboard keeps
  /// working.
  Future<void> _loadGoalMonth() async {
    try {
      _goalMonth = await _goalsRepository.fetchGoalMonth(_month);
    } on ApiFailure {
      _goalMonth = null;
    }
    notifyListeners();
  }

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
  /// month left open or uncreated, the next month not created yet, and the two
  /// periodic balance reminders.
  List<DashboardAlert> _alertsFrom(ExpenseYearSummary summary) {
    final current = MonthKey.of(_now.year, _now.month);
    final next = MonthKey.shift(current, 1);
    final previous = MonthKey.shift(current, -1);
    final alerts = <DashboardAlert>[];
    for (final month in summary.months) {
      final name = AppFormatters.monthName(month.month);
      if (month.month == current && month.status == ExpenseMonthStatus.open) {
        alerts.add(
          DashboardAlert(
            message: _now.day > _closingReminderAfterDay
                ? 'O balanço de $name continua por fechar há ${_now.day} dias'
                : '$name por fechar',
            month: month.month,
            kind: DashboardAlertKind.toClose,
            showInAttentionCard: _now.day > _closingReminderAfterDay,
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

    if (MonthFocus.isBalanceWindow(_now)) {
      final previousStatus = _statusOf(summary, previous);
      if (previousStatus == ExpenseMonthStatus.open ||
          previousStatus == ExpenseMonthStatus.missing) {
        final name = AppFormatters.monthName(previous);
        alerts.add(
          DashboardAlert(
            message: 'É altura de fazer o balanço de $name',
            month: previous,
            kind: previousStatus == ExpenseMonthStatus.open
                ? DashboardAlertKind.toClose
                : DashboardAlertKind.toCreate,
          ),
        );
      }
    }
    return alerts;
  }

  ExpenseMonthStatus? _statusOf(ExpenseYearSummary summary, String month) {
    for (final candidate in summary.months) {
      if (candidate.month == month) {
        return candidate.status;
      }
    }
    return null;
  }
}
