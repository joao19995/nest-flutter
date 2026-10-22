import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/person_income.dart';

import '../../support/test_helpers.dart';

PeopleRepository _repository(MockClient mock) => PeopleRepository(
  client: NestApiClient(
    httpClient: mock,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

void main() {
  test('fetchPeople maps the list and fails on a non-list', () async {
    final people = await _repository(
      MockClient(
        (request) async => jsonResponse(const [
          {'id': 'p1', 'name': 'João', 'dailySpendingPercentage': 25},
        ]),
      ),
    ).fetchPeople();
    expect(people.single.name, 'João');
    expect(people.single.dailySpendingPercentage, 25);

    await expectLater(
      _repository(
        MockClient((request) async => jsonResponse(const {'not': 'a list'})),
      ).fetchPeople(),
      throwsA(isA<ApiFailure>()),
    );
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
          return jsonResponse(const [
            {
              'id': 'p1',
              'name': 'João',
              'dailySpendingPercentage': 25,
              'applicableIncome': 2500,
              'applicableIncomeId': 'i9',
            },
          ]);
        }),
      );

      final people = await repository.fetchPeople(incomeMonth: '2026-01');

      expect(path, '/api/people');
      expect(query, '2026-01');
      expect(people.single.applicableIncome, 2500);
      expect(people.single.applicableIncomeId, 'i9');
    },
  );

  test('fetchAllIncomes reads the batch endpoint', () async {
    String? path;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        return jsonResponse(const [
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

  test('createPerson posts the person fields', () async {
    String? method;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        method = request.method;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(const {
          'id': 'p1',
          'name': 'João',
          'dailySpendingPercentage': 25,
          'emergencyFundMonths': 6,
        }, status: 201);
      }),
    );

    final person = await repository.createPerson(
      name: 'João',
      dailySpendingPercentage: 25,
      emergencyFundMonths: 6,
    );

    expect(method, 'POST');
    expect(body?['name'], 'João');
    expect(body?['emergencyFundMonths'], 6);
    expect(person.emergencyFundMonths, 6);
  });

  test('updatePerson puts the fields to the id path', () async {
    String? path;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(const {
          'id': 'p1',
          'name': 'Ana',
          'dailySpendingPercentage': 10,
          'emergencyFundMonths': 9,
        });
      }),
    );

    await repository.updatePerson(
      'p1',
      name: 'Ana',
      dailySpendingPercentage: 10,
      emergencyFundMonths: 9,
    );

    expect(path, '/api/people/p1');
    expect(body?['dailySpendingPercentage'], 10);
    expect(body?['emergencyFundMonths'], 9);
  });

  test('saveIncomes posts the batch and maps incomes and raises', () async {
    String? path;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(const {
          'incomes': [
            {
              'id': 'i1',
              'personId': 'p1',
              'amount': 1600,
              'validFrom': '2026-04-01',
            },
          ],
          'raises': [
            {
              'year': 2026,
              'extra': 1200.5,
              'annualTotal': 13200.5,
              'validFromMonth': '2026-04',
            },
          ],
        });
      }),
    );

    final result = await repository.saveIncomes('p1', const [
      PersonIncomeDraft(amount: 1600, validFrom: '2026-04-01'),
    ]);

    expect(path, '/api/people/p1/incomes');
    final items = (body?['incomes'] as List).cast<Map<String, dynamic>>();
    expect(items.single.containsKey('id'), isFalse);
    expect(items.single['amount'], 1600);
    expect(result.incomes.single.id, 'i1');
    expect(result.raises.single.extra, 1200.5);
    expect(result.raises.single.validFromMonth, '2026-04');
  });

  test(
    'saveIncomes includes the id when updating an existing record',
    () async {
      Map<String, dynamic>? body;
      final repository = _repository(
        MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse(const {
            'incomes': <Object>[],
            'raises': <Object>[],
          });
        }),
      );

      await repository.saveIncomes('p1', const [
        PersonIncomeDraft(id: 'i1', amount: 2000, validFrom: '2026-01-01'),
      ]);

      final items = (body?['incomes'] as List).cast<Map<String, dynamic>>();
      expect(items.single['id'], 'i1');
    },
  );
}
