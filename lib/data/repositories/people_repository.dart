import 'package:nest/data/models/person_model.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/person.dart';

/// Reads and writes household members.
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

  /// Creates a person and returns the persisted entity.
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
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return PersonModel.fromJson(data).toDomain();
  }
}
