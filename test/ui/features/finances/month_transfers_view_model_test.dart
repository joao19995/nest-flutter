import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/finances/view_models/month_transfers_view_model.dart';

import '../../../support/test_helpers.dart';

const _month = '2026-01';

MonthTransfersViewModel _viewModel(MockClient client) {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  return MonthTransfersViewModel(
    expensesRepository: ExpensesRepository(client: api),
    goalsRepository: GoalsRepository(client: api),
    month: _month,
  );
}

Map<String, dynamic> _expenseMonth() => <String, dynamic>{
  'id': 'm1',
  'month': _month,
  'templateId': 't1',
  'closed': true,
  'entries': <Object>[],
  'summary': {
    'month': _month,
    'status': 'closed',
    'planned': 600,
    'actual': 620,
    'progressPct': 103.33,
    'over': true,
  },
  'settlement': {
    'status': 'ok',
    'contributionRequired': 600,
    'jointSurplus': 0,
    'people': [
      {
        'personId': 'p1',
        'personName': 'João',
        'income': 2500,
        'quota': 300,
        'personalActual': 620,
        'transferToJoint': 0,
        'transferToPerson': 320,
      },
    ],
  },
};

Map<String, dynamic> _goalMonth({bool closed = true}) => <String, dynamic>{
  'month': _month,
  'planId': 'p1',
  'closed': closed,
  'availableAmount': 1000,
  'funding': {
    'month': _month,
    'incomeNormal': 2500,
    'bonus': 0,
    'dailyAllowance': 500,
    'contributionRequired': 1000,
    'available': 1000,
  },
  'totals': {'planned': 1000, 'actual': 1000, 'reserved': 1000},
  'allocations': <Object>[],
  'quotas': [
    {
      'personId': 'p1',
      'name': 'João',
      'earning': 2500,
      'share': 1,
      'amount': 1000,
      'parts': [
        {'goalId': 'g1', 'name': 'Viagem', 'amount': 1000},
      ],
    },
  ],
};

List<Object> _goals() => <Object>[
  {'id': 'g1', 'name': 'Viagem', 'active': true, 'iconKey': 'plane'},
];

void main() {
  test(
    'loads both closed months and builds the definitive transfers',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/months/$_month') {
          return jsonResponse(_expenseMonth());
        }
        if (request.url.path == '/api/goal-plan/$_month') {
          return jsonResponse(_goalMonth());
        }
        if (request.url.path == '/api/goals') {
          return jsonResponse(_goals());
        }
        return jsonResponse(const {'error': 'not found'}, status: 404);
      });

      final viewModel = _viewModel(client);
      await viewModel.load();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.expensesClosed, isTrue);
      expect(viewModel.goalsClosed, isTrue);
      expect(viewModel.iconKeyByGoal['g1'], 'plane');
      expect(viewModel.transfers.closed, isTrue);
      expect(viewModel.transfers.people, hasLength(1));
      expect(viewModel.transfers.totals.fromJoint, 320);
      expect(viewModel.transfers.totals.toGoals, 1000);
    },
  );

  test('a missing goal month is a partial view, not an error', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/$_month') {
        return jsonResponse(_expenseMonth());
      }
      return jsonResponse(const {'error': 'not found'}, status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.errorMessage, isNull);
    expect(viewModel.expensesClosed, isTrue);
    expect(viewModel.goalsMissing, isTrue);
    expect(viewModel.transfers.closed, isFalse);
  });

  test('a failed expense month records the error', () async {
    final client = MockClient(
      (request) async => jsonResponse(const {'error': 'Falhou.'}, status: 500),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.errorMessage, 'Falhou.');
    expect(viewModel.isLoading, isFalse);
  });
}
