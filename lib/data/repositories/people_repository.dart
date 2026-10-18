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
  Future<List<Person>> fetchPeople() async {
    final data = await _client.get('/api/people');
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => PersonModel.fromJson(json).toDomain())
        .toList(growable: false);
  }

  /// Returns the income history of [personId], ordered by `validFrom`.
  Future<List<PersonIncome>> fetchIncomes(String personId) async {
    final data = await _client.get('/api/people/$personId/income');
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => PersonIncomeModel.fromJson(json).toDomain())
        .toList(growable: false);
  }
}
