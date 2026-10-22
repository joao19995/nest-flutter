import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_stat_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppStatTile', () {
    testWidgets('shows the caption, value and icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppStatTile(
            label: 'Poupado',
            value: '1 250,00 €',
            icon: Icons.savings_outlined,
          ),
        ),
      );

      expect(find.text('Poupado'), findsOneWidget);
      expect(find.text('1 250,00 €'), findsOneWidget);
      expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
    });

    testWidgets('uses the accent on the value and icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppStatTile(
            label: 'Acima',
            value: '-20,00 €',
            icon: Icons.warning_amber_outlined,
            accent: NestColors.light.over,
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.warning_amber_outlined),
      );
      final value = tester.widget<Text>(find.text('-20,00 €'));
      expect(icon.color, NestColors.light.over);
      expect(value.style?.color, NestColors.light.over);
    });
  });
}
