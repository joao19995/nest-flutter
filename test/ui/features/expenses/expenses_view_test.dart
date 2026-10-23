import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_month_tile.dart';
import 'package:nest/ui/features/expenses/views/expenses_view.dart';

import '../../../support/test_helpers.dart';

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

void main() {
  testWidgets('renders the year hero and the month grid', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/summary') {
        return jsonResponse(_yearSummary());
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const ExpensesView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Despesa do ano'), findsOneWidget);
    expect(find.text('Por mês'), findsOneWidget);
    expect(find.byType(AppMonthTile), findsNWidgets(2));
    // 'Jan' appears both in the chart and in its month tile.
    expect(find.text('Jan'), findsNWidgets(2));
    expect(find.text('Fev'), findsNWidgets(2));
    expect(find.text('Por categoria'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the category donut and the top five rows', (
    tester,
  ) async {
    setPhoneSize(tester);
    final summary = _yearSummary()
      ..['byCategory'] = [
        {'name': 'Casa', 'actual': 1200},
        {'name': 'Gastos', 'actual': 800},
        {'name': 'Luz', 'actual': 300},
        {'name': 'Água', 'actual': 200},
        {'name': 'Pilates', 'actual': 100},
        {'name': 'Extra', 'actual': 50},
      ];
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/summary') {
        return jsonResponse(summary);
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const ExpensesView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Por categoria'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    // Also the January month tile.
    expect(find.text(AppFormatters.currency(1200)), findsNWidgets(2));
    expect(find.text('Extra'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the month detail through the hero transition', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/summary') {
        return jsonResponse(_yearSummary());
      }
      if (request.url.path == '/api/months/2026-01') {
        return jsonResponse(_closedMonth());
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const ExpensesView()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppMonthTile, 'Jan'));
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
