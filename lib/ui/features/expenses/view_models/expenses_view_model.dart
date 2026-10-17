import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/expense_year_summary.dart';

/// Presentation state for the yearly expenses panorama.
class ExpensesViewModel extends ChangeNotifier {
  ExpensesViewModel({required ExpensesRepository expensesRepository, int? year})
    : _expensesRepository = expensesRepository,
      _selectedYear = year ?? DateTime.now().year;

  /// The earliest year the API accepts.
  static const int _minYear = 2000;

  final ExpensesRepository _expensesRepository;

  int _selectedYear;
  int get selectedYear => _selectedYear;

  bool get canGoToPreviousYear => _selectedYear > _minYear;

  bool get canGoToNextYear => _selectedYear < DateTime.now().year;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ExpenseYearSummary? _summary;
  ExpenseYearSummary? get summary => _summary;

  bool get isEmpty => _summary == null || !_summary!.hasData;

  /// The twelve months of the selected year, in calendar order.
  List<ExpenseMonthSummary> get months => _summary?.months ?? const [];

  /// Loads the panorama for the selected year.
  ///
  /// Ignoring a summary whose year is no longer selected keeps rapid year
  /// changes from overwriting the current view with a stale response.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final year = _selectedYear;
    try {
      final summary = await _expensesRepository.fetchYearSummary(year);
      if (year != _selectedYear) {
        return;
      }
      _summary = summary;
    } on ApiFailure catch (failure) {
      if (year == _selectedYear) {
        _errorMessage = failure.message;
      }
    } finally {
      if (year == _selectedYear) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Selects the previous year and reloads.
  void showPreviousYear() {
    if (!canGoToPreviousYear) {
      return;
    }
    _selectedYear--;
    _summary = null;
    load();
  }

  /// Selects the next year and reloads.
  void showNextYear() {
    if (!canGoToNextYear) {
      return;
    }
    _selectedYear++;
    _summary = null;
    load();
  }
}
