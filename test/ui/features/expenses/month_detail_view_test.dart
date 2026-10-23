import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';

import '../../../support/test_helpers.dart';

Map<String, dynamic> _closedMonth() => <String, dynamic>{
  'id': 'm1',
  'month': '2026-01',
  'templateId': 't1',
  'closed': true,
  'entries': [
    {
      'id': 'e1',
      'categoryName': 'Casa',
      'categoryType': 'FIXED',
      'accountName': 'Joao',
      'planned': 450,
      'actual': 471.94,
    },
    {
      'id': 'e2',
      'categoryName': 'Luz',
      'categoryType': 'VARIABLE',
      'accountName': 'Conjunta',
      'planned': 60,
      'actual': 57.78,
    },
  ],
  'summary': {
    'month': '2026-01',
    'status': 'closed',
    'planned': 510,
    'actual': 529.72,
    'progressPct': 103.87,
    'over': true,
  },
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
      'categoryType': 'FIXED',
      'accountName': 'Joao',
      'planned': 450,
      'actual': actual,
    },
  ],
  'summary': {
    'month': '2026-02',
    'status': 'open',
    'planned': 450,
    'actual': actual,
    'progressPct': actual / 450 * 100,
    'over': actual > 450.005,
  },
  'settlement': null,
};

String? _groupTotal(WidgetTester tester, String group) =>
    tester.widget<Text>(find.byKey(ValueKey('entry-group-total-$group'))).data;

void main() {
  testWidgets('renders a closed month with entries and contributions', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async => jsonResponse(_closedMonth()));

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const MonthDetailView(month: '2026-01'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('Fechado'), findsOneWidget);
    expect(find.text('Despesas'), findsOneWidget);
    expect(find.text('Fixas'), findsOneWidget);
    expect(find.text('Variáveis'), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(_groupTotal(tester, 'Fixas'), AppFormatters.currency(471.94));
    expect(_groupTotal(tester, 'Variáveis'), AppFormatters.currency(57.78));
    expect(find.text('Contribuições'), findsOneWidget);
    expect(find.byType(AppTransferFlow), findsNWidgets(2));
    expect(find.text('Conjunta'), findsNWidgets(2));
    expect(find.text('Fechar mês'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an open month with editable fields and a close button', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async => jsonResponse(_openMonth()));

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const MonthDetailView(month: '2026-02'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aberto'), findsOneWidget);
    expect(find.text('Fixas'), findsOneWidget);
    expect(find.text('Variáveis'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Fechar mês'), findsOneWidget);
    expect(find.text('Contribuições'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates the month from the missing state', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return jsonResponse({'error': 'Não existe.'}, status: 404);
      }
      if (request.method == 'POST' && request.url.path == '/api/months') {
        return jsonResponse(_openMonth(), status: 201);
      }
      return jsonResponse({'error': 'Unexpected.'}, status: 400);
    });

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const MonthDetailView(month: '2026-10'),
      ),
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
    setPhoneSize(tester);
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'PATCH') {
        return jsonResponse(_openMonth(actual: 500));
      }
      return jsonResponse(_openMonth());
    });

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const MonthDetailView(month: '2026-02'),
      ),
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
