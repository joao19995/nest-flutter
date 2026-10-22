import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/accounts_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';

import '../../support/test_helpers.dart';

AccountsRepository _repository(MockClient mock) => AccountsRepository(
  client: NestApiClient(
    httpClient: mock,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

void main() {
  test('fetchAccounts maps the list and can request inactive ones', () async {
    String? path;
    String? include;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        include = request.url.queryParameters['includeInactive'];
        return jsonResponse(const [
          {'id': 'a1', 'name': 'Conta', 'ownerPersonId': null, 'active': true},
        ]);
      }),
    );

    final accounts = await repository.fetchAccounts(includeInactive: true);

    expect(path, '/api/accounts');
    expect(include, 'true');
    expect(accounts.single.isJoint, isTrue);
  });

  test(
    'createAccount always sends ownerPersonId, null for a joint account',
    () async {
      String? method;
      Map<String, dynamic>? body;
      final repository = _repository(
        MockClient((request) async {
          method = request.method;
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse(const {
            'id': 'a1',
            'name': 'Casa',
            'ownerPersonId': null,
            'active': true,
          }, status: 201);
        }),
      );

      final account = await repository.createAccount(name: 'Casa');

      expect(method, 'POST');
      expect(body?['name'], 'Casa');
      expect(body?.containsKey('ownerPersonId'), isTrue);
      expect(body?['ownerPersonId'], isNull);
      expect(account.name, 'Casa');
    },
  );

  test('updateAccount sends the name and owner to the id path', () async {
    String? path;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(const {
          'id': 'a1',
          'name': 'Casa',
          'ownerPersonId': 'p1',
          'active': true,
        });
      }),
    );

    await repository.updateAccount('a1', name: 'Casa', ownerPersonId: 'p1');

    expect(path, '/api/accounts/a1');
    expect(body?['ownerPersonId'], 'p1');
  });

  test('delete and restore hit the expected routes', () async {
    final calls = <String>[];
    final repository = _repository(
      MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'DELETE') {
          return jsonResponse(const {'id': 'a1'});
        }
        return jsonResponse(const {
          'id': 'a1',
          'name': 'Casa',
          'ownerPersonId': null,
          'active': true,
        });
      }),
    );

    await repository.deleteAccount('a1');
    await repository.restoreAccount('a1');

    expect(calls, ['DELETE /api/accounts/a1', 'POST /api/accounts/a1/restore']);
  });
}
