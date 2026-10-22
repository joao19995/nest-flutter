import 'package:nest/data/models/json_mapper.dart';
import 'package:nest/data/models/person_income_model.dart';
import 'package:nest/data/models/person_model.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/person.dart';
import 'package:nest/domain/models/person_income.dart';

/// Reads household members and their income history.
class PeopleRepository {
  PeopleRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns all people, ordered by name (as served by the API).
  ///
  /// With [incomeMonth] (`YYYY-MM`), each person carries `applicableIncome` —
  /// the server-side "most recent income at or before the month" rule.
  Future<List<Person>> fetchPeople({String? incomeMonth}) async {
    final path = incomeMonth == null
        ? '/api/people'
        : '/api/people?incomeMonth=$incomeMonth';
    final data = await _client.get(path);
    return mapJsonList(data, (json) => PersonModel.fromJson(json).toDomain());
  }

  /// Returns every income record for every person in one request, ordered by
  /// `validFrom`. Replaces the per-person reads (the N+1).
  Future<List<PersonIncome>> fetchAllIncomes() async {
    final data = await _client.get('/api/people/incomes');
    return mapJsonList(
      data,
      (json) => PersonIncomeModel.fromJson(json).toDomain(),
    );
  }

  /// Creates a household member.
  Future<Person> createPerson({
    required String name,
    required double dailySpendingPercentage,
    required int emergencyFundMonths,
  }) async {
    final data = await _client.post('/api/people', {
      'name': name,
      'dailySpendingPercentage': dailySpendingPercentage,
      'emergencyFundMonths': emergencyFundMonths,
    });
    return mapJson(data, (json) => PersonModel.fromJson(json).toDomain());
  }

  /// Updates the person [id].
  Future<Person> updatePerson(
    String id, {
    required String name,
    required double dailySpendingPercentage,
    required int emergencyFundMonths,
  }) async {
    final data = await _client.put('/api/people/$id', {
      'name': name,
      'dailySpendingPercentage': dailySpendingPercentage,
      'emergencyFundMonths': emergencyFundMonths,
    });
    return mapJson(data, (json) => PersonModel.fromJson(json).toDomain());
  }

  /// Saves all of [personId]'s incomes in one transaction: each draft with an
  /// [PersonIncomeDraft.id] updates that record, the others are inserted.
  /// Records not listed are left untouched.
  ///
  /// The server detects the years whose available funding rose and returns them
  /// as `raises`; only it can, because the before state is gone once saved.
  Future<SavedPersonIncomes> saveIncomes(
    String personId,
    List<PersonIncomeDraft> incomes,
  ) async {
    final data = await _client.post('/api/people/$personId/incomes', {
      'incomes': [
        for (final income in incomes)
          {
            if (income.id != null) 'id': income.id,
            'amount': income.amount,
            'validFrom': income.validFrom,
          },
      ],
    });
    return mapJson(
      data,
      (json) => SavedPersonIncomes(
        incomes: mapJsonList(
          json['incomes'] ?? const <Object?>[],
          (item) => PersonIncomeModel.fromJson(item).toDomain(),
        ),
        raises: mapJsonList(
          json['raises'] ?? const <Object?>[],
          (item) => PersonIncomeRaiseModel.fromJson(item).toDomain(),
        ),
      ),
    );
  }
}
