import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/accounts_repository.dart';
import 'package:nest/data/repositories/categories_repository.dart';
import 'package:nest/data/repositories/category_templates_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/category_template.dart';
import 'package:nest/ui/features/category_templates/view_models/category_templates_view_model.dart';

CategoryTemplatesViewModel _viewModel(MockClient client) {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  return CategoryTemplatesViewModel(
    categoryTemplatesRepository: CategoryTemplatesRepository(client: api),
    categoriesRepository: CategoriesRepository(client: api),
    accountsRepository: AccountsRepository(client: api),
  );
}

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

MockClient _loadClient() => MockClient((request) async {
  switch (request.url.path) {
    case '/api/category-templates':
      return _json(const [
        {'id': 't1', 'validFrom': '2026-01', 'entries': <Object>[]},
      ]);
    case '/api/categories':
      return _json(const [
        {'id': 'c1', 'name': 'Renda', 'type': 'FIXED', 'active': true},
      ]);
    case '/api/accounts':
      return _json(const [
        {'id': 'a1', 'name': 'Conjunta', 'ownerPersonId': null, 'active': true},
      ]);
    default:
      return _json(const <Object>[], status: 404);
  }
});

void main() {
  test('load maps the versions, categories and accounts', () async {
    final viewModel = _viewModel(_loadClient());
    await viewModel.load();

    expect(viewModel.templates.single.validFrom, '2026-01');
    expect(viewModel.categories.single.name, 'Renda');
    expect(viewModel.accounts.single.name, 'Conjunta');
  });

  test('applicableFor reads the month pair', () async {
    final client = MockClient((request) async {
      return _json(const {
        'template': {'id': 't1', 'validFrom': '2026-01', 'entries': <Object>[]},
        'defaultAccountId': 'a1',
      });
    });

    final applicable = await _viewModel(client).applicableFor('2026-04');

    expect(applicable.template?.id, 't1');
    expect(applicable.defaultAccountId, 'a1');
  });

  test('createVersion posts validFrom and the entries', () async {
    Map<String, dynamic>? body;
    final client = MockClient((request) async {
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return _json({
        'id': 't2',
        'validFrom': '2026-11',
        'entries': <Object>[],
      }, status: 201);
    });

    final failure = await _viewModel(client).createVersion(
      validFrom: '2026-11',
      entries: const [
        CategoryTemplateEntryDraft(
          categoryId: 'c1',
          accountId: 'a1',
          expectedAmount: 800,
        ),
      ],
    );

    expect(failure, isNull);
    expect(body?['validFrom'], '2026-11');
    final entries = (body?['entries'] as List).cast<Map<String, dynamic>>();
    expect(entries.single['categoryId'], 'c1');
  });
}
