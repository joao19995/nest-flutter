import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/dashboard/views/dashboard_view.dart';

import '../../../support/test_helpers.dart';

Map<String, dynamic> _yearSummary(int year, String month) => {
  'year': year,
  'planned': 1000,
  'actual': 500,
  'diff': -500,
  'diffPct': -50,
  'over': false,
  'hasData': true,
  'remainingMonths': 2,
  'perRemainingMonth': 0,
  'months': [
    {
      'month': month,
      'status': 'open',
      'planned': 1000,
      'actual': 500,
      'progressPct': 50,
      'over': false,
      'filledEntries': 5,
      'totalEntries': 10,
    },
  ],
};

Map<String, dynamic> _goalYear(int year) => {
  'plans': <Object>[],
  'funding': {'year': year, 'annualTotal': 0, 'months': <Object>[]},
};

Map<String, dynamic> _month(String month) => {
  'id': 'm1',
  'month': month,
  'templateId': 't1',
  'closed': false,
  'entries': <Object>[],
  'settlement': null,
  'summary': {
    'month': month,
    'status': 'open',
    'planned': 1000,
    'actual': 500,
    'progressPct': 50,
    'over': false,
    'filledEntries': 5,
    'totalEntries': 10,
  },
};

MockClient _client(
  String month, {
  bool failEvents = false,
  List<Object>? events,
}) {
  final year = int.parse(month.substring(0, 4));
  return MockClient((request) async {
    if (request.url.path == '/api/months/$month') {
      return jsonResponse(_month(month));
    }
    if (failEvents && request.url.path == '/api/events') {
      return jsonResponse(const {
        'error': 'Eventos indisponíveis',
      }, status: 500);
    }
    switch (request.url.path) {
      case '/api/months/summary':
        return jsonResponse(_yearSummary(year, month));
      case '/api/events':
        return jsonResponse(events ?? const <Object>[]);
      case '/api/goal-plan':
        return jsonResponse(_goalYear(year));
      case '/api/goals':
        return jsonResponse(const <Object>[]);
      case '/api/goal-templates/applicable':
        return jsonResponse(const {'template': null});
      default:
        return jsonResponse(const {'error': 'not found'}, status: 404);
    }
  });
}

void main() {
  final month = MonthKey.current();
  final previous = MonthKey.shift(month, -1);

  testWidgets('opens with the month hero and its plan state', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(month)),
        const DashboardView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Balanço do mês'), findsOneWidget);
    expect(
      find.text('${AppFormatters.monthName(month)} por fechar'),
      findsOneWidget,
    );
    expect(find.text('Despesas'), findsOneWidget);
    expect(find.text('Objetivos'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'dashboard-month-$month');
    expect(find.textContaining(AppFormatters.currency(500)), findsOneWidget);
    expect(find.text(AppFormatters.percentage(50)), findsOneWidget);
    expect(find.text('-50%'), findsOneWidget);
    expect(find.text('Sem plano'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('steps the hero to a month without a plan', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(month)),
        const DashboardView(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();

    expect(find.text(AppFormatters.monthShort(previous)), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the close wizard from the action chip', (tester) async {
    setPhoneSize(tester);
    String? opened;
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(month)),
        DashboardView(onOpenMonth: (value) => opened = value),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(opened, isNull);
    expect(
      find.text('Fechar ${AppFormatters.monthName(month)}'),
      findsOneWidget,
    );
    expect(find.text('Despesas'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the month when the hero is tapped', (tester) async {
    setPhoneSize(tester);
    String? opened;
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(month)),
        DashboardView(onOpenMonth: (value) => opened = value),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Balanço do mês'));
    expect(opened, month);
  });

  testWidgets('keeps the hero when the events section fails', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(month, failEvents: true)),
        const DashboardView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Balanço do mês'), findsOneWidget);
    expect(find.textContaining(AppFormatters.currency(500)), findsOneWidget);
    expect(find.text('Eventos indisponíveis'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('groups the upcoming events by day', (tester) async {
    setPhoneSize(tester);
    final today = DateTime.now();
    final midday = DateTime(today.year, today.month, today.day, 12);
    final tomorrow = midday.add(const Duration(days: 1));
    final events = [
      {
        'id': 'e1',
        'title': 'Almoço',
        'startsAt': midday.toUtc().toIso8601String(),
        'active': true,
      },
      {
        'id': 'e2',
        'title': 'Jantar',
        'startsAt': tomorrow.toUtc().toIso8601String(),
        'active': true,
      },
    ];
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(month, events: events)),
        const DashboardView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Amanhã'), findsOneWidget);
    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('Jantar'), findsOneWidget);
  });

  testWidgets('survives a larger system text scale', (tester) async {
    setPhoneSize(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(month)),
        const DashboardView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
