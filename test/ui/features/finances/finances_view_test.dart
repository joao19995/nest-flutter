import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/app_formatters.dart';
import 'package:nest/ui/features/finances/views/finances_view.dart';

import '../../../support/test_helpers.dart';

Map<String, dynamic> _yearSummary(int year) => {
  'year': year,
  'planned': 0,
  'actual': 0,
  'diff': 0,
  'diffPct': 0,
  'over': false,
  'hasData': false,
  'remainingMonths': 12,
  'perRemainingMonth': 0,
  'months': <Object>[],
};

void main() {
  testWidgets('loads goals only when its tab is selected', (tester) async {
    setPhoneSize(tester);
    final year = DateTime.now().year;
    var goalsLoaded = false;
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/summary') {
        return jsonResponse(_yearSummary(year));
      }
      if (request.url.path == '/api/goal-plan') {
        goalsLoaded = true;
        return jsonResponse({
          'plans': <Object>[],
          'funding': {'year': year, 'annualTotal': 0, 'months': <Object>[]},
        });
      }
      if (request.url.path == '/api/goals') {
        return jsonResponse(const <Object>[]);
      }
      if (request.url.path == '/api/goal-templates/applicable') {
        return jsonResponse(const {'template': null});
      }
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const FinancesView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Despesas'), findsWidgets);
    expect(find.text('Objetivos'), findsOneWidget);
    expect(goalsLoaded, isFalse);

    await tester.tap(find.text('Objetivos'));
    await tester.pumpAndSettle();

    expect(goalsLoaded, isTrue);
    expect(find.text('Objetivos do ano'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the close wizard from the app bar', (tester) async {
    setPhoneSize(tester);
    final year = DateTime.now().year;
    final month = MonthKey.current();
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/summary') {
        return jsonResponse(_yearSummary(year));
      }
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const FinancesView()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fechar mês atual'));
    await tester.pumpAndSettle();

    expect(
      find.text('Fechar ${AppFormatters.monthName(month)}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
