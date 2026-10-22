import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/people/views/people_view.dart';

import '../../../support/test_helpers.dart';

MockClient _client() => MockClient((request) async {
  if (request.url.path == '/api/people') {
    return jsonResponse(const [
      {
        'id': 'p1',
        'name': 'João',
        'dailySpendingPercentage': 25,
        'applicableIncome': 2500,
      },
    ]);
  }
  if (request.url.path == '/api/people/incomes') {
    return jsonResponse(const <Object>[]);
  }
  return jsonResponse(const <Object>[], status: 404);
});

void main() {
  testWidgets('keeps the hero at the top like Tarefas and Calendário', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(_client()), const PeopleView()),
    );
    await tester.pumpAndSettle();

    final heroTop = tester.getTopLeft(find.byType(HeroPanel)).dy;
    expect(heroTop, lessThan(130));
  });
}
