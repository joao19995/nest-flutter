import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppEmptyState', () {
    testWidgets('shows the icon, title and message', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Sem despesas',
            message: 'Ainda não há nada neste mês.',
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
      expect(icon.color, NestColors.light.primaryDark);
      expect(find.text('Sem despesas'), findsOneWidget);
      expect(find.text('Ainda não há nada neste mês.'), findsOneWidget);
    });

    testWidgets('fires the optional action', (tester) async {
      var acted = false;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            icon: Icons.add,
            title: 'Sem listas',
            actionLabel: 'Criar lista',
            onAction: () => acted = true,
          ),
        ),
      );

      await tester.tap(find.text('Criar lista'));
      expect(acted, isTrue);
    });
  });
}
