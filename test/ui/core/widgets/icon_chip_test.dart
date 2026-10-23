import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/icon_chip.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('IconChip paints the icon over a tinted circle', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const IconChip(icon: Icons.home_outlined, color: AppColors.primary),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(IconChip),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;

    expect(
      decoration.color,
      AppColors.primary.withValues(alpha: AppOpacity.tint),
    );
    expect(decoration.shape, BoxShape.circle);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });

  testWidgets('IconChip honours the requested size', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const IconChip(
          icon: Icons.flag_outlined,
          color: AppColors.primary,
          size: AppSizes.goalIconSmall,
          iconSize: AppSizes.iconSmall,
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(IconChip),
        matching: find.byType(Container),
      ),
    );
    expect(container.constraints?.maxWidth, AppSizes.goalIconSmall);
    expect(container.constraints?.maxHeight, AppSizes.goalIconSmall);
  });
}
