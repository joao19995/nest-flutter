import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';
import 'package:nest/ui/features/finances/views/close_month_wizard_view.dart';
import 'package:nest/ui/features/goals/views/goal_month_detail_view.dart';

import '../../../support/test_helpers.dart';

const _month = '2026-01';

Map<String, dynamic> _settlement() => <String, dynamic>{
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
    {
      'personId': 'p2',
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

MockClient _client() => MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/months/$_month') {
    return jsonResponse(_expenseMonth());
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
    return jsonResponse(_goalMonth());
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
  testWidgets('walks through both closes and shows the final transfers', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client()),
        const CloseMonthWizardView(month: _month),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fechar Janeiro'), findsOneWidget);
    expect(find.text('Transferências previstas'), findsOneWidget);
    expect(find.text('Fechar despesas'), findsOneWidget);

    await tester.tap(find.text('Fechar despesas'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Fechar despesas'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fechar objetivos'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Reservado'), findsOneWidget);

    await tester.tap(find.text('Fechar objetivos'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Guardar e fechar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transferências finais'), findsOneWidget);
    expect(find.text('Resumo final'), findsOneWidget);
    expect(find.text('Resumo por pessoa'), findsOneWidget);
    expect(find.text('Para a conta conjunta'), findsOneWidget);
    expect(find.text('Da conta conjunta'), findsOneWidget);
    expect(find.text('Para os objetivos'), findsOneWidget);
    expect(find.text('Para a conjunta'), findsOneWidget);
    expect(find.text('A receber da conjunta'), findsOneWidget);
    expect(find.text(AppFormatters.currency(300)), findsWidgets);
    expect(find.text(AppFormatters.currency(320)), findsWidgets);
    expect(find.text(AppFormatters.currency(1000)), findsWidgets);
    expect(find.text('Concluir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the expenses detail to enter the real amounts', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client()),
        const CloseMonthWizardView(month: _month),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar despesas'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthDetailView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the goals detail to set the reserved amounts', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/months/$_month') {
        return jsonResponse(_expenseMonth(closed: true, withSettlement: true));
      }
      if (path == '/api/goal-plan/$_month/close-preview') {
        return jsonResponse(_closePreview());
      }
      if (path == '/api/goal-plan/$_month') {
        return jsonResponse(_goalMonth());
      }
      if (path == '/api/goals') {
        return jsonResponse(_goals());
      }
      return jsonResponse(const {'error': 'not found'}, status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const CloseMonthWizardView(month: _month, startStep: 1),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar objetivos'));
    await tester.pumpAndSettle();

    expect(find.byType(GoalMonthDetailView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens directly on goals when expenses are already closed', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/months/$_month') {
        return jsonResponse(_expenseMonth(closed: true, withSettlement: true));
      }
      if (path == '/api/goal-plan/$_month/close-preview') {
        return jsonResponse(_closePreview());
      }
      if (path == '/api/goal-plan/$_month') {
        return jsonResponse(_goalMonth());
      }
      if (path == '/api/goals') {
        return jsonResponse(_goals());
      }
      return jsonResponse(const {'error': 'not found'}, status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const CloseMonthWizardView(month: _month, startStep: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fechar objetivos'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Fechar despesas'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
