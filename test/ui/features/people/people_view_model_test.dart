import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/people/view_models/people_view_model.dart';

PeopleViewModel _viewModel(MockClient client) => PeopleViewModel(
  peopleRepository: PeopleRepository(
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

List<Object> _people() => <Object>[
  {
    'id': 'p1',
    'name': 'João',
    'dailySpendingPercentage': 25,
    'applicableIncome': 2500,
    'applicableIncomeId': 'i-new-p1',
  },
  {
    'id': 'p2',
    'name': 'Nathalia',
    'dailySpendingPercentage': 10,
    'applicableIncome': 1500,
    'applicableIncomeId': 'i-new-p2',
  },
];

List<Object> _allIncomes() => <Object>[
  {
    'id': 'i-old-p1',
    'personId': 'p1',
    'amount': 2000,
    'validFrom': '2000-01-01',
  },
  {
    'id': 'i-old-p2',
    'personId': 'p2',
    'amount': 1000,
    'validFrom': '2000-01-01',
  },
  {
    'id': 'i-new-p1',
    'personId': 'p1',
    'amount': 2500,
    'validFrom': '2000-06-01',
  },
  {
    'id': 'i-new-p2',
    'personId': 'p2',
    'amount': 1500,
    'validFrom': '2000-06-01',
  },
];

MockClient _client() => MockClient((request) async {
  if (request.url.path == '/api/people') {
    return _json(_people());
  }
  if (request.url.path == '/api/people/incomes') {
    return _json(_allIncomes());
  }
  return _json(<Object>[], status: 404);
});

void main() {
  test(
    'load derives the salary from the server income and daily spending',
    () async {
      final viewModel = _viewModel(_client());

      await viewModel.load();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isEmpty, isFalse);
      expect(viewModel.summaries, hasLength(2));
      expect(viewModel.householdIncome, 4000);

      final joao = viewModel.summaries.firstWhere(
        (s) => s.person.name == 'João',
      );
      expect(joao.monthlyIncome, 2500);
      expect(joao.person.applicableIncomeId, 'i-new-p1');
      expect(joao.dailySpending, 625);
      expect(joao.incomes, hasLength(2));
    },
  );

  test('reads people and incomes in two requests (no N+1)', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/api/people') {
        return _json(_people());
      }
      return _json(_allIncomes());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(paths, ['/api/people', '/api/people/incomes']);
  });

  test('a person without applicable income reports zero', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/people') {
        return _json(const [
          {'id': 'p1', 'name': 'João', 'dailySpendingPercentage': 25},
        ]);
      }
      return _json(<Object>[]); // empty income history
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.summaries.first.monthlyIncome, 0);
    expect(viewModel.householdIncome, 0);
  });

  test('reports a failure without throwing', () async {
    final client = MockClient(
      (request) async => _json(const {'error': 'Falhou.'}, status: 500),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, 'Falhou.');
    expect(viewModel.isEmpty, isTrue);
  });
}
