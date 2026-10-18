import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/people/views/people_view.dart';

AppDependencies _dependencies(MockClient client) => AppDependencies(
  apiClient: NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

Widget _wrap(AppDependencies dependencies, Widget child) => DependenciesScope(
  dependencies: dependencies,
  child: MaterialApp(theme: AppTheme.light, home: child),
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

MockClient _client() => MockClient((request) async {
  if (request.url.path == '/api/people') {
    return _json(const [
      {
        'id': 'p1',
        'name': 'João',
        'dailySpendingPercentage': 25,
        'applicableIncome': 2500,
      },
    ]);
  }
  if (request.url.path == '/api/people/incomes') {
    return _json(const <Object>[]);
  }
  return _json(const <Object>[], status: 404);
});

void main() {
  testWidgets('keeps the hero at the top like Tarefas and Calendário', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(_dependencies(_client()), const PeopleView()));
    await tester.pumpAndSettle();

    final heroTop = tester.getTopLeft(find.byType(HeroPanel)).dy;
    expect(heroTop, lessThan(130));
  });
}
