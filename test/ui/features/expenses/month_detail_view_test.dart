import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';

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
    {
      'id': 'e2',
      'categoryName': 'Luz',
      'accountName': 'Conjunta',
      'planned': 60,
      'actual': 57.78,
    },
  ],
  'settlement': {
    'status': 'ok',
    'contributionRequired': 510,
    'jointSurplus': 0,
    'people': [
      {
        'personName': 'João',
        'income': 2500,
        'quota': 255,
        'personalActual': 471.94,
        'transferToJoint': 0,
        'transferToPerson': 216.94,
      },
      {
        'personName': 'Nathalia',
        'income': 2000,
        'quota': 255,
        'personalActual': 0,
        'transferToJoint': 255,
        'transferToPerson': 0,
      },
    ],
  },
};

Map<String, dynamic> _openMonth({double actual = 0}) => <String, dynamic>{
  'id': 'm2',
  'month': '2026-02',
  'templateId': 't1',
  'closed': false,
  'entries': [
    {
      'id': 'e1',
      'categoryName': 'Casa',
      'accountName': 'João',
      'planned': 450,
      'actual': actual,
    },
  ],
  'settlement': null,
};

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders a closed month with entries and contributions', (
    tester,
  ) async {
    _setPhone(tester);
    final client = MockClient((request) async => _json(_closedMonth()));

    await tester.pumpWidget(
      _wrap(_dependencies(client), const MonthDetailView(month: '2026-01')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('Fechado'), findsOneWidget);
    expect(find.text('Despesas'), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Contribuições'), findsOneWidget);
    expect(find.text('para a conta conjunta'), findsOneWidget);
    expect(find.text('da conta conjunta'), findsOneWidget);
    expect(find.text('Fechar mês'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an open month with editable fields and a close button', (
    tester,
  ) async {
    _setPhone(tester);
    final client = MockClient((request) async => _json(_openMonth()));

    await tester.pumpWidget(
      _wrap(_dependencies(client), const MonthDetailView(month: '2026-02')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aberto'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Fechar mês'), findsOneWidget);
    expect(find.text('Contribuições'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates the month from the missing state', (tester) async {
    _setPhone(tester);
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _json({'error': 'Não existe.'}, status: 404);
      }
      if (request.method == 'POST' && request.url.path == '/api/months') {
        return _json(_openMonth(), status: 201);
      }
      return _json({'error': 'Unexpected.'}, status: 400);
    });

    await tester.pumpWidget(
      _wrap(_dependencies(client), const MonthDetailView(month: '2026-10')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mês não criado'), findsOneWidget);

    await tester.tap(find.text('Criar mês'));
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Fechar mês'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saves an edited amount on focus loss', (tester) async {
    _setPhone(tester);
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'PATCH') {
        return _json(_openMonth(actual: 500));
      }
      return _json(_openMonth());
    });

    await tester.pumpWidget(
      _wrap(_dependencies(client), const MonthDetailView(month: '2026-02')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '500');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(
      requests.any((request) => request.method == 'PATCH'),
      isTrue,
      reason: 'editing an amount should PATCH the entry',
    );
    expect(tester.takeException(), isNull);
  });
}
