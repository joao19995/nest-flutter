import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/categories_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/category.dart';
import 'package:nest/ui/features/categories/view_models/categories_view_model.dart';

import '../../../support/test_helpers.dart';

CategoriesViewModel _viewModel(MockClient client) => CategoriesViewModel(
  categoriesRepository: CategoriesRepository(
    client: NestApiClient(
      httpClient: client,
      baseUrl: 'http://test.local',
      apiKey: '',
    ),
  ),
);

void main() {
  test('load maps the categories', () async {
    final client = MockClient(
      (request) async => jsonResponse(const [
        {'id': 'c1', 'name': 'Renda', 'type': 'FIXED', 'active': true},
        {
          'id': 'c2',
          'name': 'Supermercado',
          'type': 'VARIABLE',
          'active': true,
        },
      ]),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.categories, hasLength(2));
    expect(viewModel.categories.first.type, CategoryType.fixed);
  });

  test('delete is optimistic and restore brings the category back', () async {
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        return jsonResponse(const {'id': 'c1'});
      }
      if (request.url.path == '/api/categories/c1/restore') {
        return jsonResponse(const {
          'id': 'c1',
          'name': 'Renda',
          'type': 'FIXED',
          'active': true,
        });
      }
      return jsonResponse(const [
        {'id': 'c1', 'name': 'Renda', 'type': 'FIXED', 'active': true},
      ]);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    final category = viewModel.categories.single;

    expect(await viewModel.deleteCategory(category), isTrue);
    expect(viewModel.categories, isEmpty);

    await viewModel.restoreCategory(category);
    expect(viewModel.categories, hasLength(1));
  });

  test('reports a load failure without throwing', () async {
    final client = MockClient(
      (request) async => jsonResponse(const {'error': 'Falhou.'}, status: 500),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.errorMessage, 'Falhou.');
    expect(viewModel.isEmpty, isTrue);
  });
}
