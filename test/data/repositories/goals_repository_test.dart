import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal_template.dart';

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

  test('updateGoalAllocation patches and maps the returned view', () async {
    String? path;
    Object? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body);
        return _json(const {
          'month': '2026-01',
          'planId': 'p1',
          'closed': false,
          'availableAmount': 1000,
          'allocations': [
            {
              'goalId': 'g1',
              'goalName': 'Viagem',
              'planned': 600,
              'actual': 800,
            },
          ],
          'quotas': <Object>[],
        });
      }),
    );

    final view = await repository.updateGoalAllocation('2026-01', 'g1', 800);

    expect(path, '/api/goal-plan/2026-01/allocations/g1');
    expect((body as Map<String, dynamic>)['actual'], 800);
    expect(view.plan?.id, 'p1');
  });

  test(
    'closeGoalPlan posts to the month close endpoint and maps the view',
    () async {
      String? path;
      final repository = _repository(
        MockClient((request) async {
          path = request.url.path;
          return _json(const {
            'month': '2026-03',
            'planId': 'p1',
            'closed': true,
            'availableAmount': 1000,
            'allocations': <Object>[],
            'quotas': <Object>[],
          });
        }),
      );

      final view = await repository.closeGoalPlan('2026-03');

      expect(path, '/api/goal-plan/2026-03/close');
      expect(view.plan?.closed, isTrue);
    },
  );

  test(
    'fetchGoalTemplates maps the versions and tolerates a non-list',
    () async {
      final templates = await _repository(
        MockClient(
          (request) async => _json(const [
            {
              'id': 't1',
              'validFrom': '2026-01',
              'annualTotal': 12000,
              'entries': [
                {'goalId': 'g1', 'budget': 6000},
              ],
            },
          ]),
        ),
      ).fetchGoalTemplates();

      expect(templates.single.validFrom, '2026-01');
      expect(templates.single.entries.single.goalId, 'g1');

      final empty = await _repository(
        MockClient((request) async => _json(const {'not': 'a list'})),
      ).fetchGoalTemplates();
      expect(empty, isEmpty);
    },
  );

  test('allocateRaise posts validFrom, goalId and extra', () async {
    String? path;
    Object? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body);
        return _json(const {
          'template': {
            'id': 't2',
            'validFrom': '2026-04',
            'entries': <Object>[],
          },
          'plans': <Object>[],
        }, status: 201);
      }),
    );

    await repository.allocateRaise(
      validFrom: '2026-04',
      goalId: 'g1',
      extra: 1200.5,
    );

    expect(path, '/api/goal-templates/raise');
    final payload = body as Map<String, dynamic>;
    expect(payload['validFrom'], '2026-04');
    expect(payload['goalId'], 'g1');
    expect(payload['extra'], 1200.5);
  });

  test(
    'createGoal, updateGoal, deleteGoal and restoreGoal hit the routes',
    () async {
      final calls = <String>[];
      final bodies = <Object?>[];
      final repository = _repository(
        MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          bodies.add(request.body.isEmpty ? null : jsonDecode(request.body));
          if (request.method == 'DELETE') {
            return _json(const {'id': 'g1'});
          }
          return _json(const {'id': 'g1', 'name': 'Férias', 'active': true});
        }),
      );

      await repository.createGoal(name: 'Férias');
      await repository.updateGoal('g1', name: 'Férias 2026');
      await repository.deleteGoal('g1');
      await repository.restoreGoal('g1');

      expect(calls, [
        'POST /api/goals',
        'PUT /api/goals/g1',
        'DELETE /api/goals/g1',
        'POST /api/goals/g1/restore',
      ]);
      expect((bodies[0] as Map<String, dynamic>)['name'], 'Férias');
      expect((bodies[1] as Map<String, dynamic>)['name'], 'Férias 2026');
    },
  );

  test('createGoalTemplate posts the API timeline and priority', () async {
    String? path;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json(const {
          'template': {
            'id': 't1',
            'validFrom': '2026-01',
            'annualTotal': 12000,
            'entries': <Object>[],
          },
          'plans': <Object>[],
        }, status: 201);
      }),
    );

    final template = await repository.createGoalTemplate(
      validFrom: '2026-01',
      annualTotal: 12000,
      entries: const [
        GoalTemplateEntry(
          goalId: 'g1',
          percentage: 100,
          budget: 12000,
          timeline: GoalTimeline.t4,
          priority: GoalPriority.niceToHave,
          notes: 'nota',
        ),
      ],
    );

    expect(path, '/api/goal-templates');
    expect(body?['validFrom'], '2026-01');
    expect(body?['annualTotal'], 12000);
    final entries = (body?['entries'] as List).cast<Map<String, dynamic>>();
    expect(entries.single['timeline'], 'T4');
    expect(entries.single['priority'], 'NICE_TO_HAVE');
    expect(entries.single['notes'], 'nota');
    expect(template.id, 't1');
  });

  test('updateGoalTemplate puts the annual total and entries', () async {
    String? path;
    String? method;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        method = request.method;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json(const {
          'template': {
            'id': 't1',
            'validFrom': '2026-01',
            'annualTotal': 12000,
            'entries': <Object>[],
          },
          'plans': <Object>[],
        });
      }),
    );

    await repository.updateGoalTemplate(
      't1',
      annualTotal: 12000,
      entries: const [
        GoalTemplateEntry(
          goalId: 'g1',
          percentage: 100,
          budget: 12000,
          timeline: GoalTimeline.annual,
          priority: GoalPriority.grande,
          notes: '',
        ),
      ],
    );

    expect(method, 'PUT');
    expect(path, '/api/goal-templates/t1');
    expect(body?.containsKey('validFrom'), isFalse);
    expect(body?['annualTotal'], 12000);
  });
}
