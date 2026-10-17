import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_period_stepper.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppPeriodStepper', () {
    testWidgets('shows the label and fires the arrows', (tester) async {
      var previous = 0;
      var next = 0;
      await tester.pumpWidget(
        _wrap(
          AppPeriodStepper(
            label: 'Outubro 2026',
            onPrevious: () => previous++,
            onNext: () => next++,
          ),
        ),
      );

      expect(find.text('Outubro 2026'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(previous, 1);
      expect(next, 1);
    });

    testWidgets('disables an arrow when its callback is null', (tester) async {
      var next = 0;
      await tester.pumpWidget(
        _wrap(AppPeriodStepper(label: '2026', onNext: () => next++)),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(next, 0);
    });
  });
}
