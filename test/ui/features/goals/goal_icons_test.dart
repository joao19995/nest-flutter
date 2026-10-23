import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/goals/goal_icons.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('GoalIcon renders the icon for a known key', (tester) async {
    await tester.pumpWidget(
      _wrap(const GoalIcon(name: 'Férias', iconKey: 'plane')),
    );

    expect(find.byIcon(Icons.flight_outlined), findsOneWidget);
  });

  testWidgets('GoalIcon falls back to the flag for an unknown key', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const GoalIcon(name: 'Casa', iconKey: 'unknown')),
    );

    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('GoalIconPicker reports the tapped option', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        GoalIconPicker(selectedKey: 'flag', onChanged: (key) => selected = key),
      ),
    );

    await tester.tap(find.byIcon(Icons.flight_outlined));

    expect(selected, 'plane');
  });
}
