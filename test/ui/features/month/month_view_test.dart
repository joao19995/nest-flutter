import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/month/views/month_view.dart';

import '../../../support/test_helpers.dart';

/// The section switcher's label, which the ritual hero can also repeat.
Finder _sectionTab(String label) => find.descendant(
  of: find.byType(AppSectionSwitcher<MonthSection>),
  matching: find.text(label),
);

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
      expect(_sectionTab('Objetivos'), findsOneWidget);
      expect(find.text('Por criar'), findsOneWidget);
      expect(goalsLoaded, isFalse);
      expect(
        ritualRequests,
        containsAll(['/api/months/$month', '/api/goal-plan/$month']),
      );

      await tester.tap(_sectionTab('Objetivos'));
      await tester.pumpAndSettle();

      expect(goalsLoaded, isTrue);
      expect(find.text('Objetivos do ano'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the refresh signal reloads the ritual only', (tester) async {
    setPhoneSize(tester);
    final year = DateTime.now().year;
    final month = MonthKey.current();
    var ritualLoads = 0;
    var goalsLoads = 0;
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/months/summary') {
        return jsonResponse(_yearSummary(year));
      }
      if (path == '/api/goal-plan') {
        goalsLoads++;
        return jsonResponse({
          'plans': <Object>[],
          'funding': {'year': year, 'annualTotal': 0, 'months': <Object>[]},
        });
      }
      if (path == '/api/months/$month' || path == '/api/goal-plan/$month') {
        ritualLoads++;
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

    final refresh = ValueNotifier<int>(0);
    addTearDown(refresh.dispose);

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        MonthView(refreshSignal: refresh),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_sectionTab('Objetivos'));
    await tester.pumpAndSettle();

    final ritualBefore = ritualLoads;
    final goalsBefore = goalsLoads;
    expect(goalsBefore, greaterThan(0));

    refresh.value++;
    await tester.pumpAndSettle();

    expect(ritualLoads, greaterThan(ritualBefore));
    expect(goalsLoads, goalsBefore);
    expect(find.text('Objetivos do ano'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders on a 320px surface at 1.5 text scale without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final year = DateTime.now().year;
    final month = MonthKey.current();
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/months/summary') {
        return jsonResponse(_yearSummary(year));
      }
      if (path == '/api/goal-plan') {
        return jsonResponse({
          'plans': <Object>[],
          'funding': {'year': year, 'annualTotal': 0, 'months': <Object>[]},
        });
      }
      if (path == '/api/months/$month' || path == '/api/goal-plan/$month') {
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

    expect(tester.takeException(), isNull);

    await tester.tap(_sectionTab('Despesas'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(_sectionTab('Objetivos'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
