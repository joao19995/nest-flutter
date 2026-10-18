import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/category_template_model.dart';
import 'package:nest/domain/models/category.dart';
import 'package:nest/domain/models/category_template.dart';

void main() {
  group('CategoryTemplateModel', () {
    test('maps a version with its hydrated entries', () {
      final CategoryTemplate template = CategoryTemplateModel.fromJson(const {
        'id': 't1',
        'validFrom': '2026-01',
        'entries': [
          {
            'categoryId': 'c1',
            'accountId': 'a1',
            'expectedAmount': 800,
            'active': true,
            'categoryName': 'Renda',
            'categoryType': 'FIXED',
            'categoryActive': true,
            'accountName': 'Conjunta',
            'accountActive': true,
          },
        ],
      }).toDomain();

      expect(template.validFrom, '2026-01');
      expect(template.entries, hasLength(1));
      final entry = template.entries.single;
      expect(entry.categoryId, 'c1');
      expect(entry.accountId, 'a1');
      expect(entry.expectedAmount, 800);
      expect(entry.active, isTrue);
      expect(entry.categoryType, CategoryType.fixed);
      expect(entry.accountName, 'Conjunta');
    });

    test('tolerates a missing entries list', () {
      final template = CategoryTemplateModel.fromJson(const {
        'id': 't1',
        'validFrom': '2026-01',
      }).toDomain();

      expect(template.entries, isEmpty);
    });
  });
}
