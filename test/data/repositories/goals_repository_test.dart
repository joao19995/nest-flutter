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
    'fetchGoalMonth reads the month path and maps an uncreated month',
    () async {
      final paths = <String>[];
      final repository = _repository(
        MockClient((request) async {
          paths.add(request.url.path);
          return _json(const {
            'month': '2026-02',
            'planId': null,
            'closed': false,
            'availableAmount': 500,
            'allocations': <Object>[],
            'quotas': <Object>[],
          });
        }),
      );

      final view = await repository.fetchGoalMonth('2026-02');

      expect(view, isNotNull);
      expect(view?.plan, isNull);
      expect(view?.availableAmount, 500);
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

  test('computeGoalQuotas posts the drafts and maps the quotas', () async {
    Object? body;
    final repository = _repository(
      MockClient((request) async {
        body = jsonDecode(request.body);
        return _json(const {
          'quotas': [
            {
              'personId': 'p1',
              'name': 'João',
              'earning': 2500,
              'share': 1,
              'amount': 600,
              'parts': [
                {'goalId': 'g1', 'name': 'Viagem', 'amount': 600},
              ],
            },
          ],
        });
      }),
    );

    final quotas = await repository.computeGoalQuotas('2026-01', const [
      (goalId: 'g1', name: 'Viagem', amount: 600),
    ]);

    final sent = body as Map<String, dynamic>;
    expect(sent['month'], '2026-01');
    expect(sent['allocations'], [
      {'goalId': 'g1', 'name': 'Viagem', 'amount': 600},
    ]);
    expect(quotas.single.name, 'João');
    expect(quotas.single.parts.single.amount, 600);
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

  test('updateGoalAllocation patches the month allocation endpoint', () async {
    String? path;
    Object? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body);
        return _json(const {
          'id': 'p1',
          'month': '2026-01',
          'availableAmount': 1000,
          'closed': false,
          'allocations': <Object>[],
        });
      }),
    );

    await repository.updateGoalAllocation('2026-01', 'g1', 800);

    expect(path, '/api/goal-plan/2026-01/allocations/g1');
    expect((body as Map<String, dynamic>)['actual'], 800);
  });

  test('closeGoalPlan posts to the month close endpoint', () async {
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

    await repository.closeGoalPlan('2026-03');

    expect(path, '/api/goal-plan/2026-03/close');
  });
}
