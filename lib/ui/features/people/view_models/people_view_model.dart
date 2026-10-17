import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/person.dart';
import 'package:nest/domain/models/person_income.dart';

/// Read-only salary summary for one household member.
class PersonSalarySummary {
  const PersonSalarySummary({
    required this.person,
    required this.monthlyIncome,
    required this.currentIncomeId,
    required this.dailySpending,
    required this.incomes,
  });

  final Person person;

  /// The income applicable to the current month, in euros.
  final double monthlyIncome;

  /// The id of the income record applicable to the current month, if any.
  final String? currentIncomeId;

  /// The amount of [monthlyIncome] allocated to daily spending, in euros.
  final double dailySpending;

  /// The full income history, ordered by `validFrom` (oldest first).
  final List<PersonIncome> incomes;
}

/// Presentation state for the informative people/salaries page.
class PeopleViewModel extends ChangeNotifier {
  PeopleViewModel({required PeopleRepository peopleRepository})
    : _peopleRepository = peopleRepository;

  final PeopleRepository _peopleRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<PersonSalarySummary> _summaries = const [];
  List<PersonSalarySummary> get summaries => _summaries;

  bool get isEmpty => _summaries.isEmpty;

  /// Loads people and their income history, then derives the current salary
  /// and daily spending per person.
  ///
  /// Reads run sequentially: the API shares a single database connection, so
  /// concurrent requests gain nothing and can stall.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final people = await _peopleRepository.fetchPeople();
      final month = _currentMonth();
      final summaries = <PersonSalarySummary>[];
      for (final person in people) {
        final incomes = await _peopleRepository.fetchIncomes(person.id);
        final current = PersonIncome.applicableFor(incomes, person.id, month);
        final monthlyIncome = current?.amount ?? 0;
        summaries.add(
          PersonSalarySummary(
            person: person,
            monthlyIncome: monthlyIncome,
            currentIncomeId: current?.id,
            dailySpending: monthlyIncome * person.dailySpendingPercentage / 100,
            incomes: incomes,
          ),
        );
      }
      _summaries = summaries;
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static String _currentMonth() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}
