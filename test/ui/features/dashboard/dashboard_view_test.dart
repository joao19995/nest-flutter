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
  },
};

MockClient _client(String month) {
  final year = int.parse(month.substring(0, 4));
  return MockClient((request) async {
    if (request.url.path == '/api/months/$month') {
      return jsonResponse(_month(month));
    }
    switch (request.url.path) {
      case '/api/months/summary':
        return jsonResponse(_yearSummary(year, month));
      case '/api/events':
        return jsonResponse(const <Object>[]);
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

    expect(find.text('Despesa do mês'), findsOneWidget);
    expect(find.text(AppFormatters.currency(500)), findsOneWidget);
    expect(find.text(AppFormatters.percentage(50)), findsOneWidget);
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
    expect(find.text('Sem plano'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the alert month from the action chip', (tester) async {
    setPhoneSize(tester);
    String? opened;
    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(_client(month)),
        DashboardView(onOpenMonth: (value) => opened = value),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fechar'));
    expect(opened, month);
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

    await tester.tap(find.text('Despesa do mês'));
    expect(opened, month);
  });
}
