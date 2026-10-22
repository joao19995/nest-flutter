import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// Builds a JSON HTTP response for the MockClient-based tests.
http.Response jsonResponse(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Builds the dependency graph against a mocked API client.
AppDependencies testDependencies(MockClient client) => AppDependencies(
  apiClient: NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

/// Wraps [child] in the dependency scope and the light app theme.
Widget wrapWithDependencies(AppDependencies dependencies, Widget child) =>
    DependenciesScope(
      dependencies: dependencies,
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

/// Uses an iPhone-sized viewport for widget tests.
void setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
