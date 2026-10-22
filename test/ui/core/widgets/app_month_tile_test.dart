import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_month_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppMonthTile', () {
    testWidgets('shows the short month and formatted amount', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppMonthTile(
            month: '2026-10',
            status: AppMonthStatus.open,
            amount: 1234.5,
          ),
        ),
      );

      expect(find.text('Out'), findsOneWidget);
      expect(find.text(AppFormatters.currency(1234.5)), findsOneWidget);
    });

    testWidgets('labels a missing month as unplanned', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppMonthTile(month: '2026-11', status: AppMonthStatus.missing),
        ),
      );

      expect(find.text('Nov'), findsOneWidget);
      expect(find.text('Sem plano'), findsOneWidget);
    });

    testWidgets('paints an over amount coral and opens on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          AppMonthTile(
            month: '2026-12',
            status: AppMonthStatus.closed,
            amount: 90,
            over: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      final amount = tester.widget<Text>(find.text(AppFormatters.currency(90)));
      expect(amount.style?.color, NestColors.light.over);

      await tester.tap(find.text('Dez'));
      expect(tapped, isTrue);
    });
  });
}
