import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/features/month/views/month_view.dart';

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
  testWidgets(
    'starts on Balanço and loads goals only when its tab is selected',
    (tester) async {
      setPhoneSize(tester);
      final year = DateTime.now().year;
      final month = MonthKey.current();
      final ritualRequests = <String>{};
      var goalsLoaded = false;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/months/summary') {
          return jsonResponse(_yearSummary(year));
        }
        if (path == '/api/goal-plan') {
          goalsLoaded = true;
          return jsonResponse({
            'plans': <Object>[],
            'funding': {'year': year, 'annualTotal': 0, 'months': <Object>[]},
          });
        }
        if (path == '/api/months/$month' || path == '/api/goal-plan/$month') {
          ritualRequests.add(path);
          return jsonResponse(const {'error': 'not found'}, status: 404);
        }
        if (path == '/api/goals') {
          return jsonResponse(const <Object>[]);
        }
        if (path == '/api/goal-templates/applicable') {
          return jsonResponse(const {'template': null});
        }
        return jsonResponse(const <Object>[]);
      });

      await tester.pumpWidget(
        wrapWithDependencies(testDependencies(client), const MonthView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mês'), findsOneWidget);
      expect(find.text('Balanço'), findsOneWidget);
      expect(find.text('Despesas'), findsWidgets);
      expect(find.text('Objetivos'), findsOneWidget);
      expect(find.text('Por criar'), findsOneWidget);
      expect(goalsLoaded, isFalse);
      expect(
        ritualRequests,
        containsAll(['/api/months/$month', '/api/goal-plan/$month']),
      );

      await tester.tap(find.text('Objetivos'));
      await tester.pumpAndSettle();

      expect(goalsLoaded, isTrue);
      expect(find.text('Objetivos do ano'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
