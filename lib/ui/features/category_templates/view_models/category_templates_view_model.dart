import 'package:flutter/foundation.dart' hide Category;
import 'package:nest/data/repositories/accounts_repository.dart';
import 'package:nest/data/repositories/categories_repository.dart';
import 'package:nest/data/repositories/category_templates_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/account.dart';
import 'package:nest/domain/models/category.dart';
import 'package:nest/domain/models/category_template.dart';

/// Presentation state for the monthly expense templates: list the versions and
/// create or edit one.
class CategoryTemplatesViewModel extends ChangeNotifier {
  CategoryTemplatesViewModel({
    required CategoryTemplatesRepository categoryTemplatesRepository,
    required CategoriesRepository categoriesRepository,
    required AccountsRepository accountsRepository,
  }) : _categoryTemplatesRepository = categoryTemplatesRepository,
       _categoriesRepository = categoriesRepository,
       _accountsRepository = accountsRepository;

  final CategoryTemplatesRepository _categoryTemplatesRepository;
  final CategoriesRepository _categoriesRepository;
  final AccountsRepository _accountsRepository;

  bool _isLoading = true;
  String? _errorMessage;
  String? _actionError;
  List<CategoryTemplate> _templates = const [];
  List<Category> _categories = const [];
  List<Account> _accounts = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  List<CategoryTemplate> get templates => _templates;
  bool get isEmpty => _templates.isEmpty;

  /// The categories (including inactive ones), for the row pickers.
  List<Category> get categories => _categories;

  /// The accounts (including inactive ones), for the row pickers.
  List<Account> get accounts => _accounts;

  /// Loads the versions, the categories and the accounts.
  ///
  /// Reads run sequentially: the API shares a single database connection.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final templates = await _categoryTemplatesRepository
          .fetchCategoryTemplates();
      final categories = await _categoriesRepository.fetchCategories(
        includeInactive: true,
      );
      final accounts = await _accountsRepository.fetchAccounts(
        includeInactive: true,
      );
      _templates = [...templates]
        ..sort((a, b) => a.validFrom.compareTo(b.validFrom));
      _categories = categories;
      _accounts = accounts;
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// The version in force for [month] and the account to suggest for new rows.
  Future<ApplicableCategoryTemplate> applicableFor(String month) =>
      _categoryTemplatesRepository.fetchApplicableCategoryTemplate(month);

  /// Creates a version starting at [validFrom] (`YYYY-MM`). Returns null on
  /// success, or the failure message.
  Future<String?> createVersion({
    required String validFrom,
    required List<CategoryTemplateEntryDraft> entries,
  }) async {
    _actionError = null;
    try {
      final created = await _categoryTemplatesRepository.createCategoryTemplate(
        validFrom: validFrom,
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
    CategoryTemplate template,
    List<CategoryTemplateEntryDraft> entries,
  ) async {
    _actionError = null;
    try {
      final updated = await _categoryTemplatesRepository.updateCategoryTemplate(
        template.id,
        entries,
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

  void _upsert(CategoryTemplate template) {
    _templates = [
      for (final current in _templates)
        if (current.id != template.id) current,
      template,
    ]..sort((a, b) => a.validFrom.compareTo(b.validFrom));
    notifyListeners();
  }
}
