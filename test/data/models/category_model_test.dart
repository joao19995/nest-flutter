import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/category_model.dart';
import 'package:nest/domain/models/category.dart';

void main() {
  group('CategoryModel', () {
    test('maps a fixed category', () {
      final Category category = CategoryModel.fromJson(const {
        'id': 'c1',
        'name': 'Renda',
        'type': 'FIXED',
        'active': true,
      }).toDomain();

      expect(category.id, 'c1');
      expect(category.name, 'Renda');
      expect(category.type, CategoryType.fixed);
      expect(category.isFixed, isTrue);
      expect(category.active, isTrue);
    });

    test('maps a variable category', () {
      final category = CategoryModel.fromJson(const {
        'id': 'c2',
        'name': 'Supermercado',
        'type': 'VARIABLE',
        'active': false,
      }).toDomain();

      expect(category.type, CategoryType.variable);
      expect(category.isFixed, isFalse);
      expect(category.active, isFalse);
    });
  });
}
