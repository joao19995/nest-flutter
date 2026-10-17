import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/person.dart';

/// Presentation state for the people list and its create form.
class PeopleViewModel extends ChangeNotifier {
  PeopleViewModel({required PeopleRepository peopleRepository})
    : _peopleRepository = peopleRepository;

  final PeopleRepository _peopleRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Person> _people = const [];
  List<Person> get people => _people;

  bool get isEmpty => _people.isEmpty;

  /// Loads the people list.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _people = await _peopleRepository.fetchPeople();
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a person and reloads the list.
  ///
  /// Returns `true` on success; on failure sets [errorMessage] and returns
  /// `false` so the form can stay open.
  Future<bool> createPerson({
    required String name,
    required double dailySpendingPercentage,
    required int emergencyFundMonths,
  }) async {
    try {
      await _peopleRepository.createPerson(
        name: name,
        dailySpendingPercentage: dailySpendingPercentage,
        emergencyFundMonths: emergencyFundMonths,
      );
      await load();
      return true;
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }
  }
}
