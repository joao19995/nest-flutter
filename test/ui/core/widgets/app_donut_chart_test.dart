import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_donut_chart.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppDonutChart', () {
    testWidgets('renders the centre and a legend row per slice', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppDonutChart(
            data: [
              (label: 'Casa', value: 75, color: AppColors.primary),
              (label: 'Luz', value: 25, color: AppColors.terraDark),
            ],
            centerValue: '100,00 €',
            centerLabel: 'Total',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100,00 €'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Luz'), findsOneWidget);
      expect(find.text(AppFormatters.percentage(75)), findsOneWidget);
      expect(find.text(AppFormatters.percentage(25)), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles an empty set', (tester) async {
      await tester.pumpWidget(_wrap(const AppDonutChart(data: [])));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ignores zero-valued slices in the legend', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppDonutChart(
            data: [
              (label: 'Casa', value: 0, color: AppColors.primary),
              (label: 'Luz', value: 10, color: AppColors.terraDark),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Casa'), findsNothing);
      expect(find.text('Luz'), findsOneWidget);
    });
  });
}
