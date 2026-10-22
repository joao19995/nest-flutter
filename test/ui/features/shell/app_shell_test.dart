import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/features/shell/views/app_shell.dart';

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
  testWidgets('defers the secondary destinations until they are opened', (
    tester,
  ) async {
    setPhoneSize(tester);
    final year = DateTime.now().year;
    final requested = <String>[];
    final client = MockClient((request) async {
      requested.add(request.url.path);
      if (request.url.path == '/api/months/summary') {
        return jsonResponse(_yearSummary(year));
      }
      if (request.url.path == '/api/goal-plan') {
        return jsonResponse({
          'plans': <Object>[],
          'funding': {'year': year, 'annualTotal': 0, 'months': <Object>[]},
        });
      }
      if (request.url.path == '/api/goal-templates/applicable') {
        return jsonResponse(const {'template': null});
      }
      if (request.url.path.startsWith('/api/months/')) {
        return jsonResponse(const {'error': 'not found'}, status: 404);
      }
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const AppShell()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Início'), findsWidgets);
    expect(requested, isNot(contains('/api/people')));
    expect(requested, isNot(contains('/api/category-templates')));

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    expect(requested, isNot(contains('/api/people')));

    await tester.tap(find.text('Pessoas'));
    await tester.pumpAndSettle();

    expect(requested, contains('/api/people'));
    expect(tester.takeException(), isNull);
  });
}
