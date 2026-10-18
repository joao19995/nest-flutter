import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';

GoalsRepository _repository(MockClient mock) => GoalsRepository(
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
  test('fetchGoals maps the list and tolerates a non-list', () async {
    final goals = await _repository(
      MockClient(
        (request) async => _json(const [
          {'id': 'g1', 'name': 'Viagem', 'active': true},
        ]),
      ),
    ).fetchGoals();
    expect(goals.single.name, 'Viagem');

    final empty = await _repository(
      MockClient((request) async => _json(const {'not': 'a list'})),
    ).fetchGoals();
    expect(empty, isEmpty);
  });

  test(
    'fetchGoalMonth reads the month path and returns null when absent',
    () async {
      final paths = <String>[];
      final repository = _repository(
        MockClient((request) async {
          paths.add(request.url.path);
          return _json(const {
            'month': '2026-02',
            'planId': null,
            'closed': false,
            'availableAmount': 0,
            'allocations': <Object>[],
          });
        }),
      );

      expect(await repository.fetchGoalMonth('2026-02'), isNull);
      expect(paths, ['/api/goal-plan/2026-02']);
    },
  );

  test('fetchGoalMonth treats a 404 as a missing month', () async {
    final repository = _repository(
      MockClient(
        (request) async => _json(const {'error': 'Não existe.'}, status: 404),
      ),
    );

    expect(await repository.fetchGoalMonth('2026-02'), isNull);
  });

  test('fetchGoalYear throws ApiFailure on an unexpected payload', () async {
    final repository = _repository(
      MockClient((request) async => _json(const <Object>[])),
    );

    await expectLater(
      repository.fetchGoalYear(2026),
      throwsA(isA<ApiFailure>()),
    );
  });

  test('createGoalPlan posts the month', () async {
    Object? body;
    final repository = _repository(
      MockClient((request) async {
        body = jsonDecode(request.body);
        return _json(const {
          'id': 'p1',
          'month': '2026-03',
          'availableAmount': 1000,
          'closed': false,
          'allocations': <Object>[],
        }, status: 201);
      }),
    );

    final plan = await repository.createGoalPlan('2026-03');

    expect((body as Map<String, dynamic>)['month'], '2026-03');
    expect(plan.id, 'p1');
  });

  test('closeGoalPlan posts to the plan close endpoint', () async {
    String? path;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        return _json(const {
          'id': 'p1',
          'month': '2026-03',
          'availableAmount': 1000,
          'closed': true,
          'allocations': <Object>[],
        });
      }),
    );

    await repository.closeGoalPlan('p1');

    expect(path, '/api/goal-plan/p1/close');
  });
}
