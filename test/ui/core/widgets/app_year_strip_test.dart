import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_year_strip.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

ExpenseMonthSummary _month(String month, ExpenseMonthStatus status) =>
    ExpenseMonthSummary(
      month: month,
      status: status,
      planned: 0,
      actual: 0,
      progressPct: 0,
      over: false,
      filledEntries: 0,
      totalEntries: 0,
    );

List<ExpenseMonthSummary> _months() => [
  for (var index = 1; index <= 12; index++)
    _month(
      '2026-${index.toString().padLeft(2, '0')}',
      index <= 8
          ? ExpenseMonthStatus.closed
          : index == 9
          ? ExpenseMonthStatus.open
          : ExpenseMonthStatus.missing,
    ),
];

BoxDecoration _decoration(WidgetTester tester, String key) =>
    tester.widget<Container>(find.byKey(ValueKey(key))).decoration
        as BoxDecoration;

void main() {
  group('AppYearStrip', () {
    testWidgets('renders one tooltip point per month', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppYearStrip(
            months: _months(),
            currentMonth: '2026-09',
            onTap: (_) {},
          ),
        ),
      );

      expect(find.byType(Tooltip), findsNWidgets(12));
      expect(find.byTooltip('Janeiro'), findsOneWidget);
      expect(find.byTooltip('Dezembro'), findsOneWidget);
    });

    testWidgets('colours each point by its month state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppYearStrip(
            months: _months(),
            currentMonth: '2026-09',
            onTap: (_) {},
          ),
        ),
      );

      const colors = NestColors.light;
      final closed = _decoration(tester, 'year-strip-2026-01');
      final open = _decoration(tester, 'year-strip-2026-09');
      final missing = _decoration(tester, 'year-strip-2026-10');

      expect(closed.color, colors.primary);
      expect(closed.border, isNull);
      expect(open.color, colors.mint);
      expect(open.border?.top.color, colors.primary);
      expect(missing.color, colors.lineSoft);

      final currentRing = _decoration(tester, 'year-strip-ring-2026-09');
      final otherRing = _decoration(tester, 'year-strip-ring-2026-01');
      expect(currentRing.border?.top.color, colors.primary);
      expect(otherRing.border, isNull);
    });

    testWidgets('reports the tapped month', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        _wrap(
          AppYearStrip(
            months: _months(),
            currentMonth: '2026-09',
            onTap: (month) => tapped = month,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('year-strip-2026-03')));
      expect(tapped, '2026-03');
    });

    testWidgets('gives every point a tall touch target', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppYearStrip(
            months: _months(),
            currentMonth: '2026-09',
            onTap: (_) {},
          ),
        ),
      );

      final target = find.descendant(
        of: find.byTooltip('Janeiro'),
        matching: find.byType(InkWell),
      );
      expect(
        tester.getSize(target).height,
        greaterThanOrEqualTo(AppSizes.minTouchTarget),
      );
    });
  });
}
