import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/views/goal_month_detail_view.dart';

import '../../../support/test_helpers.dart';

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

/// A saved plan (the shape returned by POST create).
Map<String, dynamic> _plan({
  bool closed = true,
  double actual1 = 600,
  double actual2 = 400,
}) => <String, dynamic>{
  'id': 'p1',
  'month': '2026-01',
  'availableAmount': 1000,
  'closed': closed,
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': actual1},
    {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': actual2},
  ],
};

/// The self-sufficient month view returned by `GET /api/goal-plan/{month}`
/// and by the PATCH / close writes.
Map<String, dynamic> _monthView({
  bool closed = true,
  double actual1 = 600,
  double actual2 = 400,
}) => <String, dynamic>{
  'month': '2026-01',
  'planId': 'p1',
  'closed': closed,
  'availableAmount': 1000,
  'funding': {
    'month': '2026-01',
    'incomeNormal': 2500,
    'bonus': 0,
    'dailyAllowance': 500,
    'contributionRequired': 1000,
    'available': 1000,
  },
  'totals': {'planned': 1000, 'actual': actual1 + actual2, 'reserved': 1000},
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': actual1},
    {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': actual2},
  ],
  'quotas': _quotas(),
};

Map<String, dynamic> _closePreview() => <String, dynamic>{
  'month': '2026-01',
  'availableAmount': 1000,
  'plannedTotal': 1000,
  'reservedTotal': 1000,
  'unallocated': 0,
  'adjustedFromTemplate': false,
  'affectedFutureMonths': <Object>[],
  'defaulted': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'amount': 600},
    {'goalId': 'g2', 'goalName': 'Carro', 'amount': 400},
  ],
  'quotas': _quotas(),
};

Map<String, dynamic> _missingMonth() => <String, dynamic>{
  'month': '2026-01',
  'planId': null,
  'closed': false,
  'availableAmount': 0,
  'allocations': <Object>[],
  'quotas': <Object>[],
};

List<Object> _goals() => <Object>[
  {'id': 'g1', 'name': 'Viagem', 'active': true, 'iconKey': 'plane'},
  {'id': 'g2', 'name': 'Carro', 'active': true, 'iconKey': 'car'},
];

MockClient _client({bool created = false}) {
  var hasMonth = created;
  return MockClient((request) async {
    if (request.url.path == '/api/goals') {
      return jsonResponse(_goals());
    }
    if (request.url.path == '/api/goal-plan' && request.method == 'POST') {
      hasMonth = true;
      return jsonResponse(_plan(), status: 201);
    }
    if (request.url.path.endsWith('/close-preview')) {
      return jsonResponse(_closePreview());
    }
    if (request.method == 'GET' &&
        request.url.path.startsWith('/api/goal-plan/')) {
      return hasMonth
          ? jsonResponse(_monthView())
          : jsonResponse(_missingMonth());
    }
    return jsonResponse(<Object>[], status: 404);
  });
}

void main() {
  testWidgets('renders the month hero, goals and transfers', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(created: true)),
        const GoalMonthDetailView(month: '2026-01'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('Fechado'), findsOneWidget);
    expect(find.text('Objetivos'), findsOneWidget);
    expect(find.text('Transferências'), findsOneWidget);
    // The goals card plus one transfer line per allocation target.
    expect(find.text('Viagem'), findsNWidgets(2));
    expect(find.text('Carro'), findsNWidgets(3));
    expect(find.text('João'), findsNWidgets(2));
    expect(find.text('Nathalia'), findsOneWidget);
    expect(find.byType(AppTransferFlow), findsNWidgets(3));
    expect(find.text('Disponível para objetivos'), findsOneWidget);
    expect(find.text('Como é calculado'), findsOneWidget);
    expect(find.text('Rendimento normal'), findsOneWidget);
    expect(find.text('Projeção atual'), findsOneWidget);
    expect(find.text('Fechar mês'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a missing month', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client()),
        const GoalMonthDetailView(month: '2026-01'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mês não criado'), findsOneWidget);

    await tester.tap(find.text('Criar mês'));
    await tester.pumpAndSettle();

    expect(find.text('Objetivos'), findsOneWidget);
    expect(find.text('Transferências'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits the reserved value', (tester) async {
    setPhoneSize(tester);
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/api/goals') {
        return jsonResponse(_goals());
      }
      if (request.method == 'GET') {
        return jsonResponse(_monthView(closed: false, actual1: 0, actual2: 0));
      }
      if (request.method == 'PATCH') {
        return jsonResponse(
          _monthView(closed: false, actual1: 500, actual2: 0),
        );
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const GoalMonthDetailView(month: '2026-01'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aberto'), findsOneWidget);
    expect(find.text('Fechar mês'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, '500');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(requests.any((request) => request.method == 'PATCH'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the close wizard from the month detail', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/goals') {
        return jsonResponse(_goals());
      }
      if (request.url.path.startsWith('/api/months/')) {
        return jsonResponse(const {'error': 'Não existe.'}, status: 404);
      }
      return jsonResponse(_monthView(closed: false));
    });

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const GoalMonthDetailView(month: '2026-01'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fechar mês'));
    await tester.pumpAndSettle();

    expect(find.text('Fechar Janeiro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
