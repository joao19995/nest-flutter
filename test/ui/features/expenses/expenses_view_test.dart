import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/expenses/views/expenses_view.dart';

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

Map<String, dynamic> _yearSummary() => <String, dynamic>{
  'year': 2026,
  'planned': 12000,
  'actual': 13200,
  'diff': 1200,
  'diffPct': 10,
  'over': true,
  'hasData': true,
  'remainingMonths': 3,
  'perRemainingMonth': 400,
  'months': [
    {
      'month': '2026-01',
      'status': 'closed',
      'planned': 1000,
      'actual': 1200,
      'progressPct': 120,
      'over': true,
    },
    {
      'month': '2026-02',
      'status': 'open',
      'planned': 1000,
      'actual': 800,
      'progressPct': 80,
      'over': false,
    },
  ],
};

Map<String, dynamic> _closedMonth() => <String, dynamic>{
  'id': 'm1',
  'month': '2026-01',
  'templateId': 't1',
  'closed': true,
  'entries': [
    {
      'id': 'e1',
      'categoryName': 'Casa',
      'accountName': 'João',
      'planned': 450,
      'actual': 471.94,
    },
  ],
  'summary': {
    'month': '2026-01',
    'status': 'closed',
    'planned': 450,
    'actual': 471.94,
    'progressPct': 104.88,
    'over': true,
  },
  'settlement': null,
};

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders the year hero and the month list', (tester) async {
    _setPhone(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/summary') {
        return _json(_yearSummary());
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const ExpensesView()));
    await tester.pumpAndSettle();

    expect(find.text('Despesa do ano'), findsOneWidget);
    expect(find.text('Por mês'), findsOneWidget);
    // 'Jan' appears both in the chart and in the month list.
    expect(find.text('Jan'), findsNWidgets(2));
    expect(find.text('Fev'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the month detail through the hero transition', (
    tester,
  ) async {
    _setPhone(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/summary') {
        return _json(_yearSummary());
      }
      if (request.url.path == '/api/months/2026-01') {
        return _json(_closedMonth());
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const ExpensesView()));
    await tester.pumpAndSettle();

    // The last 'Jan' is the month list row (the first is the chart label).
    await tester.tap(find.text('Jan').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Flying back to the list must not throw either.
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Despesa do ano'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
