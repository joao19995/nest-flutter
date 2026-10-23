import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/category_icon.dart';

Future<IconData?> _iconFor(
  WidgetTester tester,
  String category, {
  String? iconKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: CategoryIcon(category: category, iconKey: iconKey),
      ),
    ),
  );
  return tester.widget<Icon>(find.byType(Icon)).icon;
}

void main() {
  group('CategoryIcon', () {
    testWidgets('maps known categories case-insensitively', (tester) async {
      expect(await _iconFor(tester, 'Casa'), Icons.home_outlined);
      expect(await _iconFor(tester, 'luz'), Icons.bolt);
      expect(await _iconFor(tester, 'Água'), Icons.water_drop_outlined);
      expect(await _iconFor(tester, 'Internet'), Icons.wifi);
      expect(
        await _iconFor(tester, 'Gasolina'),
        Icons.local_gas_station_outlined,
      );
      expect(await _iconFor(tester, 'Via Verde'), Icons.toll);
    });

    testWidgets('matches keywords inside longer labels', (tester) async {
      expect(await _iconFor(tester, 'Luz e Gás'), Icons.bolt);
    });

    testWidgets('falls back for unknown categories', (tester) async {
      expect(
        await _iconFor(tester, 'Zzz inexplicável'),
        CategoryIcons.fallback,
      );
    });

    testWidgets('a stored iconKey wins over the name heuristic', (
      tester,
    ) async {
      expect(
        await _iconFor(tester, 'Supermercado', iconKey: 'gift'),
        Icons.card_giftcard_outlined,
      );
      expect(
        await _iconFor(tester, 'Supermercado', iconKey: 'unknown'),
        Icons.shopping_cart_outlined,
      );
    });
  });
}
