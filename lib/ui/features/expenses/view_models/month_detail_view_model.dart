import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/category.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/monthly_plan.dart';

/// Presentation state for a single month's expense detail.
class MonthDetailViewModel extends ChangeNotifier {
  MonthDetailViewModel({
    required ExpensesRepository expensesRepository,
    required String month,
  }) : _expensesRepository = expensesRepository,
       _month = month;

  final ExpensesRepository _expensesRepository;

  final String _month;
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

  /// The contributions calculated without closing the month, for review.
  MonthSettlement? _settlementPreview;
  MonthSettlement? get settlementPreview => _settlementPreview;

  /// The last preview failure, shown inside the close dialog.
  String? _previewError;
  String? get previewError => _previewError;

  bool _isPreviewLoading = false;
  bool get isPreviewLoading => _isPreviewLoading;

  /// How many lines of the month have a real amount entered (server rule).
  int get filledEntries => _plan?.summary.filledEntries ?? 0;

  /// How many lines the month has (server rule).
  int get totalEntries => _plan?.summary.totalEntries ?? 0;

  /// Whether at least one fixed line still has no real amount entered.
  bool get hasFixedToFill {
    final plan = _plan;
    if (plan == null || plan.closed) {
      return false;
    }
    for (final entry in plan.entries) {
      if (entry.type == CategoryType.fixed && !entry.actualSet) {
        return true;
      }
    }
    return false;
  }

  /// Loads the plan for the selected month.
  ///
  /// Ignoring a plan whose month is no longer selected keeps rapid month
  /// changes from overwriting the current view with a stale response.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _actionError = null;
    _settlementPreview = null;
    _previewError = null;
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
      _settlementPreview = null;
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
      _plan = await _expensesRepository.closeMonth(_month);
      _settlementPreview = null;
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
        _month,
        entryId,
        actual,
      );
      _settlementPreview = null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Loads the contributions without closing the month, for the review dialog.
  Future<void> loadSettlementPreview() async {
    if (_isPreviewLoading) {
      return;
    }
    _isPreviewLoading = true;
    _previewError = null;
    _settlementPreview = null;
    notifyListeners();
    try {
      _settlementPreview = await _expensesRepository.fetchSettlementPreview(
        _month,
      );
    } on ApiFailure catch (failure) {
      _previewError = failure.message;
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  /// Copies the planned amount into every fixed line still left empty.
  ///
  /// Lines already filled are never overwritten: an actual that differs from
  /// the plan is an intentional exception.
  Future<void> fillPlannedForFixed() async {
    final plan = _plan;
    if (plan == null || plan.closed || _isBusy) {
      return;
    }
    final updates = <String, double>{
      for (final entry in plan.entries)
        if (entry.type == CategoryType.fixed && !entry.actualSet)
          entry.id: entry.planned,
    };
    if (updates.isEmpty) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      _plan = await _expensesRepository.updateEntriesActual(_month, updates);
      _settlementPreview = null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Copies the planned amount into the line [entryId].
  Future<void> fillPlanned(String entryId) async {
    final plan = _plan;
    if (plan == null || plan.closed) {
      return;
    }
    for (final entry in plan.entries) {
      if (entry.id == entryId) {
        await updateEntryActual(entryId, entry.planned);
        return;
      }
    }
  }
}
