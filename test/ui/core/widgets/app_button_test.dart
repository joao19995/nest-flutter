import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_button.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

ButtonStyle _styleOf(WidgetTester tester) {
  final button = tester.widget<TextButton>(find.byType(TextButton));
  return button.style!;
}

void main() {
  group('AppButton', () {
    testWidgets('primary is a filled pill with a hover state layer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AppButton(label: 'Guardar', onPressed: () {})),
      );

      final style = _styleOf(tester);
      expect(
        style.backgroundColor?.resolve(const <WidgetState>{}),
        AppColors.primary,
      );
      expect(
        style.foregroundColor?.resolve(const <WidgetState>{}),
        AppColors.surface,
      );
      expect(style.shape?.resolve(const <WidgetState>{}), isA<StadiumBorder>());
      expect(
        style.overlayColor?.resolve(const <WidgetState>{}),
        AppColors.transparent,
      );
      expect(
        style.overlayColor?.resolve(const {WidgetState.hovered}),
        isNot(AppColors.transparent),
      );
      expect(style.animationDuration, AppMotion.standard);
    });

    testWidgets('secondary is a tonal button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Cancelar',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
      );

      final style = _styleOf(tester);
      expect(
        style.backgroundColor?.resolve(const <WidgetState>{}),
        AppColors.mint,
      );
      expect(
        style.foregroundColor?.resolve(const <WidgetState>{}),
        AppColors.primaryDark,
      );
    });

    testWidgets('disabled uses the muted pair', (tester) async {
      await tester.pumpWidget(_wrap(const AppButton(label: 'Guardar')));

      final style = _styleOf(tester);
      expect(
        style.backgroundColor?.resolve(const {WidgetState.disabled}),
        AppColors.lineSoft,
      );
      expect(
        style.foregroundColor?.resolve(const {WidgetState.disabled}),
        AppColors.faint,
      );
      expect(
        style.overlayColor?.resolve(const {WidgetState.disabled}),
        AppColors.transparent,
      );
    });

    testWidgets('icon-only is circular', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton.icon(
            icon: Icons.add,
            tooltip: 'Adicionar',
            onPressed: () {},
          ),
        ),
      );

      final style = _styleOf(tester);
      expect(style.shape?.resolve(const <WidgetState>{}), isA<CircleBorder>());
    });
  });
}
