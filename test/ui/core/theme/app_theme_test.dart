import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';

Future<NestColors> _colorsFor(WidgetTester tester, ThemeData theme) async {
  late NestColors colors;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          colors = context.colors;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return colors;
}

void main() {
  group('AppTheme palette', () {
    testWidgets('exposes the light palette', (tester) async {
      final colors = await _colorsFor(tester, AppTheme.light);
      expect(AppTheme.light.brightness, Brightness.light);
      expect(colors.ink, NestColors.light.ink);
      expect(colors.paper, NestColors.light.paper);
      expect(colors.surface, NestColors.light.surface);
    });

    testWidgets('exposes the dark palette', (tester) async {
      final colors = await _colorsFor(tester, AppTheme.dark);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(colors.ink, NestColors.dark.ink);
      expect(colors.paper, NestColors.dark.paper);
      expect(colors.paper, isNot(NestColors.light.paper));
    });
  });
}
