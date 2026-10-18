import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/ui/features/goals/view_models/goal_templates_view_model.dart';

GoalTemplatesViewModel _viewModel(MockClient client) => GoalTemplatesViewModel(
  goalsRepository: GoalsRepository(
    client: NestApiClient(
      httpClient: client,
      baseUrl: 'http://test.local',
      apiKey: '',
    ),
  ),
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('load maps the versions and keeps only the active goals', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/goal-templates') {
        return _json(const [
          {
            'id': 't1',
            'validFrom': '2026-01',
            'annualTotal': 12000,
            'entries': [
              {
                'goalId': 'g1',
                'percentage': 100,
                'budget': 12000,
                'timeline': 'ANUAL',
                'priority': 'GRANDE',
                'notes': '',
              },
            ],
          },
        ]);
      }
      if (request.url.path == '/api/goals') {
        return _json(const [
          {'id': 'g1', 'name': 'Viagem', 'active': true},
          {'id': 'g2', 'name': 'Carro', 'active': false},
        ]);
      }
      return _json(const <Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.templates, hasLength(1));
    expect(viewModel.goals.single.id, 'g1');
  });

  test(
    'createVersion posts the table and adopts the returned version',
    () async {
      String? path;
      Map<String, dynamic>? body;
      final client = MockClient((request) async {
        if (request.url.path == '/api/goal-plan') {
          return _json(const {
            'plans': <Object>[],
            'funding': {
              'year': 2026,
              'annualTotal': 12000,
              'months': <Object>[],
            },
          });
        }
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json(const {
          'template': {
            'id': 't2',
            'validFrom': '2026-06',
            'annualTotal': 12000,
            'entries': <Object>[],
          },
          'plans': <Object>[],
        }, status: 201);
      });

      final viewModel = _viewModel(client);
      final failure = await viewModel.createVersion(
        validFrom: '2026-06',
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

      expect(failure, isNull);
      expect(path, '/api/goal-templates');
      expect(body?['validFrom'], '2026-06');
      expect(body?['annualTotal'], 12000);
      expect(viewModel.templates.single.id, 't2');
    },
  );
}
