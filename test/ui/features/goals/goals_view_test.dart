import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/goals/views/goals_view.dart';

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

Map<String, dynamic> _goalYear() => <String, dynamic>{
  'plans': [
    {
      'id': 'p1',
      'month': '2026-01',
      'availableAmount': 1725,
      'closed': true,
      'allocations': [
        {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 800, 'actual': 800},
        {'goalId': 'g2', 'goalName': 'Carro', 'planned': 925, 'actual': 925},
      ],
    },
  ],
  'funding': {
    'year': 2026,
    'annualTotal': 4140,
    'months': [
      {'month': '2026-01', 'available': 2040},
      {'month': '2026-02', 'available': 2100},
    ],
  },
};

List<Object> _goals() => <Object>[
  {'id': 'g1', 'name': 'Viagem', 'active': true},
  {'id': 'g2', 'name': 'Carro', 'active': true},
];

List<Object> _templates() => <Object>[
  {
    'id': 't1',
    'validFrom': '2026-01',
    'annualTotal': 4140,
    'entries': [
      {'goalId': 'g1', 'percentage': 19.3, 'budget': 800},
      {'goalId': 'g2', 'percentage': 80.7, 'budget': 5000},
    ],
  },
];

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders the year hero and both lists', (tester) async {
    _setPhone(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/goal-plan') {
        return _json(_goalYear());
      }
      if (request.url.path == '/api/goals') {
        return _json(_goals());
      }
      if (request.url.path == '/api/goal-templates') {
        return _json(_templates());
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const GoalsView()));
    await tester.pumpAndSettle();

    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Objetivos do ano'), findsOneWidget);
    expect(find.text('Por mês'), findsOneWidget);
    expect(find.text('Por objetivo'), findsOneWidget);
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Viagem'), findsOneWidget);
    expect(find.text('Carro'), findsOneWidget);
    expect(find.textContaining('Completo'), findsOneWidget);
    expect(find.textContaining('Falta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when the year has no plans', (
    tester,
  ) async {
    _setPhone(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/goal-plan') {
        return _json(<String, dynamic>{'plans': <Object>[], 'funding': null});
      }
      return _json(<Object>[]);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const GoalsView()));
    await tester.pumpAndSettle();

    expect(
      find.text('Ainda não há objetivos poupados neste ano.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
