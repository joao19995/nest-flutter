import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_error_banner.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppErrorBanner', () {
    testWidgets('shows the message', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppErrorBanner(message: 'Algo falhou')),
      );

      expect(find.text('Algo falhou'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('dismisses through the close button when provided', (
      tester,
    ) async {
      var dismissed = false;
      await tester.pumpWidget(
        _wrap(
          AppErrorBanner(
            message: 'Algo falhou',
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });
  });
}
