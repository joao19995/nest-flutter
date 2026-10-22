import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/more/views/more_view.dart';

void main() {
  testWidgets('lists the overflow destinations', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MoreView()),
    );

    expect(find.text('Mais'), findsOneWidget);
    expect(find.text('Pessoas'), findsOneWidget);
    expect(find.text('Contas'), findsOneWidget);
    expect(find.text('Definições'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
