import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/widgets/animated_period_switcher.dart';

void main() {
  testWidgets('slides the content out when the period changes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedPeriodSwitcher(
          period: '2026',
          child: Text('conteúdo antigo'),
        ),
      ),
    );
    expect(find.text('conteúdo antigo'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedPeriodSwitcher(
          period: '2027',
          child: Text('conteúdo novo'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('conteúdo antigo'), findsOneWidget);
    expect(find.text('conteúdo novo'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('conteúdo antigo'), findsNothing);
    expect(find.text('conteúdo novo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
