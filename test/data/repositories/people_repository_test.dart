import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';

PeopleRepository _repository(MockClient mock) => PeopleRepository(
  client: NestApiClient(
    httpClient: mock,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('fetchPeople maps the list and tolerates a non-list', () async {
    final people = await _repository(
      MockClient(
        (request) async => _json(const [
          {'id': 'p1', 'name': 'João', 'dailySpendingPercentage': 25},
        ]),
      ),
    ).fetchPeople();
    expect(people.single.name, 'João');
    expect(people.single.dailySpendingPercentage, 25);

    final empty = await _repository(
      MockClient((request) async => _json(const {'not': 'a list'})),
    ).fetchPeople();
    expect(empty, isEmpty);
  });

  test(
    'fetchPeople with incomeMonth adds the query and maps the income',
    () async {
      String? path;
      String? query;
      final repository = _repository(
        MockClient((request) async {
          path = request.url.path;
          query = request.url.queryParameters['incomeMonth'];
          return _json(const [
            {
              'id': 'p1',
              'name': 'João',
              'dailySpendingPercentage': 25,
              'applicableIncome': 2500,
            },
          ]);
        }),
      );

      final people = await repository.fetchPeople(incomeMonth: '2026-01');

      expect(path, '/api/people');
      expect(query, '2026-01');
      expect(people.single.applicableIncome, 2500);
    },
  );

  test('fetchAllIncomes reads the batch endpoint', () async {
    String? path;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        return _json(const [
          {
            'id': 'i1',
            'personId': 'p1',
            'amount': 2500,
            'validFrom': '2026-01-01',
          },
          {
            'id': 'i2',
            'personId': 'p2',
            'amount': 1500,
            'validFrom': '2026-01-01',
          },
        ]);
      }),
    );

    final incomes = await repository.fetchAllIncomes();

    expect(path, '/api/people/incomes');
    expect(incomes, hasLength(2));
    expect(incomes.last.personId, 'p2');
  });
}
