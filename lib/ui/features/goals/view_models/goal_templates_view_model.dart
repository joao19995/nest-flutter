import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/domain/models/goal_template.dart';

/// Presentation state for the annual goals table: list the versions and create
/// or edit one. The entries must total 100%.
class GoalTemplatesViewModel extends ChangeNotifier {
  GoalTemplatesViewModel({required GoalsRepository goalsRepository})
    : _goalsRepository = goalsRepository;

  final GoalsRepository _goalsRepository;

  bool _isLoading = true;
  String? _errorMessage;
  String? _actionError;
  List<GoalTemplate> _templates = const [];
  List<Goal> _goals = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  List<GoalTemplate> get templates => _templates;
  bool get isEmpty => _templates.isEmpty;

  /// The active goals, used to build the table rows.
  List<Goal> get goals => _goals;

  /// Loads the versions and the active goal catalogue.
  ///
  /// Reads run sequentially: the API shares a single database connection.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final templates = await _goalsRepository.fetchGoalTemplates();
      final goals = await _goalsRepository.fetchGoals();
      _templates = [...templates]
        ..sort((a, b) => a.validFrom.compareTo(b.validFrom));
      _goals = [
        for (final goal in goals)
          if (goal.active) goal,
      ];
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a version starting at [validFrom] (`YYYY-MM`). Returns null on
  /// success, or the failure message.
  Future<String?> createVersion({
    required String validFrom,
    required List<GoalTemplateEntry> entries,
  }) async {
    _actionError = null;
    try {
      final annualTotal = await _annualTotalForYear(_yearOf(validFrom));
      final created = await _goalsRepository.createGoalTemplate(
        validFrom: validFrom,
        annualTotal: annualTotal,
        entries: entries,
      );
      _upsert(created);
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
    }
  }

  /// Replaces the entries of [template]. Returns null on success, or the
  /// failure message.
  Future<String?> updateVersion(
    GoalTemplate template, {
    required List<GoalTemplateEntry> entries,
  }) async {
    _actionError = null;
    try {
      final annualTotal = await _annualTotalForYear(
        _yearOf(template.validFrom),
      );
      final updated = await _goalsRepository.updateGoalTemplate(
        template.id,
        annualTotal: annualTotal,
        entries: entries,
      );
      _upsert(updated);
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
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

  /// The year's funding snapshot, or 0 when it cannot be read (the field is
  /// informational; a missing year must not block saving the table).
  Future<double> _annualTotalForYear(int year) async {
    try {
      final goalYear = await _goalsRepository.fetchGoalYear(year);
      return goalYear.annualTotal;
    } on ApiFailure {
      return 0;
    }
  }

  static int _yearOf(String month) =>
      int.tryParse(month.length >= 4 ? month.substring(0, 4) : '') ??
      DateTime.now().year;

  void _upsert(GoalTemplate template) {
    _templates = [
      for (final current in _templates)
        if (current.id != template.id) current,
      template,
    ]..sort((a, b) => a.validFrom.compareTo(b.validFrom));
    notifyListeners();
  }
}
