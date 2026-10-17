import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/accounts_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';

/// Presentation state for the dashboard.
///
/// Exposes a simple loading/error/data triple; the view renders it through
/// `AsyncView`.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required PeopleRepository peopleRepository,
    required AccountsRepository accountsRepository,
  }) : _peopleRepository = peopleRepository,
       _accountsRepository = accountsRepository;

  final PeopleRepository _peopleRepository;
  final AccountsRepository _accountsRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _peopleCount = 0;
  int get peopleCount => _peopleCount;

  int _accountsCount = 0;
  int get accountsCount => _accountsCount;

  int _jointAccountsCount = 0;
  int get jointAccountsCount => _jointAccountsCount;

  bool get isEmpty => _peopleCount == 0 && _accountsCount == 0;

  /// Loads the dashboard summary.
  ///
  /// Reads run sequentially: the API shares a single database connection, so
  /// concurrent requests gain nothing and can stall.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final people = await _peopleRepository.fetchPeople();
      final accounts = await _accountsRepository.fetchAccounts();
      _peopleCount = people.length;
      _accountsCount = accounts.length;
      _jointAccountsCount = accounts.where((account) => account.isJoint).length;
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
