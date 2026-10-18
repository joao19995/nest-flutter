import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/account_model.dart';
import 'package:nest/domain/models/account.dart';

void main() {
  group('AccountModel', () {
    test('maps a joint account', () {
      final Account account = AccountModel.fromJson(const {
        'id': 'a1',
        'name': 'Conta conjunta',
        'ownerPersonId': null,
        'active': true,
      }).toDomain();

      expect(account.id, 'a1');
      expect(account.name, 'Conta conjunta');
      expect(account.ownerPersonId, isNull);
      expect(account.isJoint, isTrue);
      expect(account.active, isTrue);
    });

    test('maps a personal, inactive account', () {
      final account = AccountModel.fromJson(const {
        'id': 'a2',
        'name': 'Conta Ana',
        'ownerPersonId': 'p1',
        'active': false,
      }).toDomain();

      expect(account.ownerPersonId, 'p1');
      expect(account.isJoint, isFalse);
      expect(account.active, isFalse);
    });

    test('defaults a missing active flag to true', () {
      final account = AccountModel.fromJson(const {
        'id': 'a3',
        'name': 'Conta',
        'ownerPersonId': null,
      }).toDomain();

      expect(account.active, isTrue);
    });
  });
}
