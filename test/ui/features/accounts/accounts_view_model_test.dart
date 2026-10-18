import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/accounts_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/accounts/view_models/accounts_view_model.dart';

AccountsViewModel _viewModel(MockClient client) {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  return AccountsViewModel(
    accountsRepository: AccountsRepository(client: api),
    peopleRepository: PeopleRepository(client: api),
  );
}

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('load maps accounts and resolves the owner name', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/people') {
        return _json(const [
          {'id': 'p1', 'name': 'Ana', 'dailySpendingPercentage': 25},
        ]);
      }
      return _json(const [
        {'id': 'a1', 'name': 'Casa', 'ownerPersonId': null, 'active': true},
        {
          'id': 'a2',
          'name': 'Conta Ana',
          'ownerPersonId': 'p1',
          'active': true,
        },
      ]);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.accounts, hasLength(2));
    expect(viewModel.ownerName(viewModel.accounts.first), isNull);
    expect(viewModel.ownerName(viewModel.accounts.last), 'Ana');
  });

  test('delete is optimistic and restore brings the account back', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/people') {
        return _json(const <Object>[]);
      }
      if (request.method == 'DELETE') {
        return _json(const {'id': 'a1'});
      }
      if (request.url.path == '/api/accounts/a1/restore') {
        return _json(const {
          'id': 'a1',
          'name': 'Casa',
          'ownerPersonId': null,
          'active': true,
        });
      }
      return _json(const [
        {'id': 'a1', 'name': 'Casa', 'ownerPersonId': null, 'active': true},
      ]);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    final account = viewModel.accounts.single;

    expect(await viewModel.deleteAccount(account), isTrue);
    expect(viewModel.accounts, isEmpty);

    await viewModel.restoreAccount(account);
    expect(viewModel.accounts, hasLength(1));
  });

  test('reports a load failure without throwing', () async {
    final client = MockClient(
      (request) async => _json(const {'error': 'Falhou.'}, status: 500),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, 'Falhou.');
    expect(viewModel.isEmpty, isTrue);
  });
}
