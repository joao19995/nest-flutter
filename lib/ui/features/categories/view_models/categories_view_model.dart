import 'package:flutter/foundation.dart' hide Category;
import 'package:nest/data/repositories/categories_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/category.dart';

/// Presentation state for the expense categories.
class CategoriesViewModel extends ChangeNotifier {
  CategoriesViewModel({required CategoriesRepository categoriesRepository})
    : _categoriesRepository = categoriesRepository;

  final CategoriesRepository _categoriesRepository;

  bool _isLoading = true;
  String? _errorMessage;
  bool _includeInactive = false;
  String? _actionError;
  List<Category> _categories = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get includeInactive => _includeInactive;
  String? get actionError => _actionError;
  List<Category> get categories => _categories;
  bool get isEmpty => _categories.isEmpty;

  /// Loads the categories, soft-deleted ones when [includeInactive] is set.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final categories = await _categoriesRepository.fetchCategories(
        includeInactive: _includeInactive,
      );
      _categories = _sorted(categories);
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads, including (or excluding) the soft-deleted categories.
  Future<void> setIncludeInactive(bool value) async {
    if (_includeInactive == value) {
      return;
    }
    _includeInactive = value;
    await load();
  }

  /// Creates a category. Returns null on success, or the failure message.
  Future<String?> createCategory({
    required String name,
    required CategoryType type,
    String? iconKey,
  }) async {
    _actionError = null;
    try {
      final created = await _categoriesRepository.createCategory(
        name: name,
        type: type,
        iconKey: iconKey,
      );
      _upsert(created);
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
    }
  }

  /// Updates [category], preserving its active state. Returns null on success,
  /// or the failure message.
  Future<String?> updateCategory(
    Category category, {
    required String name,
    required CategoryType type,
    String? iconKey,
  }) async {
    _actionError = null;
    try {
      final updated = await _categoriesRepository.updateCategory(
        category.id,
        name: name,
        type: type,
        active: category.active,
        iconKey: iconKey,
      );
      _upsert(updated);
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
    }
  }

  /// Soft-deletes [category] optimistically, rolling back if the request
  /// fails. Returns whether the delete succeeded.
  Future<bool> deleteCategory(Category category) async {
    final index = _categories.indexWhere(
      (current) => current.id == category.id,
    );
    if (index == -1) {
      return false;
    }
    _actionError = null;
    _categories = [
      for (final current in _categories)
        if (current.id != category.id) current,
    ];
    notifyListeners();
    try {
      await _categoriesRepository.deleteCategory(category.id);
      return true;
    } on ApiFailure catch (failure) {
      final restored = [..._categories]
        ..insert(index.clamp(0, _categories.length), category);
      _categories = restored;
      _actionError = failure.message;
      notifyListeners();
      return false;
    }
  }

  /// Restores a soft-deleted [category] (the swipe-to-delete undo).
  Future<void> restoreCategory(Category category) async {
    _actionError = null;
    try {
      final restored = await _categoriesRepository.restoreCategory(category.id);
      _upsert(restored);
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

  /// Inserts or replaces [category], keeping the list sorted by name. Inactive
  /// categories are dropped unless [includeInactive] is on.
  void _upsert(Category category) {
    final visible = _includeInactive || category.active;
    _categories = _sorted([
      for (final current in _categories)
        if (current.id != category.id) current,
      if (visible) category,
    ]);
    notifyListeners();
  }

  static List<Category> _sorted(List<Category> categories) =>
      [...categories]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
