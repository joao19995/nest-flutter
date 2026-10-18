import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/person.dart';
import 'package:nest/domain/models/person_income.dart';
import 'package:nest/ui/core/month_key.dart';

/// Read-only salary summary for one household member.
class PersonSalarySummary {
  const PersonSalarySummary({
    required this.person,
    required this.monthlyIncome,
    required this.dailySpending,
    required this.incomes,
  });

  final Person person;

  /// The income applicable to the current month, in euros (server-provided).
  final double monthlyIncome;

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

  /// The household's total monthly income, in euros.
  double get householdIncome =>
      _summaries.fold<double>(0, (sum, summary) => sum + summary.monthlyIncome);

  /// Loads the people (with the server-applied income for the current month)
  /// and their income history, then derives the daily spending per person.
  ///
  /// Reads run sequentially: the API shares a single database connection, so
  /// concurrent requests gain nothing and can stall.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final month = MonthKey.current();
      final people = await _peopleRepository.fetchPeople(incomeMonth: month);
      final allIncomes = await _peopleRepository.fetchAllIncomes();
      final incomesByPerson = <String, List<PersonIncome>>{};
      for (final income in allIncomes) {
        (incomesByPerson[income.personId] ??= <PersonIncome>[]).add(income);
      }
      final summaries = <PersonSalarySummary>[
        for (final person in people)
          PersonSalarySummary(
            person: person,
            monthlyIncome: person.applicableIncome ?? 0,
            dailySpending:
                (person.applicableIncome ?? 0) *
                person.dailySpendingPercentage /
                100,
            incomes: incomesByPerson[person.id] ?? const <PersonIncome>[],
          ),
      ];
      _summaries = summaries;
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
