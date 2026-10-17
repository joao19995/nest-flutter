import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_bar_chart.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

List<Color?> _barColors(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((container) => (container.decoration as BoxDecoration?)?.color)
    .toList();

void main() {
  group('AppBarChart', () {
    testWidgets('renders one label per bar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppBarChart(
            bars: [
              (label: 'Jan', value: 100, over: false, highlighted: false),
              (label: 'Fev', value: 200, over: false, highlighted: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Fev'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints over bars coral and highlighted bars bright', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppBarChart(
            bars: [
              (label: 'Jan', value: 100, over: false, highlighted: false),
              (label: 'Fev', value: 200, over: true, highlighted: false),
              (label: 'Mar', value: 150, over: false, highlighted: true),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final colors = _barColors(tester);
      expect(colors, contains(AppColors.onHeroMuted));
      expect(colors, contains(AppColors.overOnDark));
      expect(colors, contains(AppColors.onHero));
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles an empty set', (tester) async {
      await tester.pumpWidget(_wrap(const AppBarChart(bars: [])));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
