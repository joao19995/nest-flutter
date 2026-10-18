import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/domain/models/goal_template.dart';
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

/// Presentation state for the people/salaries page.
///
/// Besides the read-only overview it owns the write flows: creating and editing
/// people, saving their income history in one batch, and allocating the
/// "extra money" the server detects when a salary rises.
class PeopleViewModel extends ChangeNotifier {
  PeopleViewModel({
    required PeopleRepository peopleRepository,
    required GoalsRepository goalsRepository,
  }) : _peopleRepository = peopleRepository,
       _goalsRepository = goalsRepository;

  final PeopleRepository _peopleRepository;
  final GoalsRepository _goalsRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<PersonSalarySummary> _summaries = const [];

  PersonIncomeRaise? _pendingRaise;
  bool _isLoadingRaiseOptions = false;
  List<Goal> _raiseGoalOptions = const [];
  bool _raiseMonthTaken = false;
  bool _isAllocatingRaise = false;
  String? _raiseError;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PersonSalarySummary> get summaries => _summaries;
  bool get isEmpty => _summaries.isEmpty;

  /// The raise awaiting a goal choice, or null when there is none.
  PersonIncomeRaise? get pendingRaise => _pendingRaise;

  /// Whether the goal options for [pendingRaise] are still loading.
  bool get isLoadingRaiseOptions => _isLoadingRaiseOptions;

  /// The active goals present in the applicable template, for the raise picker.
  List<Goal> get raiseGoalOptions => _raiseGoalOptions;

  /// True when a template version already starts at the raise's month, so the
  /// server would reject the allocation with a 409.
  bool get raiseMonthTaken => _raiseMonthTaken;

  bool get isAllocatingRaise => _isAllocatingRaise;
  String? get raiseError => _raiseError;

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
      _summaries = [
        for (final person in people)
          _buildSummary(
            person,
            incomesByPerson[person.id] ?? const <PersonIncome>[],
            month,
          ),
      ];
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates or updates a person and saves their incomes in one flow.
  ///
  /// Returns null on success, or the failure message for the form to show. On
  /// success, if the server detected a raise, [pendingRaise] is set and the
  /// goal options start loading.
  Future<String?> savePerson({
    Person? person,
    required String name,
    required double dailySpendingPercentage,
    required int emergencyFundMonths,
    required List<PersonIncomeDraft> incomes,
  }) async {
    try {
      final saved = person == null
          ? await _peopleRepository.createPerson(
              name: name,
              dailySpendingPercentage: dailySpendingPercentage,
              emergencyFundMonths: emergencyFundMonths,
            )
          : await _peopleRepository.updatePerson(
              person.id,
              name: name,
              dailySpendingPercentage: dailySpendingPercentage,
              emergencyFundMonths: emergencyFundMonths,
            );
      final result = await _peopleRepository.saveIncomes(saved.id, incomes);
      _replacePerson(saved, result.incomes);
      _pendingRaise = result.raises.isEmpty ? null : result.raises.first;
      _raiseError = null;
      notifyListeners();
      final raise = _pendingRaise;
      if (raise != null) {
        await _loadRaiseOptions(raise);
      }
      return null;
    } on ApiFailure catch (failure) {
      return failure.message;
    }
  }

  /// Allocates [pendingRaise] to [goalId]. Returns null on success, or the
  /// failure message.
  Future<String?> allocateRaise(String goalId) async {
    final raise = _pendingRaise;
    if (raise == null) {
      return null;
    }
    _isAllocatingRaise = true;
    _raiseError = null;
    notifyListeners();
    try {
      await _goalsRepository.allocateRaise(
        validFrom: raise.validFromMonth,
        goalId: goalId,
        extra: raise.extra,
      );
      _clearRaise();
      return null;
    } on ApiFailure catch (failure) {
      _raiseError = failure.message;
      return failure.message;
    } finally {
      _isAllocatingRaise = false;
      notifyListeners();
    }
  }

  /// Dismisses [pendingRaise] without allocating it.
  void dismissRaise() {
    if (_pendingRaise == null) {
      return;
    }
    _clearRaise();
    notifyListeners();
  }

  void _clearRaise() {
    _pendingRaise = null;
    _raiseGoalOptions = const [];
    _raiseMonthTaken = false;
    _raiseError = null;
  }

  /// Loads the templates and goals needed by the raise picker, then resolves
  /// the applicable template's active goals.
  Future<void> _loadRaiseOptions(PersonIncomeRaise raise) async {
    _isLoadingRaiseOptions = true;
    _raiseGoalOptions = const [];
    _raiseMonthTaken = false;
    notifyListeners();
    try {
      final templates = await _goalsRepository.fetchGoalTemplates();
      final goals = await _goalsRepository.fetchGoals();
      _raiseMonthTaken = templates.any(
        (template) => template.validFrom == raise.validFromMonth,
      );
      final applicable = _applicableTemplate(templates, raise.validFromMonth);
      final entryGoalIds = {
        for (final entry in applicable?.entries ?? const <GoalTemplateEntry>[])
          entry.goalId,
      };
      _raiseGoalOptions = [
        for (final goal in goals)
          if (goal.active && entryGoalIds.contains(goal.id)) goal,
      ];
    } on ApiFailure catch (failure) {
      _raiseError = failure.message;
    } finally {
      _isLoadingRaiseOptions = false;
      notifyListeners();
    }
  }

  /// Replaces (or appends) [person]'s summary with the freshly saved [incomes],
  /// keeping the list ordered by name.
  void _replacePerson(Person person, List<PersonIncome> incomes) {
    final summary = _buildSummary(person, incomes, MonthKey.current());
    final index = _summaries.indexWhere(
      (current) => current.person.id == person.id,
    );
    final next = [..._summaries];
    if (index == -1) {
      next.add(summary);
    } else {
      next[index] = summary;
    }
    next.sort(
      (a, b) =>
          a.person.name.toLowerCase().compareTo(b.person.name.toLowerCase()),
    );
    _summaries = next;
  }

  PersonSalarySummary _buildSummary(
    Person person,
    List<PersonIncome> incomes,
    String month,
  ) {
    final monthlyIncome =
        person.applicableIncome ??
        _applicableIncome(incomes, month)?.amount ??
        0;
    return PersonSalarySummary(
      person: person,
      monthlyIncome: monthlyIncome,
      dailySpending: monthlyIncome * person.dailySpendingPercentage / 100,
      incomes: incomes,
    );
  }

  /// The latest income whose month is at or before [month], or null.
  static PersonIncome? _applicableIncome(
    List<PersonIncome> incomes,
    String month,
  ) {
    PersonIncome? best;
    for (final income in incomes) {
      final incomeMonth = _monthOf(income.validFrom);
      if (incomeMonth == null || incomeMonth.compareTo(month) > 0) {
        continue;
      }
      if (best == null || income.validFrom.compareTo(best.validFrom) > 0) {
        best = income;
      }
    }
    return best;
  }

  /// The template in force at [month]: the greatest `validFrom` at or before it.
  static GoalTemplate? _applicableTemplate(
    List<GoalTemplate> templates,
    String month,
  ) {
    GoalTemplate? best;
    for (final template in templates) {
      if (template.validFrom.compareTo(month) > 0) {
        continue;
      }
      if (best == null || template.validFrom.compareTo(best.validFrom) > 0) {
        best = template;
      }
    }
    return best;
  }

  static String? _monthOf(String date) =>
      date.length >= 7 ? date.substring(0, 7) : null;
}
