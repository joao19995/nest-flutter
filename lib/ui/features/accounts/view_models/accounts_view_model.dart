import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/accounts_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/account.dart';
import 'package:nest/domain/models/person.dart';

/// Presentation state for the household bank accounts.
class AccountsViewModel extends ChangeNotifier {
  AccountsViewModel({
    required AccountsRepository accountsRepository,
    required PeopleRepository peopleRepository,
  }) : _accountsRepository = accountsRepository,
       _peopleRepository = peopleRepository;

  final AccountsRepository _accountsRepository;
  final PeopleRepository _peopleRepository;

  bool _isLoading = true;
  String? _errorMessage;
  bool _includeInactive = false;
  String? _actionError;
  List<Account> _accounts = const [];
  List<Person> _people = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get includeInactive => _includeInactive;
  String? get actionError => _actionError;
  List<Account> get accounts => _accounts;

  /// The household members, used to pick the account owner in the form.
  List<Person> get people => _people;

  bool get isEmpty => _accounts.isEmpty;

  /// The owner's name, or null for a joint account or an unknown owner.
  String? ownerName(Account account) {
    final ownerId = account.ownerPersonId;
    if (ownerId == null) {
      return null;
    }
    for (final person in _people) {
      if (person.id == ownerId) {
        return person.name;
      }
    }
    return null;
  }

  /// Loads the people and the accounts (soft-deleted ones when
  /// [includeInactive] is set).
  ///
  /// Reads run sequentially: the API shares a single database connection, so
  /// concurrent requests gain nothing and can stall.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final people = await _peopleRepository.fetchPeople();
      final accounts = await _accountsRepository.fetchAccounts(
        includeInactive: _includeInactive,
      );
      _people = people;
      _accounts = _sorted(accounts);
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads, including (or excluding) the soft-deleted accounts.
  Future<void> setIncludeInactive(bool value) async {
    if (_includeInactive == value) {
      return;
    }
    _includeInactive = value;
    await load();
  }

  /// Creates an account. Returns null on success, or the failure message.
  Future<String?> createAccount({
    required String name,
    String? ownerPersonId,
  }) async {
    _actionError = null;
    try {
      final created = await _accountsRepository.createAccount(
        name: name,
        ownerPersonId: ownerPersonId,
      );
      _upsert(created);
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
    }
  }

  /// Updates [account]. Returns null on success, or the failure message.
  Future<String?> updateAccount(
    Account account, {
    required String name,
    String? ownerPersonId,
  }) async {
    _actionError = null;
    try {
      final updated = await _accountsRepository.updateAccount(
        account.id,
        name: name,
        ownerPersonId: ownerPersonId,
      );
      _upsert(updated);
      return null;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return failure.message;
    }
  }

  /// Soft-deletes [account] optimistically, rolling back if the request fails.
  /// Returns whether the delete succeeded.
  Future<bool> deleteAccount(Account account) async {
    final index = _accounts.indexWhere((current) => current.id == account.id);
    if (index == -1) {
      return false;
    }
    _actionError = null;
    _accounts = [
      for (final current in _accounts)
        if (current.id != account.id) current,
    ];
    notifyListeners();
    try {
      await _accountsRepository.deleteAccount(account.id);
      return true;
    } on ApiFailure catch (failure) {
      final restored = [..._accounts]
        ..insert(index.clamp(0, _accounts.length), account);
      _accounts = restored;
      _actionError = failure.message;
      notifyListeners();
      return false;
    }
  }

  /// Restores a soft-deleted [account] (the swipe-to-delete undo).
  Future<void> restoreAccount(Account account) async {
    _actionError = null;
    try {
      final restored = await _accountsRepository.restoreAccount(account.id);
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

  /// Inserts or replaces [account], keeping the list sorted by name. Inactive
  /// accounts are dropped unless [includeInactive] is on.
  void _upsert(Account account) {
    final visible = _includeInactive || account.active;
    _accounts = _sorted([
      for (final current in _accounts)
        if (current.id != account.id) current,
      if (visible) account,
    ]);
    notifyListeners();
  }

  static List<Account> _sorted(List<Account> accounts) =>
      [...accounts]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
