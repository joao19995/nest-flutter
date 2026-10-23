import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';

/// Presentation state for the goals catalogue: create, rename and
/// deactivate/restore. Deactivating is a soft delete, reversible.
class GoalsCatalogViewModel extends ChangeNotifier {
  GoalsCatalogViewModel({required GoalsRepository goalsRepository})
    : _goalsRepository = goalsRepository;

  final GoalsRepository _goalsRepository;

  bool _isLoading = true;
  String? _errorMessage;
  String? _actionError;
  bool _includeInactive = false;
  List<Goal> _goals = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  bool get includeInactive => _includeInactive;
  List<Goal> get goals => _goals;
  bool get isEmpty => _goals.isEmpty;

  /// Loads the catalogue, including deactivated goals when [includeInactive].
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final goals = await _goalsRepository.fetchGoals(
        includeInactive: _includeInactive,
      );
      _goals = _sorted(goals);
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads, including (or excluding) the deactivated goals.
  Future<void> setIncludeInactive(bool value) async {
    if (_includeInactive == value) {
      return;
    }
    _includeInactive = value;
    await load();
  }

  /// Creates a goal. Returns null on success, or the failure message.
  Future<String?> createGoal(String name, {String? iconKey}) async {
    _actionError = null;
    try {
      _upsert(await _goalsRepository.createGoal(name: name, iconKey: iconKey));
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
    }
  }

  /// Renames [goal] and updates its icon. Returns null on success, or the
  /// failure message.
  Future<String?> updateGoal(Goal goal, String name, {String? iconKey}) async {
    _actionError = null;
    try {
      _upsert(
        await _goalsRepository.updateGoal(
          goal.id,
          name: name,
          iconKey: iconKey,
        ),
      );
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
    }
  }

  /// Deactivates [goal]. Returns null on success, or the failure message — the
  /// server refuses when a template still funds the goal for an open month.
  Future<String?> deleteGoal(Goal goal) async {
    _actionError = null;
    try {
      await _goalsRepository.deleteGoal(goal.id);
      _upsert(goal.copyWith(active: false));
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
    }
  }

  /// Restores a deactivated [goal]. Returns null on success, or the failure
  /// message.
  Future<String?> restoreGoal(Goal goal) async {
    _actionError = null;
    try {
      _upsert(await _goalsRepository.restoreGoal(goal.id));
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

  void _upsert(Goal goal) {
    final visible = _includeInactive || goal.active;
    _goals = _sorted([
      for (final current in _goals)
        if (current.id != goal.id) current,
      if (visible) goal,
    ]);
    notifyListeners();
  }

  static List<Goal> _sorted(List<Goal> goals) =>
      [...goals]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
