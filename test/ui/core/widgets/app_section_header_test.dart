import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_section_header.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppSectionHeader', () {
    testWidgets('renders the title and trailing widget', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppSectionHeader(title: 'Por mês', trailing: Text('Ver tudo')),
        ),
      );

      expect(find.text('Por mês'), findsOneWidget);
      expect(find.text('Ver tudo'), findsOneWidget);
    });

    testWidgets('opens when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          AppSectionHeader(title: 'Categorias', onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.text('Categorias'));
      expect(tapped, isTrue);
    });
  });
}
