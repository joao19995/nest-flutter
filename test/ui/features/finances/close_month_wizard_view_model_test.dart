import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/ui/features/finances/view_models/close_month_wizard_view_model.dart';

import '../../../support/test_helpers.dart';

const _month = '2026-01';

CloseMonthWizardViewModel _viewModel(MockClient client) {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  return CloseMonthWizardViewModel(
    expensesRepository: ExpensesRepository(client: api),
    goalsRepository: GoalsRepository(client: api),
    month: _month,
  );
}

Map<String, dynamic> _settlement() => <String, dynamic>{
  'status': 'ok',
  'contributionRequired': 600,
  'jointSurplus': 0,
  'people': [
    {
      'personName': 'João',
      'income': 2500,
      'quota': 300,
      'personalActual': 620,
      'transferToJoint': 0,
      'transferToPerson': 320,
    },
    {
      'personName': 'Nathalia',
      'income': 2000,
      'quota': 300,
      'personalActual': 0,
      'transferToJoint': 300,
      'transferToPerson': 0,
    },
  ],
};

Map<String, dynamic> _expenseMonth({
  bool closed = false,
  bool withSettlement = false,
}) => <String, dynamic>{
  'id': 'm1',
  'month': _month,
  'templateId': 't1',
  'closed': closed,
  'entries': [
    {
      'id': 'e1',
      'categoryName': 'Casa',
      'categoryType': 'FIXED',
      'accountName': 'Conjunta',
      'planned': 500,
      'actual': 500,
      'actualSet': true,
    },
    {
      'id': 'e2',
      'categoryName': 'Luz',
      'categoryType': 'VARIABLE',
      'accountName': 'Conjunta',
      'planned': 100,
      'actual': 120,
      'actualSet': true,
    },
  ],
  'summary': {
    'month': _month,
    'status': closed ? 'closed' : 'open',
    'planned': 600,
    'actual': 620,
    'progressPct': 103.33,
    'over': true,
  },
  'settlement': withSettlement ? _settlement() : null,
};

List<Object> _quotas() => <Object>[
  {
    'personId': 'p1',
    'name': 'João',
    'earning': 2500,
    'share': 0.625,
    'amount': 625,
    'parts': [
      {'goalId': 'g1', 'name': 'Viagem', 'amount': 600},
      {'goalId': 'g2', 'name': 'Carro', 'amount': 25},
    ],
  },
  {
    'personId': 'p2',
    'name': 'Nathalia',
    'earning': 1500,
    'share': 0.375,
    'amount': 375,
    'parts': [
      {'goalId': 'g2', 'name': 'Carro', 'amount': 375},
    ],
  },
];

Map<String, dynamic> _goalMonth({bool closed = false}) => <String, dynamic>{
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
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': 600},
    {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': 400},
  ],
  'quotas': _quotas(),
};

Map<String, dynamic> _closePreview() => <String, dynamic>{
  'month': _month,
  'availableAmount': 1000,
  'plannedTotal': 1000,
  'reservedTotal': 1000,
  'unallocated': 0,
  'adjustedFromTemplate': false,
  'affectedFutureMonths': <Object>[],
  'defaulted': <Object>[],
  'quotas': _quotas(),
};

List<Object> _goals() => <Object>[
  {'id': 'g1', 'name': 'Viagem', 'active': true, 'iconKey': 'plane'},
  {'id': 'g2', 'name': 'Carro', 'active': true, 'iconKey': 'car'},
];

MockClient _client({
  bool expenseMonthExists = true,
  bool goalMonthExists = true,
}) => MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/months/$_month') {
    return expenseMonthExists
        ? jsonResponse(_expenseMonth())
        : jsonResponse(const {'error': 'Não existe.'}, status: 404);
  }
  if (path == '/api/months/$_month/settlement-preview') {
    return jsonResponse(_settlement());
  }
  if (path == '/api/months/$_month/close') {
    return jsonResponse(_expenseMonth(closed: true, withSettlement: true));
  }
  if (path == '/api/goal-plan/$_month/close-preview') {
    return jsonResponse(_closePreview());
  }
  if (path == '/api/goal-plan/$_month') {
    return goalMonthExists
        ? jsonResponse(_goalMonth())
        : jsonResponse(const {'error': 'Não existe.'}, status: 404);
  }
  if (path == '/api/goals') {
    return jsonResponse(_goals());
  }
  if (path == '/api/goal-plan/$_month/close') {
    return jsonResponse(_goalMonth(closed: true));
  }
  return jsonResponse(const {'error': 'not found'}, status: 404);
});

void main() {
  test('loads both months and their reviews', () async {
    final viewModel = _viewModel(_client());
    await viewModel.load();

    expect(viewModel.expenses.plan, isNotNull);
    expect(viewModel.goals.plan, isNotNull);
    expect(viewModel.expensesClosed, isFalse);
    expect(viewModel.goalsClosed, isFalse);
    expect(viewModel.expenseSettlement?.status, SettlementStatus.ok);
    expect(viewModel.goalTransfers, hasLength(2));
  });

  test('closes expenses and exposes the recorded settlement', () async {
    final viewModel = _viewModel(_client());
    await viewModel.load();

    final ok = await viewModel.closeExpenses();

    expect(ok, isTrue);
    expect(viewModel.expensesClosed, isTrue);
    expect(viewModel.expenseSettlement?.status, SettlementStatus.ok);
    expect(viewModel.expenseSettlement?.people, hasLength(2));
  });

  test('closes goals and exposes the recorded quotas', () async {
    final viewModel = _viewModel(_client());
    await viewModel.load();

    final ok = await viewModel.closeGoals();

    expect(ok, isTrue);
    expect(viewModel.goalsClosed, isTrue);
    expect(viewModel.goalTransfers, hasLength(2));
  });

  test('handles missing months without failing', () async {
    final viewModel = _viewModel(
      _client(expenseMonthExists: false, goalMonthExists: false),
    );
    await viewModel.load();

    expect(viewModel.expenses.plan, isNull);
    expect(viewModel.goals.plan, isNull);
    expect(viewModel.expenseSettlement, isNull);
    expect(viewModel.goalTransfers, isEmpty);
  });
}
