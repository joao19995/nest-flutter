import 'package:nest/data/models/category_model.dart';
import 'package:nest/data/models/json_mapper.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/category.dart';

/// Reads and writes the expense categories.
class CategoriesRepository {
  CategoriesRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns the categories ordered by name. Soft-deleted categories are
  /// excluded unless [includeInactive].
  Future<List<Category>> fetchCategories({bool includeInactive = false}) async {
    final path = includeInactive
        ? '/api/categories?includeInactive=true'
        : '/api/categories';
    final data = await _client.get(path);
    return mapJsonList(data, (json) => CategoryModel.fromJson(json).toDomain());
  }

  /// Creates a category; the server always marks it active.
  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    String? iconKey,
  }) async {
    final data = await _client.post('/api/categories', {
      'name': name,
      'type': _apiType(type),
      'iconKey': ?iconKey,
    });
    return mapJson(data, (json) => CategoryModel.fromJson(json).toDomain());
  }

  /// Updates the category [id]. The category update body needs all three
  /// fields, so [active] is always sent.
  Future<Category> updateCategory(
    String id, {
    required String name,
    required CategoryType type,
    required bool active,
    String? iconKey,
  }) async {
    final data = await _client.put('/api/categories/$id', {
      'name': name,
      'type': _apiType(type),
      'active': active,
      'iconKey': ?iconKey,
    });
    return mapJson(data, (json) => CategoryModel.fromJson(json).toDomain());
  }

  /// Soft-deletes the category [id] (sets `active = false`).
  Future<void> deleteCategory(String id) =>
      _client.delete('/api/categories/$id');

  /// Restores a soft-deleted category [id].
  Future<Category> restoreCategory(String id) async {
    final data = await _client.post('/api/categories/$id/restore', const {});
    return mapJson(data, (json) => CategoryModel.fromJson(json).toDomain());
  }

  static String _apiType(CategoryType type) => switch (type) {
    CategoryType.fixed => 'FIXED',
    CategoryType.variable => 'VARIABLE',
  };
}
