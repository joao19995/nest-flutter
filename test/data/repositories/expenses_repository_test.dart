import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';

ExpensesRepository _repository(MockClient mock) => ExpensesRepository(
  client: NestApiClient(
    httpClient: mock,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('fetchMonth reads the month path and returns null on a 404', () async {
    String? path;
    final present = _repository(
      MockClient((request) async {
        path = request.url.path;
        return _json(const {
          'id': 'm1',
          'month': '2026-01',
          'closed': false,
          'entries': <Object>[],
          'settlement': null,
        });
      }),
    );
    expect((await present.fetchMonth('2026-01'))?.id, 'm1');
    expect(path, '/api/months/2026-01');

    final missing = _repository(
      MockClient(
        (request) async => _json(const {'error': 'Não existe.'}, status: 404),
      ),
    );
    expect(await missing.fetchMonth('2026-02'), isNull);
  });

  test('fetchMonth rethrows non-404 failures', () async {
    final repository = _repository(
      MockClient(
        (request) async => _json(const {'error': 'Falhou.'}, status: 500),
      ),
    );

    await expectLater(
      repository.fetchMonth('2026-01'),
      throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'statusCode', 500)),
    );
  });

  test('fetchYearSummary throws ApiFailure on an unexpected payload', () async {
    final repository = _repository(
      MockClient((request) async => _json(const <Object>[])),
    );

    await expectLater(
      repository.fetchYearSummary(2026),
      throwsA(isA<ApiFailure>()),
    );
  });

  test('updateEntryActual patches the entry with the new amount', () async {
    String? path;
    Object? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body);
        return _json(const {
          'id': 'm1',
          'month': '2026-01',
          'closed': false,
          'entries': <Object>[],
          'settlement': null,
        });
      }),
    );

    await repository.updateEntryActual('m1', 'e1', 500);

    expect(path, '/api/months/m1/entries/e1');
    expect((body as Map<String, dynamic>)['actual'], 500);
  });
}
