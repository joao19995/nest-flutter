import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_section_switcher.dart';

const _options = <AppSectionOption<String>>[
  AppSectionOption(
    value: 'expenses',
    label: 'Despesas',
    icon: Icons.receipt_long_outlined,
  ),
  AppSectionOption(
    value: 'goals',
    label: 'Objetivos',
    icon: Icons.flag_outlined,
  ),
];

/// Pumps [child] inside a viewport [width] wide so the breakpoint logic is
/// exercised at a known layout size.
Future<void> _pump(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

SegmentedButton<String> _button(WidgetTester tester) => tester
    .widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));

void main() {
  group('AppSectionSwitcher', () {
    testWidgets('renders every label and reports the selected value', (
      tester,
    ) async {
      await _pump(
        tester,
        900,
        AppSectionSwitcher<String>(
          options: _options,
          selected: 'goals',
          onChanged: (_) {},
        ),
      );

      expect(find.text('Despesas'), findsOneWidget);
      expect(find.text('Objetivos'), findsOneWidget);
      expect(_button(tester).selected, {'goals'});
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a segment reports its value', (tester) async {
      String? changed;
      await _pump(
        tester,
        900,
        AppSectionSwitcher<String>(
          options: _options,
          selected: 'expenses',
          onChanged: (value) => changed = value,
        ),
      );

      await tester.tap(find.text('Objetivos'));
      await tester.pumpAndSettle();

      expect(changed, 'goals');
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides the icons on a narrow viewport', (tester) async {
      await _pump(
        tester,
        320,
        AppSectionSwitcher<String>(
          options: _options,
          selected: 'expenses',
          onChanged: (_) {},
        ),
      );

      final segments = _button(tester).segments;
      expect(segments, hasLength(_options.length));
      for (final segment in segments) {
        expect(segment.icon, isNull);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the icons on a wide viewport', (tester) async {
      await _pump(
        tester,
        900,
        AppSectionSwitcher<String>(
          options: _options,
          selected: 'expenses',
          onChanged: (_) {},
        ),
      );

      final segments = _button(tester).segments;
      expect(segments[0].icon, isA<Icon>());
      expect((segments[0].icon! as Icon).icon, Icons.receipt_long_outlined);
      expect(segments[1].icon, isA<Icon>());
      expect((segments[1].icon! as Icon).icon, Icons.flag_outlined);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact never shows the icons, even when wide', (
      tester,
    ) async {
      await _pump(
        tester,
        900,
        AppSectionSwitcher<String>(
          options: _options,
          selected: 'expenses',
          onChanged: (_) {},
          compact: true,
        ),
      );

      for (final segment in _button(tester).segments) {
        expect(segment.icon, isNull);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
