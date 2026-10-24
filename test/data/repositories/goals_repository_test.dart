import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal_template.dart';

import '../../support/test_helpers.dart';

GoalsRepository _repository(MockClient mock) => GoalsRepository(
  client: NestApiClient(
    httpClient: mock,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

void main() {
  test('converts mapping errors into ApiFailure', () async {
    await expectLater(
      _repository(
        MockClient(
          (request) async => jsonResponse([
            {'id': 'g1'},
          ]),
        ),
      ).fetchGoals(),
      throwsA(isA<ApiFailure>()),
    );
  });

  test('fetchGoals maps the list and fails on a non-list', () async {
    final goals = await _repository(
      MockClient(
        (request) async => jsonResponse(const [
          {'id': 'g1', 'name': 'Viagem', 'active': true},
        ]),
      ),
    ).fetchGoals();
    expect(goals.single.name, 'Viagem');

    await expectLater(
      _repository(
        MockClient((request) async => jsonResponse(const {'not': 'a list'})),
      ).fetchGoals(),
      throwsA(isA<ApiFailure>()),
    );
  });

  test(
    'fetchGoalMonth reads the month path and maps an uncreated month',
    () async {
      final paths = <String>[];
      final repository = _repository(
        MockClient((request) async {
          paths.add(request.url.path);
          return jsonResponse(const {
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
        (request) async =>
            jsonResponse(const {'error': 'Não existe.'}, status: 404),
      ),
    );

    expect(await repository.fetchGoalMonth('2026-02'), isNull);
  });

  test('fetchGoalYear throws ApiFailure on an unexpected payload', () async {
    final repository = _repository(
      MockClient((request) async => jsonResponse(const <Object>[])),
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
        return jsonResponse(const {
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
        return jsonResponse(const {
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

  test('fetchGoalClosePreview reads the preview endpoint', () async {
    String? path;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        return jsonResponse(const {
          'month': '2026-01',
          'availableAmount': 1000,
          'plannedTotal': 900,
          'reservedTotal': 950,
          'unallocated': 100,
          'adjustedFromTemplate': true,
          'affectedFutureMonths': ['2026-02'],
          'defaulted': [
            {'goalId': 'g2', 'goalName': 'Carro', 'amount': 400},
          ],
          'quotas': [
            {
              'personId': 'p1',
              'name': 'João',
              'earning': 2500,
              'share': 1,
              'amount': 950,
              'parts': <Object>[],
            },
          ],
        });
      }),
    );

    final preview = await repository.fetchGoalClosePreview('2026-01');

    expect(path, '/api/goal-plan/2026-01/close-preview');
    expect(preview.adjustedFromTemplate, isTrue);
    expect(preview.defaulted.single.goalName, 'Carro');
    expect(preview.quotas.single.amount, 950);
  });

  test(
    'closeGoalPlan posts to the month close endpoint and maps the view',
    () async {
      String? path;
      final repository = _repository(
        MockClient((request) async {
          path = request.url.path;
          return jsonResponse(const {
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
    'fetchGoalTemplates maps the versions and fails on a non-list',
    () async {
      final templates = await _repository(
        MockClient(
          (request) async => jsonResponse(const [
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

      await expectLater(
        _repository(
          MockClient((request) async => jsonResponse(const {'not': 'a list'})),
        ).fetchGoalTemplates(),
        throwsA(isA<ApiFailure>()),
      );
    },
  );

  test('allocateRaise posts validFrom, goalId and extra', () async {
    String? path;
    Object? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body);
        return jsonResponse(const {
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
            return jsonResponse(const {'id': 'g1'});
          }
          return jsonResponse(const {
            'id': 'g1',
            'name': 'Férias',
            'active': true,
          });
        }),
      );

      await repository.createGoal(name: 'Férias', iconKey: 'plane');
      await repository.updateGoal('g1', name: 'Férias 2026', iconKey: 'car');
      await repository.deleteGoal('g1');
      await repository.restoreGoal('g1');

      expect(calls, [
        'POST /api/goals',
        'PUT /api/goals/g1',
        'DELETE /api/goals/g1',
        'POST /api/goals/g1/restore',
      ]);
      expect((bodies[0] as Map<String, dynamic>)['name'], 'Férias');
      expect((bodies[0] as Map<String, dynamic>)['iconKey'], 'plane');
      expect((bodies[1] as Map<String, dynamic>)['name'], 'Férias 2026');
      expect((bodies[1] as Map<String, dynamic>)['iconKey'], 'car');
    },
  );

  test('createGoalTemplate posts the API timeline and priority', () async {
    String? path;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(const {
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
        return jsonResponse(const {
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
