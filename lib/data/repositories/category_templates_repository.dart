import 'package:nest/data/models/category_template_model.dart';
import 'package:nest/data/models/json_mapper.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/category_template.dart';

/// Reads and writes the monthly expense templates.
class CategoryTemplatesRepository {
  CategoryTemplatesRepository({required NestApiClient client})
    : _client = client;

  final NestApiClient _client;

  /// Returns the template versions, oldest first.
  Future<List<CategoryTemplate>> fetchCategoryTemplates() async {
    final data = await _client.get('/api/category-templates');
    return mapJsonList(
      data,
      (json) => CategoryTemplateModel.fromJson(json).toDomain(),
    );
  }

  /// Returns the version in force for [month] (`YYYY-MM`) and the account
  /// suggested for new rows. Both rules are server-side.
  Future<ApplicableCategoryTemplate> fetchApplicableCategoryTemplate(
    String month,
  ) async {
    final data = await _client.get(
      '/api/category-templates/applicable?month=$month',
    );
    return mapJson(data, (json) {
      final template = json['template'];
      return ApplicableCategoryTemplate(
        template: template is Map<String, dynamic>
            ? CategoryTemplateModel.fromJson(template).toDomain()
            : null,
        defaultAccountId: json['defaultAccountId'] as String?,
      );
    });
  }

  /// Creates a version starting at [validFrom] (`YYYY-MM`).
  Future<CategoryTemplate> createCategoryTemplate({
    required String validFrom,
    required List<CategoryTemplateEntryDraft> entries,
  }) async {
    final data = await _client.post('/api/category-templates', {
      'validFrom': validFrom,
      'entries': [for (final entry in entries) _entryJson(entry)],
    });
    return mapJson(
      data,
      (json) => CategoryTemplateModel.fromJson(json).toDomain(),
    );
  }

  /// Replaces the entries of the version [id]. The `validFrom` does not change
  /// and rows omitted from [entries] are deactivated (never deleted).
  Future<CategoryTemplate> updateCategoryTemplate(
    String id,
    List<CategoryTemplateEntryDraft> entries,
  ) async {
    final data = await _client.put('/api/category-templates/$id', {
      'entries': [for (final entry in entries) _entryJson(entry)],
    });
    return mapJson(
      data,
      (json) => CategoryTemplateModel.fromJson(json).toDomain(),
    );
  }

  static Map<String, dynamic> _entryJson(CategoryTemplateEntryDraft entry) => {
    'categoryId': entry.categoryId,
    'accountId': entry.accountId,
    'expectedAmount': entry.expectedAmount,
    'active': entry.active,
  };
}
