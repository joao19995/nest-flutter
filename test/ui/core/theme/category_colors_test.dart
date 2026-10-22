import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';

void main() {
  group('category palette', () {
    test('has eight tones in both brightnesses', () {
      expect(NestColors.light.categoryPalette, hasLength(8));
      expect(NestColors.dark.categoryPalette, hasLength(8));
      expect(
        NestColors.dark.categoryPalette,
        hasLength(NestColors.light.categoryPalette.length),
      );
    });
  });

  group('colorForCategory', () {
    test('is deterministic for the same name', () {
      final first = NestColors.light.colorForCategory('Casa');
      final second = NestColors.light.colorForCategory('Casa');
      expect(first, second);
    });

    test('ignores surrounding whitespace and case', () {
      final color = NestColors.light.colorForCategory('Casa');
      expect(NestColors.light.colorForCategory('  casa  '), color);
      expect(NestColors.light.colorForCategory('CASA'), color);
    });

    test('always returns a colour from the active palette', () {
      for (final name in ['Casa', 'Luz', 'Água', 'Gasolina', 'Zzz']) {
        expect(
          NestColors.light.categoryPalette,
          contains(NestColors.light.colorForCategory(name)),
        );
        expect(
          NestColors.dark.categoryPalette,
          contains(NestColors.dark.colorForCategory(name)),
        );
      }
    });

    test('keeps the same slot in light and dark', () {
      const light = NestColors.light;
      const dark = NestColors.dark;
      final lightIndex = light.categoryPalette.indexOf(
        light.colorForCategory('Casa'),
      );
      final darkIndex = dark.categoryPalette.indexOf(
        dark.colorForCategory('Casa'),
      );
      expect(lightIndex, darkIndex);
    });
  });
}
