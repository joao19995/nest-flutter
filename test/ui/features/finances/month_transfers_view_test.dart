import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/finances/views/month_transfers_view.dart';

import '../../../support/test_helpers.dart';

const _month = '2026-01';

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

Map<String, dynamic> _goalMonth() => <String, dynamic>{
  'month': _month,
  'planId': 'p1',
  'closed': true,
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

MockClient _client({bool goalsExist = true}) => MockClient((request) async {
  if (request.url.path == '/api/months/$_month') {
    return jsonResponse(_expenseMonth());
  }
  if (request.url.path == '/api/goal-plan/$_month') {
    return goalsExist
        ? jsonResponse(_goalMonth())
        : jsonResponse(const {'error': 'Não existe.'}, status: 404);
  }
  if (request.url.path == '/api/goals') {
    return jsonResponse(_goals());
  }
  return jsonResponse(const {'error': 'not found'}, status: 404);
});

void main() {
  testWidgets('shows the definitive transfers of a closed month', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client()),
        const MonthTransfersView(month: _month),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transferências de Janeiro'), findsOneWidget);
    expect(find.text('Resumo final'), findsOneWidget);
    expect(find.text('Resumo por pessoa'), findsOneWidget);
    expect(find.text('A receber da conjunta'), findsOneWidget);
    expect(find.text('Para objetivos'), findsOneWidget);
    expect(find.text(AppFormatters.currency(320)), findsWidgets);
    expect(find.text(AppFormatters.currency(1000)), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('asks to close the month when one side is still open', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(goalsExist: false)),
        const MonthTransfersView(month: _month),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ainda não há transferências finais'), findsOneWidget);
    expect(find.text('Despesas'), findsOneWidget);
    expect(find.text('Objetivos'), findsOneWidget);
    expect(find.text('Por criar'), findsOneWidget);
    expect(find.text('Abrir assistente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
