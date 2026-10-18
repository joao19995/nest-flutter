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
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => PersonModel.fromJson(json).toDomain())
        .toList(growable: false);
  }

  /// Returns every income record for every person in one request, ordered by
  /// `validFrom`. Replaces the per-person reads (the N+1).
  Future<List<PersonIncome>> fetchAllIncomes() async {
    final data = await _client.get('/api/people/incomes');
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => PersonIncomeModel.fromJson(json).toDomain())
        .toList(growable: false);
  }
}
