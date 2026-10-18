import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/expenses/view_models/month_detail_view_model.dart';

MonthDetailViewModel _viewModel(
  MockClient client, {
  String month = '2026-02',
}) => MonthDetailViewModel(
  expensesRepository: ExpensesRepository(
    client: NestApiClient(
      httpClient: client,
      baseUrl: 'http://test.local',
      apiKey: '',
    ),
  ),
  month: month,
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _month({
  String id = 'm2',
  bool closed = false,
  double actual = 0,
}) => <String, dynamic>{
  'id': id,
  'month': '2026-02',
  'templateId': 't1',
  'closed': closed,
  'entries': [
    {
      'id': 'e1',
      'categoryName': 'Casa',
      'accountName': 'João',
      'planned': 450,
      'actual': actual,
    },
  ],
  'settlement': null,
};

void main() {
  test('load exposes the plan', () async {
    final client = MockClient(
      (request) async => request.url.path == '/api/months/2026-02'
          ? _json(_month())
          : _json(<Object>[], status: 404),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.plan?.id, 'm2');
    expect(viewModel.plan?.planned, 450);
  });

  test('a 404 month is a null plan, not an error', () async {
    var createsCalled = false;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _json(const {'error': 'Não existe.'}, status: 404);
      }
      createsCalled = true;
      return _json(_month(id: 'm9'), status: 201);
    });

    final viewModel = _viewModel(client, month: '2026-10');
    await viewModel.load();

    expect(viewModel.plan, isNull);
    expect(viewModel.errorMessage, isNull);

    await viewModel.createMonth();
    expect(createsCalled, isTrue);
    expect(viewModel.plan?.id, 'm9');
  });

  test('createMonth posts the month and adopts the plan', () async {
    Object? body;
    final client = MockClient((request) async {
      if (request.method == 'POST' && request.url.path == '/api/months') {
        body = jsonDecode(request.body);
        return _json(_month(id: 'm9'), status: 201);
      }
      return _json(const {'error': 'Não existe.'}, status: 404);
    });

    final viewModel = _viewModel(client, month: '2026-10');
    await viewModel.load();
    await viewModel.createMonth();

    expect((body as Map<String, dynamic>)['month'], '2026-10');
    expect(viewModel.plan?.id, 'm9');
    expect(viewModel.isBusy, isFalse);
    expect(viewModel.actionError, isNull);
  });

  test('updateEntryActual patches the entry and refreshes the plan', () async {
    String? patchedPath;
    Object? body;
    final client = MockClient((request) async {
      if (request.method == 'PATCH') {
        patchedPath = request.url.path;
        body = jsonDecode(request.body);
        return _json(_month(actual: 500));
      }
      return _json(_month());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.updateEntryActual('e1', 500);

    expect(patchedPath, '/api/months/m2/entries/e1');
    expect((body as Map<String, dynamic>)['actual'], 500);
    expect(viewModel.plan?.actual, 500);
    expect(viewModel.isBusy, isFalse);
  });

  test('a failed write records the action error', () async {
    final client = MockClient((request) async {
      if (request.method == 'PATCH') {
        return _json(const {'error': 'Não guardou.'}, status: 500);
      }
      return _json(_month());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.updateEntryActual('e1', 500);

    expect(viewModel.actionError, 'Não guardou.');
    expect(viewModel.isBusy, isFalse);
  });
}
