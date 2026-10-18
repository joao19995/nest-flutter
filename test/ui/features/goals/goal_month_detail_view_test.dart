import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/goals/views/goal_month_detail_view.dart';

AppDependencies _dependencies(MockClient client) => AppDependencies(
  apiClient: NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

Widget _wrap(AppDependencies dependencies, Widget child) => DependenciesScope(
  dependencies: dependencies,
  child: MaterialApp(theme: AppTheme.light, home: child),
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

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

/// A saved plan (the shape returned by POST create and PATCH / close).
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

Map<String, dynamic> _openPlan() =>
    _plan(closed: false, actual1: 0, actual2: 0);

/// The self-sufficient month view returned by `GET /api/goal-plan/{month}`.
Map<String, dynamic> _monthView({
  bool closed = true,
  double actual1 = 600,
  double actual2 = 400,
}) => <String, dynamic>{
  'month': '2026-01',
  'planId': 'p1',
  'closed': closed,
  'availableAmount': 1000,
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': actual1},
    {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': actual2},
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

MockClient _client({bool created = false}) {
  var hasMonth = created;
  return MockClient((request) async {
    if (request.url.path == '/api/goal-plan' && request.method == 'POST') {
      hasMonth = true;
      return _json(_plan(), status: 201);
    }
    if (request.url.path.startsWith('/api/goal-plan/') &&
        !request.url.path.endsWith('/quotas')) {
      return hasMonth ? _json(_monthView()) : _json(_missingMonth());
    }
    return _json(<Object>[], status: 404);
  });
}

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders the month hero, goals and transfers', (tester) async {
    _setPhone(tester);
    await tester.pumpWidget(
      _wrap(
        _dependencies(_client(created: true)),
        const GoalMonthDetailView(month: '2026-01'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('Fechado'), findsOneWidget);
    expect(find.text('Objetivos'), findsOneWidget);
    expect(find.text('Transferências'), findsOneWidget);
    expect(find.text('Viagem'), findsOneWidget);
    expect(find.text('Carro'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Nathalia'), findsOneWidget);
    expect(find.textContaining('Transfere'), findsNWidgets(2));
    expect(find.text('Fechar mês'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a missing month', (tester) async {
    _setPhone(tester);
    await tester.pumpWidget(
      _wrap(
        _dependencies(_client()),
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

  testWidgets('edits the reserved value and closes the month', (tester) async {
    _setPhone(tester);
    final requests = <http.Request>[];
    var closed = false;
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET') {
        return _json(_monthView(closed: closed, actual1: 0, actual2: 0));
      }
      if (request.method == 'PATCH') {
        return _json(_openPlan());
      }
      if (request.url.path == '/api/goal-plan/quotas') {
        return _json({'quotas': _quotas()});
      }
      if (request.method == 'POST' && request.url.path.endsWith('/close')) {
        closed = true;
        return _json(_plan());
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      _wrap(_dependencies(client), const GoalMonthDetailView(month: '2026-01')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aberto'), findsOneWidget);
    expect(find.text('Fechar mês'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, '500');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(requests.any((request) => request.method == 'PATCH'), isTrue);
    expect(
      requests.any((request) => request.url.path == '/api/goal-plan/quotas'),
      isTrue,
    );

    await tester.tap(find.text('Fechar mês'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar e fechar'));
    await tester.pumpAndSettle();

    expect(find.text('Fechado'), findsOneWidget);
    expect(
      requests.any((request) => request.url.path.endsWith('/close')),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
