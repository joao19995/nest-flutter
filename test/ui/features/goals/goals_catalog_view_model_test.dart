import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/goals/view_models/goals_catalog_view_model.dart';

import '../../../support/test_helpers.dart';

GoalsCatalogViewModel _viewModel(MockClient client) => GoalsCatalogViewModel(
  goalsRepository: GoalsRepository(
    client: NestApiClient(
      httpClient: client,
      baseUrl: 'http://test.local',
      apiKey: '',
    ),
  ),
);

void main() {
  test('load maps active and inactive goals, ordered by name', () async {
    final client = MockClient(
      (request) async => jsonResponse(const [
        {'id': 'g1', 'name': 'Viagem', 'active': true},
        {'id': 'g2', 'name': 'Carro', 'active': false},
      ]),
    );

    final viewModel = _viewModel(client);
    await viewModel.setIncludeInactive(true);

    expect(viewModel.goals, hasLength(2));
    expect(viewModel.goals.first.name, 'Carro');
    expect(viewModel.goals.last.active, isTrue);
  });

  test('createGoal adds the goal to the catalogue', () async {
    Object? body;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        body = jsonDecode(request.body);
        return jsonResponse(const {
          'id': 'g3',
          'name': 'Casa',
          'active': true,
          'iconKey': 'home',
        }, status: 201);
      }
      return jsonResponse(const <Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    final failure = await viewModel.createGoal('Casa', iconKey: 'home');

    expect(failure, isNull);
    expect(viewModel.goals.single.name, 'Casa');
    expect(viewModel.goals.single.iconKey, 'home');
    expect((body as Map<String, dynamic>)['iconKey'], 'home');
  });

  test(
    'deleteGoal marks the goal inactive and restore reactivates it',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/goals') {
          return jsonResponse(const [
            {'id': 'g1', 'name': 'Viagem', 'active': true},
          ]);
        }
        if (request.method == 'DELETE') {
          return jsonResponse(const {'id': 'g1'});
        }
        return jsonResponse(const {
          'id': 'g1',
          'name': 'Viagem',
          'active': true,
        });
      });

      final viewModel = _viewModel(client);
      await viewModel.load();
      final goal = viewModel.goals.single;

      expect(await viewModel.deleteGoal(goal), isNull);
      expect(viewModel.goals, isEmpty);

      expect(await viewModel.restoreGoal(goal), isNull);
      expect(viewModel.goals.single.active, isTrue);
    },
  );
}
