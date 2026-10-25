import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/finances/views/close_month_wizard_view.dart';
import 'package:nest/ui/features/finances/views/month_transfers_view.dart';
import 'package:nest/ui/features/goals/views/goal_month_detail_view.dart';
import 'package:nest/ui/features/month/views/month_ritual_view.dart';

import '../../../support/test_helpers.dart';

const _stepLabels = [
  'Criar o mês',
  'Preencher despesas reais',
  'Fechar despesas',
  'Definir objetivos',
  'Fechar objetivos',
  'Ver transferências',
];

String get _month => MonthKey.current();

int get _year => DateTime.now().year;

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

Map<String, dynamic> _expenseMonth({
  bool closed = false,
  int filled = 0,
  int total = 0,
}) => <String, dynamic>{
  'id': 'm-$_month',
  'month': _month,
  'closed': closed,
  'entries': <Object>[],
  'summary': {
    'month': _month,
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

Map<String, dynamic> _goalMonth({bool closed = false}) => <String, dynamic>{
  'month': _month,
  'planId': 'g-$_month',
  'closed': closed,
  'availableAmount': 500,
  'totals': {'planned': 500, 'actual': 400, 'reserved': 400},
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 500, 'actual': 400},
  ],
  'quotas': <Object>[],
};

Map<String, dynamic> _settlement() => <String, dynamic>{
  'status': 'ok',
  'contributionRequired': 500,
  'jointSurplus': 0,
  'people': [
    {
      'personId': 'p1',
      'personName': 'João',
      'income': 2500,
      'quota': 250,
      'personalActual': 400,
      'transferToJoint': 0,
      'transferToPerson': 150,
    },
  ],
};

Map<String, dynamic> _closePreview() => <String, dynamic>{
  'month': _month,
  'availableAmount': 500,
  'plannedTotal': 500,
  'reservedTotal': 400,
  'unallocated': 0,
  'adjustedFromTemplate': false,
  'affectedFutureMonths': <Object>[],
  'defaulted': <Object>[],
  'quotas': <Object>[],
};

List<Object> _goals() => <Object>[
  {'id': 'g1', 'name': 'Viagem', 'active': true, 'iconKey': 'plane'},
];

MockClient _client({
  bool expenseMissing = false,
  bool expenseClosed = false,
  int filled = 0,
  int total = 0,
  bool goalMissing = false,
  bool goalClosed = false,
}) => MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/months/summary') {
    return jsonResponse(_yearSummary(_year));
  }
  if (path == '/api/months/$_month') {
    if (expenseMissing) {
      return jsonResponse(const {'error': 'not found'}, status: 404);
    }
    return jsonResponse(
      _expenseMonth(closed: expenseClosed, filled: filled, total: total),
    );
  }
  if (path == '/api/months/$_month/settlement-preview') {
    return jsonResponse(_settlement());
  }
  if (path == '/api/goal-plan/$_month/close-preview') {
    return jsonResponse(_closePreview());
  }
  if (path == '/api/goal-plan/$_month') {
    if (goalMissing) {
      return jsonResponse(const {'error': 'not found'}, status: 404);
    }
    return jsonResponse(_goalMonth(closed: goalClosed));
  }
  if (path == '/api/goals') {
    return jsonResponse(_goals());
  }
  return jsonResponse(const {'error': 'not found'}, status: 404);
});

Future<void> _pumpRitual(WidgetTester tester, MockClient client) async {
  setPhoneSize(tester);
  await tester.pumpWidget(
    wrapWithDependencies(
      testDependencies(client),
      const Scaffold(body: MonthRitualView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a month not created invites the user to start', (tester) async {
    await _pumpRitual(tester, _client(expenseMissing: true, goalMissing: true));

    expect(find.text('Por criar'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    for (final label in _stepLabels) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Fechar ${AppFormatters.monthName(_month)}'),
      findsOneWidget,
    );
    expect(find.text('Cria o mês de despesas para começar.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open month continues the expense step', (tester) async {
    await _pumpRitual(tester, _client(filled: 5, total: 10));

    expect(find.text('Por fechar'), findsOneWidget);
    expect(find.text('Preencher despesas reais'), findsOneWidget);
    expect(find.text('5 de 10 preenchidas'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Confirma o real e as transferências antes de fechar.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('closed expenses continue at the goals step', (tester) async {
    await _pumpRitual(
      tester,
      _client(expenseClosed: true, filled: 10, total: 10),
    );

    expect(find.text('Continuar'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Confirma o reservado e as transferências antes de fechar.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a closed month invites the transfers summary', (tester) async {
    await _pumpRitual(
      tester,
      _client(expenseClosed: true, filled: 10, total: 10, goalClosed: true),
    );

    expect(find.text('Fechado'), findsOneWidget);
    expect(find.text('Ver resumo'), findsOneWidget);

    await tester.tap(find.text('Ver resumo'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthTransfersView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the goals step opens the goals detail', (tester) async {
    await _pumpRitual(tester, _client(filled: 5, total: 10));

    await tester.ensureVisible(find.text('Definir objetivos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Definir objetivos'));
    await tester.pumpAndSettle();

    expect(find.byType(GoalMonthDetailView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the close expenses step opens the wizard', (tester) async {
    await _pumpRitual(tester, _client(filled: 5, total: 5));

    await tester.ensureVisible(find.text('Fechar despesas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fechar despesas'));
    await tester.pumpAndSettle();

    expect(find.byType(CloseMonthWizardView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
