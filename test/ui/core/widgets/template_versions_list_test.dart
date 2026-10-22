import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/template_versions_list.dart';

void main() {
  testWidgets('renders the month and subtitle and reports taps', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateVersionsList<String>(
            templates: const ['2026-01'],
            monthLabel: (month) => month,
            subtitle: (month) => 'versão $month',
            onTap: (month) => tapped = month,
          ),
        ),
      ),
    );

    expect(find.text('2026-01'), findsOneWidget);
    expect(find.text('versão 2026-01'), findsOneWidget);

    await tester.tap(find.text('2026-01'));
    await tester.pumpAndSettle();
    expect(tapped, '2026-01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the action error banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateVersionsList<String>(
            templates: const ['2026-01'],
            errorMessage: 'Falhou',
            monthLabel: (month) => month,
            subtitle: (month) => 'versão',
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Falhou'), findsOneWidget);
  });
}
