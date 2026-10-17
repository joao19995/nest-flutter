import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/monthly_plan.dart';

/// Presentation state for a single month's expense detail.
class MonthDetailViewModel extends ChangeNotifier {
  MonthDetailViewModel({
    required ExpensesRepository expensesRepository,
    required String month,
  }) : _expensesRepository = expensesRepository,
       _month = month;

  final ExpensesRepository _expensesRepository;

  String _month;
  String get month => _month;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MonthlyPlan? _plan;
  MonthlyPlan? get plan => _plan;

  /// True while a write action (create, close, save) is in flight.
  bool _isBusy = false;
  bool get isBusy => _isBusy;

  /// The last write-action failure, cleared when a new action starts.
  String? _actionError;
  String? get actionError => _actionError;

  /// Loads the plan for the selected month.
  ///
  /// Ignoring a plan whose month is no longer selected keeps rapid month
  /// changes from overwriting the current view with a stale response.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _actionError = null;
    notifyListeners();
    final month = _month;
    try {
      final plan = await _expensesRepository.fetchMonth(month);
      if (month != _month) {
        return;
      }
      _plan = plan;
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
      _plan = await _expensesRepository.createMonth(_month);
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Closes the selected month and records its settlement.
  Future<void> closeMonth() async {
    final plan = _plan;
    if (plan == null || _isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      _plan = await _expensesRepository.closeMonth(plan.id);
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Saves the real amount spent on [entryId].
  Future<void> updateEntryActual(String entryId, double actual) async {
    final plan = _plan;
    if (plan == null || _isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      _plan = await _expensesRepository.updateEntryActual(
        plan.id,
        entryId,
        actual,
      );
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Selects the previous month and reloads.
  void showPreviousMonth() => _shiftMonth(-1);

  /// Selects the next month and reloads.
  void showNextMonth() => _shiftMonth(1);

  void _shiftMonth(int delta) {
    final parts = _month.split('-');
    final year = int.tryParse(parts.isNotEmpty ? parts[0] : '');
    final monthNumber = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (year == null || monthNumber == null) {
      return;
    }
    final shifted = DateTime(year, monthNumber + delta);
    _month = _format(shifted);
    _plan = null;
    load();
  }

  static String _format(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
