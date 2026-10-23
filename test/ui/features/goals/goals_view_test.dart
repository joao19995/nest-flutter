import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/widgets/app_month_tile.dart';
import 'package:nest/ui/features/goals/views/goals_view.dart';

import '../../../support/test_helpers.dart';

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

Map<String, dynamic> _applicableTemplate() => <String, dynamic>{
  'id': 't1',
  'validFrom': '2026-01',
  'annualTotal': 4140,
  'entries': [
    {'goalId': 'g1', 'percentage': 19.3, 'budget': 800},
    {'goalId': 'g2', 'percentage': 80.7, 'budget': 5000},
  ],
};

Map<String, dynamic> _monthView() => <String, dynamic>{
  'month': '2026-01',
  'planId': 'p1',
  'closed': true,
  'availableAmount': 1725,
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 800, 'actual': 800},
  ],
  'quotas': <Object>[],
};

void main() {
  testWidgets('renders the year hero and opens the per-goal accumulation', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/goal-plan') {
        return jsonResponse(_goalYear());
      }
      if (request.url.path == '/api/goals') {
        return jsonResponse(_goals());
      }
      if (request.url.path == '/api/goal-templates/applicable') {
        return jsonResponse({'template': _applicableTemplate()});
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const GoalsView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Objetivos do ano'), findsOneWidget);
    expect(find.text('Por mês'), findsOneWidget);
    expect(find.byType(AppMonthTile), findsNWidgets(12));
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('2 objetivos'), findsOneWidget);
    expect(find.text('Distribuição'), findsOneWidget);
    expect(find.text('Acumulado'), findsOneWidget);
    expect(find.text('Viagem'), findsNothing);

    await tester.ensureVisible(find.text('Acumulado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acumulado'));
    await tester.pumpAndSettle();

    expect(find.text('Viagem'), findsOneWidget);
    expect(find.text('Carro'), findsOneWidget);
    expect(find.textContaining('Completo'), findsOneWidget);
    expect(find.textContaining('Falta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the goal month through the hero transition', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/goal-plan') {
        return jsonResponse(_goalYear());
      }
      if (request.url.path == '/api/goals') {
        return jsonResponse(_goals());
      }
      if (request.url.path == '/api/goal-templates/applicable') {
        return jsonResponse({'template': _applicableTemplate()});
      }
      if (request.url.path == '/api/goal-plan/2026-01') {
        return jsonResponse(_monthView());
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const GoalsView()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppMonthTile, 'Jan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Janeiro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when the year has no plans', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/goal-plan') {
        return jsonResponse(<String, dynamic>{
          'plans': <Object>[],
          'funding': null,
        });
      }
      if (request.url.path == '/api/goal-templates/applicable') {
        return jsonResponse(const <String, Object?>{'template': null});
      }
      return jsonResponse(<Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const GoalsView()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Ainda não há objetivos poupados neste ano.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
