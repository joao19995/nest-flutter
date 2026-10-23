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
              (
                label: 'Jan',
                value: 100,
                planned: null,
                over: false,
                highlighted: false,
              ),
              (
                label: 'Fev',
                value: 200,
                planned: null,
                over: false,
                highlighted: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Fev'), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-chart-planned-Jan')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints over bars coral and highlighted bars bright', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppBarChart(
            bars: [
              (
                label: 'Jan',
                value: 100,
                planned: null,
                over: false,
                highlighted: false,
              ),
              (
                label: 'Fev',
                value: 200,
                planned: null,
                over: true,
                highlighted: false,
              ),
              (
                label: 'Mar',
                value: 150,
                planned: null,
                over: false,
                highlighted: true,
              ),
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

    testWidgets('draws the planned marker when a plan is present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppBarChart(
            bars: [
              (
                label: 'Jan',
                value: 100,
                planned: 200,
                over: false,
                highlighted: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('bar-chart-planned-Jan')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a bar shows its value and tapping away closes it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppBarChart(
            bars: [
              (
                label: 'Jan',
                value: 100,
                planned: null,
                over: false,
                highlighted: false,
              ),
              (
                label: 'Fev',
                value: 200,
                planned: null,
                over: false,
                highlighted: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppFormatters.currency(100)), findsNothing);

      await tester.tap(find.text('Jan'));
      await tester.pumpAndSettle();
      expect(find.text(AppFormatters.currency(100)), findsOneWidget);

      await tester.tap(find.text('Fev'));
      await tester.pumpAndSettle();
      expect(find.text(AppFormatters.currency(200)), findsOneWidget);
      expect(find.text(AppFormatters.currency(100)), findsNothing);

      await tester.tapAt(const Offset(20, 550));
      await tester.pumpAndSettle();
      expect(find.text(AppFormatters.currency(200)), findsNothing);
    });

    testWidgets('handles an empty set', (tester) async {
      await tester.pumpWidget(_wrap(const AppBarChart(bars: [])));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
