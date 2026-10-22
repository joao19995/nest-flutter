import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/config/settings_controller.dart';
import 'package:nest/ui/features/settings/views/settings_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_helpers.dart';

void main() {
  test('loads and persists the theme mode', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final controller = SettingsController();
    await controller.load();
    expect(controller.themeMode, ThemeMode.dark);

    await controller.setThemeMode(ThemeMode.light);
    expect(controller.themeMode, ThemeMode.light);

    final reloaded = SettingsController();
    await reloaded.load();
    expect(reloaded.themeMode, ThemeMode.light);
  });

  testWidgets('changes the theme mode from the selector', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final dependencies = testDependencies(
      MockClient((request) async {
        return jsonResponse(const <Object>[]);
      }),
    );

    await tester.pumpWidget(
      wrapWithDependencies(dependencies, const SettingsView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Definições'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);

    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(dependencies.settingsController.themeMode, ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });
}
