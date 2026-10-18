import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/categories_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/category.dart';

CategoriesRepository _repository(MockClient mock) => CategoriesRepository(
  client: NestApiClient(
    httpClient: mock,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('fetchCategories maps the list and can request inactive ones', () async {
    String? include;
    final repository = _repository(
      MockClient((request) async {
        include = request.url.queryParameters['includeInactive'];
        return _json(const [
          {'id': 'c1', 'name': 'Renda', 'type': 'FIXED', 'active': true},
        ]);
      }),
    );

    final categories = await repository.fetchCategories(includeInactive: true);

    expect(include, 'true');
    expect(categories.single.type, CategoryType.fixed);
  });

  test('createCategory sends the API type', () async {
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json(const {
          'id': 'c1',
          'name': 'Renda',
          'type': 'FIXED',
          'active': true,
        }, status: 201);
      }),
    );

    await repository.createCategory(name: 'Renda', type: CategoryType.fixed);

    expect(body?['name'], 'Renda');
    expect(body?['type'], 'FIXED');
    expect(body?.containsKey('active'), isFalse);
  });

  test('updateCategory sends name, type and active', () async {
    String? path;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json(const {
          'id': 'c1',
          'name': 'Renda',
          'type': 'VARIABLE',
          'active': false,
        });
      }),
    );

    await repository.updateCategory(
      'c1',
      name: 'Renda',
      type: CategoryType.variable,
      active: false,
    );

    expect(path, '/api/categories/c1');
    expect(body?['type'], 'VARIABLE');
    expect(body?['active'], isFalse);
  });

  test('delete and restore hit the expected routes', () async {
    final calls = <String>[];
    final repository = _repository(
      MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'DELETE') {
          return _json(const {'id': 'c1'});
        }
        return _json(const {
          'id': 'c1',
          'name': 'Renda',
          'type': 'FIXED',
          'active': true,
        });
      }),
    );

    await repository.deleteCategory('c1');
    await repository.restoreCategory('c1');

    expect(calls, [
      'DELETE /api/categories/c1',
      'POST /api/categories/c1/restore',
    ]);
  });
}
