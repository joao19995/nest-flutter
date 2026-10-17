import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_progress_ring.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppProgressRing', () {
    testWidgets('paints a ring and shows its label', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppProgressRing(progress: 0.5, label: '50%')),
      );
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps progress above one without error', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppProgressRing(progress: 1.8, label: '180%')),
      );
      await tester.pumpAndSettle();

      expect(find.text('180%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
