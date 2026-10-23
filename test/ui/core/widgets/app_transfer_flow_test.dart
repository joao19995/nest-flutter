import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppTransferFlow', () {
    testWidgets('flows from the person to the joint account', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 320,
            child: AppTransferFlow(
              name: 'Ana',
              amount: 100,
              detail: 'para a conta conjunta',
            ),
          ),
        ),
      );

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Conjunta'), findsOneWidget);
      expect(find.text(AppFormatters.currency(100)), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);

      final avatar = tester.getCenter(find.byType(InitialAvatar)).dx;
      final name = tester.getCenter(find.text('Ana')).dx;
      final target = tester.getCenter(find.text('Conjunta')).dx;
      final joint = tester.getCenter(find.byIcon(Icons.groups_outlined)).dx;
      expect(avatar, lessThan(name));
      expect(name, lessThan(target));
      expect(target, lessThan(joint));
    });

    testWidgets('flows from the joint account to the person', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 320,
            child: AppTransferFlow(
              name: 'Ana',
              amount: 50,
              direction: AppTransferDirection.toPerson,
              detail: 'da conta conjunta',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Conjunta'), findsOneWidget);
      final joint = tester.getCenter(find.byIcon(Icons.groups_outlined)).dx;
      final target = tester.getCenter(find.text('Conjunta')).dx;
      final name = tester.getCenter(find.text('Ana')).dx;
      final avatar = tester.getCenter(find.byType(InitialAvatar)).dx;
      expect(joint, lessThan(target));
      expect(target, lessThan(name));
      expect(name, lessThan(avatar));
    });

    testWidgets('shows a neutral line without a transfer', (tester) async {
      await tester.pumpWidget(_wrap(const AppTransferFlow(name: 'Ana')));

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Está certo'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.groups_outlined), findsNothing);
    });

    testWidgets('renders without overflow at 360 px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const Padding(
            padding: EdgeInsets.all(16),
            child: AppTransferFlow(
              name: 'Alexandra Maria da Silva',
              amount: 1234.56,
              detail: 'Ganho 2 500,00 € · quota 50% de 4 500,00 €',
            ),
          ),
        ),
      );

      expect(find.byType(AppTransferFlow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
