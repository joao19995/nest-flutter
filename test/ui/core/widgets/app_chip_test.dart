import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_chip.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppChip', () {
    testWidgets('renders the label and icon with the badge style', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppChip(
            label: 'Fixa',
            icon: Icons.push_pin_outlined,
            style: AppBadgeStyles.open(NestColors.light),
          ),
        ),
      );

      expect(find.text('Fixa'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin_outlined));
      expect(icon.color, NestColors.light.primaryDark);
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AppChip),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, NestColors.light.mintSoft);
    });

    testWidgets('is tappable when a callback is given', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          AppChip(
            label: 'Variável',
            style: AppBadgeStyles.muted(NestColors.light),
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Variável'));
      expect(tapped, isTrue);
    });
  });
}
