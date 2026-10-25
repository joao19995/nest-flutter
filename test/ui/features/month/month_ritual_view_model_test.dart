import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/features/month/view_models/month_ritual_view_model.dart';

import '../../../support/test_helpers.dart';

const _october = '2026-10';
const _september = '2026-09';

MonthRitualViewModel _viewModel(MockClient client) {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  return MonthRitualViewModel(
    expensesRepository: ExpensesRepository(client: api),
    goalsRepository: GoalsRepository(client: api),
    now: DateTime(2026, 10, 15),
  );
}

Map<String, dynamic> _yearSummary(int year) => <String, dynamic>{
  'year': year,
  'planned': 0,
  'actual': 0,
  'diff': 0,
  'diffPct': 0,
  'over': false,
  'hasData': false,
  'remainingMonths': 12,
  'perRemainingMonth': 0,
  'months': [
    for (var number = 1; number <= 12; number++)
      {
        'month': '$year-${number.toString().padLeft(2, '0')}',
        'status': 'missing',
        'planned': 0,
        'actual': 0,
        'progressPct': 0,
        'over': false,
      },
  ],
};

Map<String, dynamic> _expenseMonth(
  String month, {
  bool closed = false,
  int filled = 0,
  int total = 0,
}) => <String, dynamic>{
  'id': 'm-$month',
  'month': month,
  'closed': closed,
  'entries': <Object>[],
  'summary': {
    'month': month,
    'status': closed ? 'closed' : 'open',
    'planned': 500,
    'actual': 400,
    'progressPct': 80,
    'over': false,
    'filledEntries': filled,
    'totalEntries': total,
  },
  'settlement': null,
};

Map<String, dynamic> _goalMonth(
  String month, {
  bool closed = false,
  double reserved = 0,
  double planned = 0,
}) => <String, dynamic>{
  'month': month,
  'planId': 'g-$month',
  'closed': closed,
  'availableAmount': planned,
  'totals': {'planned': planned, 'actual': reserved, 'reserved': reserved},
  'allocations': <Object>[],
  'quotas': <Object>[],
};

MockClient _yearClient() => MockClient((request) async {
  if (request.url.path == '/api/months/summary') {
    return jsonResponse(_yearSummary(2026));
  }
  return jsonResponse(const {'error': 'not found'}, status: 404);
});

void main() {
  test('a month with no plans starts the ritual from scratch', () async {
    final viewModel = _viewModel(_yearClient());

    await viewModel.load();

    expect(viewModel.month, _october);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.ritual.isMissing, isTrue);
    expect(viewModel.ritual.statusLabel, 'Por criar');
    expect(viewModel.ritual.currentStep?.label, 'Criar o mês');
    expect(viewModel.yearMonths, hasLength(12));
  });

  test('missing goals keep the ritual on the expense lines', () async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/months/$_october') {
        return jsonResponse(_expenseMonth(_october, filled: 2, total: 5));
      }
      if (path == '/api/months/summary') {
        return jsonResponse(_yearSummary(2026));
      }
      return jsonResponse(const {'error': 'not found'}, status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.ritual.goalsStatus, ExpenseMonthStatus.missing);
    expect(viewModel.ritual.currentStep?.label, 'Preencher despesas reais');
    expect(viewModel.ritual.currentStep?.detail, '2 de 5 preenchidas');
  });

  test('a failed month request records the error', () async {
    final client = MockClient(
      (request) async => jsonResponse(const {'error': 'Falhou.'}, status: 500),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.errorMessage, 'Falhou.');
    expect(viewModel.isLoading, isFalse);
  });

  test('steps back a month and reads its payload', () async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/months/$_october') {
        return jsonResponse(_expenseMonth(_october, filled: 2, total: 5));
      }
      if (path == '/api/goal-plan/$_october') {
        return jsonResponse(_goalMonth(_october));
      }
      if (path == '/api/months/$_september') {
        return jsonResponse(
          _expenseMonth(_september, closed: true, filled: 5, total: 5),
        );
      }
      if (path == '/api/goal-plan/$_september') {
        return jsonResponse(_goalMonth(_september, closed: true));
      }
      if (path == '/api/months/summary') {
        return jsonResponse(_yearSummary(2026));
      }
      return jsonResponse(const {'error': 'not found'}, status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.month, _october);
    expect(viewModel.ritual.statusLabel, 'Por fechar');

    await viewModel.showPreviousMonth();

    expect(viewModel.month, _september);
    expect(viewModel.ritual.month, _september);
    expect(viewModel.ritual.expensesClosed, isTrue);
    expect(viewModel.ritual.isClosed, isTrue);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test('discards a late month response after the user steps away', () async {
    final gate = Completer<void>();
    var octoberGoalRequested = false;
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/months/$_october') {
        await gate.future;
        return jsonResponse(_expenseMonth(_october, filled: 2, total: 5));
      }
      if (path == '/api/goal-plan/$_october') {
        octoberGoalRequested = true;
        return jsonResponse(_goalMonth(_october));
      }
      if (path == '/api/months/$_september') {
        return jsonResponse(
          _expenseMonth(_september, closed: true, filled: 5, total: 5),
        );
      }
      if (path == '/api/goal-plan/$_september') {
        return jsonResponse(_goalMonth(_september, closed: true));
      }
      if (path == '/api/months/summary') {
        return jsonResponse(_yearSummary(2026));
      }
      return jsonResponse(const {'error': 'not found'}, status: 404);
    });

    final viewModel = _viewModel(client);
    final first = viewModel.load();
    final second = viewModel.showPreviousMonth();
    await second;
    gate.complete();
    await first;

    expect(viewModel.month, _september);
    expect(viewModel.ritual.month, _september);
    expect(viewModel.ritual.isClosed, isTrue);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(octoberGoalRequested, isFalse);
  });
}
