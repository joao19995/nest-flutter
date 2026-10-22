import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/person_income.dart';
import 'package:nest/ui/features/people/view_models/people_view_model.dart';

import '../../../support/test_helpers.dart';

PeopleViewModel _viewModel(MockClient client) {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  return PeopleViewModel(
    peopleRepository: PeopleRepository(client: api),
    goalsRepository: GoalsRepository(client: api),
  );
}

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
    return jsonResponse(_people());
  }
  if (request.url.path == '/api/people/incomes') {
    return jsonResponse(_allIncomes());
  }
  return jsonResponse(<Object>[], status: 404);
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
        return jsonResponse(_people());
      }
      return jsonResponse(_allIncomes());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(paths, ['/api/people', '/api/people/incomes']);
  });

  test('a person without applicable income reports zero', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/people') {
        return jsonResponse(const [
          {'id': 'p1', 'name': 'João', 'dailySpendingPercentage': 25},
        ]);
      }
      return jsonResponse(<Object>[]); // empty income history
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.summaries.first.monthlyIncome, 0);
    expect(viewModel.householdIncome, 0);
  });

  test('reports a failure without throwing', () async {
    final client = MockClient(
      (request) async => jsonResponse(const {'error': 'Falhou.'}, status: 500),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, 'Falhou.');
    expect(viewModel.isEmpty, isTrue);
  });

  test(
    'savePerson saves the incomes and exposes the raise to allocate',
    () async {
      final calls = <String>[];
      final client = MockClient((request) async {
        final path = request.url.path;
        calls.add('${request.method} $path');
        if (path == '/api/people') {
          return jsonResponse(const {
            'id': 'p1',
            'name': 'João',
            'dailySpendingPercentage': 25,
            'emergencyFundMonths': 6,
          }, status: 201);
        }
        if (path == '/api/people/p1/incomes') {
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
        }
        if (path == '/api/goal-templates') {
          return jsonResponse(const [
            {
              'id': 't1',
              'validFrom': '2026-01',
              'annualTotal': 12000,
              'entries': [
                {'goalId': 'g1', 'budget': 6000},
              ],
            },
          ]);
        }
        if (path == '/api/goals') {
          return jsonResponse(const [
            {'id': 'g1', 'name': 'Viagem', 'active': true},
          ]);
        }
        if (path == '/api/goal-templates/raise') {
          return jsonResponse(const {
            'template': {
              'id': 't2',
              'validFrom': '2026-04',
              'entries': <Object>[],
            },
            'plans': <Object>[],
          }, status: 201);
        }
        return jsonResponse(const <Object>[], status: 404);
      });

      final viewModel = _viewModel(client);
      final failure = await viewModel.savePerson(
        name: 'João',
        dailySpendingPercentage: 25,
        emergencyFundMonths: 6,
        incomes: const [
          PersonIncomeDraft(amount: 1600, validFrom: '2026-04-01'),
        ],
      );

      expect(failure, isNull);
      expect(calls.first, 'POST /api/people');
      expect(calls[1], 'POST /api/people/p1/incomes');
      expect(viewModel.summaries.single.person.name, 'João');
      expect(viewModel.pendingRaise?.extra, 1200.5);
      expect(viewModel.pendingRaise?.validFromMonth, '2026-04');
      expect(viewModel.raiseGoalOptions.single.name, 'Viagem');
      expect(viewModel.raiseMonthTaken, isFalse);

      final allocateFailure = await viewModel.allocateRaise('g1');

      expect(allocateFailure, isNull);
      expect(calls.last, 'POST /api/goal-templates/raise');
      expect(viewModel.pendingRaise, isNull);
    },
  );
}
