import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/views/goal_templates_view.dart';

import '../../../support/test_helpers.dart';

Finder _field(String label, int index) => find
    .byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    )
    .at(index);

String _text(WidgetTester tester, String label, int index) {
  final field = tester
      .widgetList<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == label,
        ),
      )
      .elementAt(index);
  return field.controller!.text;
}

void main() {
  testWidgets('derives the percentages from the budgets', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async {
      if (request.url.path == '/api/goal-templates') {
        return jsonResponse(<Object>[]);
      }
      if (request.url.path == '/api/goals') {
        return jsonResponse(const [
          {'id': 'g1', 'name': 'Viagem', 'active': true},
          {'id': 'g2', 'name': 'Carro', 'active': true},
        ]);
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      DependenciesScope(
        dependencies: testDependencies(client),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const GoalTemplatesView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nova versão'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Viagem'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Carro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carro'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Orçamento', 0), '1000');
    await tester.pump();
    await tester.enterText(_field('Orçamento', 1), '3000');
    await tester.pump();

    expect(_text(tester, 'Percentagem', 0), '25');
    expect(_text(tester, 'Percentagem', 1), '75');
    expect(find.text('100.00%'), findsOneWidget);
    expect(find.byType(AppChip), findsNWidgets(4));
    expect(find.widgetWithText(AppChip, 'Anual'), findsNWidgets(2));
    expect(find.widgetWithText(AppChip, 'Nice to have'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
