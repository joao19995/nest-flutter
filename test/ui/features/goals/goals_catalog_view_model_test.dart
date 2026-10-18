import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/goals/view_models/goals_catalog_view_model.dart';

GoalsCatalogViewModel _viewModel(MockClient client) => GoalsCatalogViewModel(
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
  test('load maps active and inactive goals, ordered by name', () async {
    final client = MockClient(
      (request) async => _json(const [
        {'id': 'g1', 'name': 'Viagem', 'active': true},
        {'id': 'g2', 'name': 'Carro', 'active': false},
      ]),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.goals, hasLength(2));
    expect(viewModel.goals.first.name, 'Carro');
    expect(viewModel.goals.last.active, isTrue);
  });

  test('createGoal adds the goal to the catalogue', () async {
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        return _json(const {
          'id': 'g3',
          'name': 'Casa',
          'active': true,
        }, status: 201);
      }
      return _json(const <Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    final failure = await viewModel.createGoal('Casa');

    expect(failure, isNull);
    expect(viewModel.goals.single.name, 'Casa');
  });

  test(
    'deleteGoal marks the goal inactive and restore reactivates it',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/goals') {
          return _json(const [
            {'id': 'g1', 'name': 'Viagem', 'active': true},
          ]);
        }
        if (request.method == 'DELETE') {
          return _json(const {'id': 'g1'});
        }
        return _json(const {'id': 'g1', 'name': 'Viagem', 'active': true});
      });

      final viewModel = _viewModel(client);
      await viewModel.load();
      final goal = viewModel.goals.single;

      expect(await viewModel.deleteGoal(goal), isNull);
      expect(viewModel.goals.single.active, isFalse);

      expect(await viewModel.restoreGoal(goal), isNull);
      expect(viewModel.goals.single.active, isTrue);
    },
  );
}
