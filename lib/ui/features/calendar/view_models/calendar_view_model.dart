import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/calendar_event.dart';

/// Presentation state for the event calendar: the visible month, the selected
/// day and the events loaded for the surrounding weeks.
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({
    required EventsRepository eventsRepository,
    DateTime? today,
  }) : _eventsRepository = eventsRepository,
       _today = _dateOnly(today ?? DateTime.now()) {
    _visibleMonth = DateTime(_today.year, _today.month);
    _selectedDay = _today;
  }

  final EventsRepository _eventsRepository;

  /// Midnight of the reference "today", fixed at construction so the highlight
  /// does not drift during a long session.
  final DateTime _today;

  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  List<CalendarEvent> _events = const [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isBusy = false;
  String? _actionError;

  /// Guards against a stale response overwriting a newer month's events.
  int _loadToken = 0;

  DateTime get today => _today;
  DateTime get visibleMonth => _visibleMonth;
  DateTime get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;
  String? get actionError => _actionError;

  /// The full weeks (Monday first) covering the visible month, including the
  /// leading and trailing days that fall in the adjacent months.
  List<DateTime> get gridDays => buildGridDays(_visibleMonth);

  /// How many events the visible month itself holds.
  int get monthEventCount => _events
      .where(
        (event) =>
            event.startsAt.year == _visibleMonth.year &&
            event.startsAt.month == _visibleMonth.month,
      )
      .length;

  /// The selected day's events, earliest first.
  List<CalendarEvent> get selectedEvents => eventsFor(_selectedDay);

  /// Whether the selected day has no events.
  bool get isEmpty => selectedEvents.isEmpty;

  /// The events falling on [day], earliest first.
  List<CalendarEvent> eventsFor(DateTime day) =>
      _events.where((event) => event.occursOn(day)).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  /// Builds the calendar grid for [month]: whole weeks starting on Monday.
  static List<DateTime> buildGridDays(DateTime month) {
    final first = DateTime(month.year, month.month);
    final leading = first.weekday - DateTime.monday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weeks = ((leading + daysInMonth) / 7).ceil();
    return [
      for (var index = 0; index < weeks * 7; index++)
        DateTime(month.year, month.month, 1 - leading + index),
    ];
  }

  /// Loads the events that can land on the visible grid.
  ///
  /// The range is padded by one day on each side: the API filters by date and a
  /// late-night event can fall on a neighbouring day once converted to local
  /// time. A stale response is discarded by [_loadToken].
  Future<void> load() async {
    final token = ++_loadToken;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final days = gridDays;
    final from = DateTime(
      days.first.year,
      days.first.month,
      days.first.day - 1,
    );
    final to = DateTime(days.last.year, days.last.month, days.last.day + 1);
    try {
      final events = await _eventsRepository.fetchEvents(from: from, to: to);
      if (token != _loadToken) {
        return;
      }
      _events = events;
    } on ApiFailure catch (failure) {
      if (token != _loadToken) {
        return;
      }
      _errorMessage = failure.message;
    } finally {
      if (token == _loadToken) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Moves to the previous month and reloads.
  Future<void> showPreviousMonth() =>
      _setMonth(DateTime(_visibleMonth.year, _visibleMonth.month - 1));

  /// Moves to the next month and reloads.
  Future<void> showNextMonth() =>
      _setMonth(DateTime(_visibleMonth.year, _visibleMonth.month + 1));

  /// Returns to the current month and selects today.
  Future<void> goToToday() {
    _visibleMonth = DateTime(_today.year, _today.month);
    _selectedDay = _today;
    return load();
  }

  /// Selects [day]; a day in another month also switches the visible month.
  Future<void> selectDay(DateTime day) {
    final changesMonth =
        day.year != _visibleMonth.year || day.month != _visibleMonth.month;
    _selectedDay = _dateOnly(day);
    if (changesMonth) {
      _visibleMonth = DateTime(day.year, day.month);
      return load();
    }
    notifyListeners();
    return Future<void>.value();
  }

  /// Creates an event and adopts the server's response. Returns whether it
  /// succeeded, so the caller can keep a form open on failure.
  Future<bool> createEvent({
    required String title,
    required DateTime startsAt,
  }) async {
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      final created = await _eventsRepository.createEvent(
        title: title,
        startsAt: startsAt,
      );
      await _adopt(created);
      return true;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Updates [event] and adopts the server's response.
  Future<bool> updateEvent(
    CalendarEvent event, {
    required String title,
    required DateTime startsAt,
  }) async {
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      final updated = await _eventsRepository.updateEvent(
        event.id,
        title: title,
        startsAt: startsAt,
      );
      await _adopt(updated);
      return true;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Soft-deletes [event] optimistically, rolling back if the request fails.
  /// Returns whether the delete succeeded.
  Future<bool> deleteEvent(CalendarEvent event) async {
    final index = _events.indexWhere((current) => current.id == event.id);
    if (index == -1) {
      return false;
    }
    _actionError = null;
    _events = [
      for (final current in _events)
        if (current.id != event.id) current,
    ];
    notifyListeners();
    try {
      await _eventsRepository.deleteEvent(event.id);
      return true;
    } on ApiFailure catch (failure) {
      final restored = [..._events]
        ..insert(index.clamp(0, _events.length), event);
      _events = restored;
      _actionError = failure.message;
      notifyListeners();
      return false;
    }
  }

  /// Restores a soft-deleted [event] (the swipe-to-delete undo).
  Future<void> restoreEvent(CalendarEvent event) async {
    _actionError = null;
    try {
      await _eventsRepository.restoreEvent(event.id);
      _events = [
        for (final current in _events)
          if (current.id != event.id) current,
        event,
      ];
      notifyListeners();
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
    }
  }

  /// Clears the last action error.
  void clearActionError() {
    if (_actionError == null) {
      return;
    }
    _actionError = null;
    notifyListeners();
  }

  Future<void> _setMonth(DateTime month) {
    _visibleMonth = DateTime(month.year, month.month);
    _selectedDay = _defaultDayFor(_visibleMonth);
    return load();
  }

  /// The day selected after changing month: today when it is the current
  /// month, otherwise the first of the month.
  DateTime _defaultDayFor(DateTime month) {
    if (month.year == _today.year && month.month == _today.month) {
      return _today;
    }
    return DateTime(month.year, month.month);
  }

  /// Adopts a freshly written [event]: selects its day, then updates the local
  /// list — or switches month and reloads when the event moved elsewhere.
  Future<void> _adopt(CalendarEvent event) async {
    final sameMonth =
        event.startsAt.year == _visibleMonth.year &&
        event.startsAt.month == _visibleMonth.month;
    _selectedDay = _dateOnly(event.startsAt);
    if (sameMonth) {
      _events = [
        for (final current in _events)
          if (current.id != event.id) current,
        event,
      ];
      notifyListeners();
    } else {
      _visibleMonth = DateTime(event.startsAt.year, event.startsAt.month);
      _events = const [];
      await load();
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
