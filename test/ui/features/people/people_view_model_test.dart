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
  {'id': 'p1', 'name': 'João', 'dailySpendingPercentage': 25},
  {'id': 'p2', 'name': 'Nathalia', 'dailySpendingPercentage': 10},
];

List<Object> _incomes(String personId) => <Object>[
  {
    'id': 'i-old-$personId',
    'personId': personId,
    'amount': personId == 'p1' ? 2000 : 1000,
    'validFrom': '2000-01-01',
  },
  {
    'id': 'i-new-$personId',
    'personId': personId,
    'amount': personId == 'p1' ? 2500 : 1500,
    'validFrom': '2000-06-01',
  },
];

MockClient _client() => MockClient((request) async {
  if (request.url.path == '/api/people') {
    return _json(_people());
  }
  final match = RegExp(
    r'^/api/people/([^/]+)/income$',
  ).firstMatch(request.url.path);
  if (match != null) {
    return _json(_incomes(match.group(1)!));
  }
  return _json(<Object>[], status: 404);
});

void main() {
  test(
    'load derives the current salary and daily spending per person',
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
      expect(joao.currentIncomeId, 'i-new-p1');
      expect(joao.dailySpending, 625);
      expect(joao.incomes, hasLength(2));
    },
  );

  test('a person without applicable income reports zero', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/people') {
        return _json(_people());
      }
      return _json(<Object>[]); // empty income history
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.summaries.first.monthlyIncome, 0);
    expect(viewModel.summaries.first.currentIncomeId, isNull);
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
