import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';

NestApiClient _client(MockClient mock, {String apiKey = 'secret'}) =>
    NestApiClient(
      httpClient: mock,
      baseUrl: 'http://test.local',
      apiKey: apiKey,
    );

void main() {
  test('sends the bearer key and decodes a JSON body', () async {
    String? authorization;
    final client = _client(
      MockClient((request) async {
        authorization = request.headers['Authorization'];
        return http.Response(
          jsonEncode(const {'ok': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final data = await client.get('/api/health');

    expect(authorization, 'Bearer secret');
    expect((data as Map<String, dynamic>)['ok'], isTrue);
  });

  test('omits the authorization header when no key is set', () async {
    var hasAuth = true;
    final client = _client(
      MockClient((request) async {
        hasAuth = request.headers.containsKey('Authorization');
        return http.Response('{}', 200);
      }),
      apiKey: '',
    );

    await client.get('/api/health');

    expect(hasAuth, isFalse);
  });

  test('sends a JSON body on post', () async {
    Object? body;
    final client = _client(
      MockClient((request) async {
        body = jsonDecode(request.body);
        return http.Response('{}', 200);
      }),
    );

    await client.post('/api/months', const {'month': '2026-01'});

    expect((body as Map<String, dynamic>)['month'], '2026-01');
  });

  test('maps a non-2xx response with an error field to ApiFailure', () async {
    final client = _client(
      MockClient(
        (request) async => http.Response(
          jsonEncode(const {'error': 'Chave inválida.'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    await expectLater(
      client.get('/api/goals'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.message, 'message', 'Chave inválida.')
            .having((f) => f.statusCode, 'statusCode', 401)
            .having((f) => f.isUnauthorized, 'isUnauthorized', isTrue),
      ),
    );
  });

  test('falls back to a generic message without an error field', () async {
    final client = _client(
      MockClient((request) async => http.Response('', 500)),
    );

    await expectLater(
      client.get('/api/goals'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.message, 'message', 'Erro 500.')
            .having((f) => f.statusCode, 'statusCode', 500),
      ),
    );
  });

  test('returns null for an empty success body', () async {
    final client = _client(
      MockClient((request) async => http.Response('', 200)),
    );

    expect(await client.delete('/api/events/e1'), isNull);
  });

  test('normalises a transport failure to ApiFailure.network', () async {
    final client = _client(
      MockClient((request) async => throw Exception('boom')),
    );

    await expectLater(client.get('/api/health'), throwsA(isA<ApiFailure>()));
  });

  test('invokes onUnauthorized when the API answers 401', () async {
    var calls = 0;
    final client = _client(
      MockClient((request) async => http.Response('', 401)),
    )..onUnauthorized = () => calls++;

    await expectLater(client.get('/api/goals'), throwsA(isA<ApiFailure>()));

    expect(calls, 1);
  });

  test('does not invoke onUnauthorized for other failures', () async {
    var calls = 0;
    final client = _client(
      MockClient((request) async => http.Response('', 500)),
    )..onUnauthorized = () => calls++;

    await expectLater(client.get('/api/goals'), throwsA(isA<ApiFailure>()));

    expect(calls, 0);
  });

  testWidgets('maps a slow response to ApiFailure.timeout', (tester) async {
    final client = _client(
      MockClient((request) => Completer<http.Response>().future),
    );
    final request = client.get('/api/health');
    final expectation = expectLater(
      request,
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          'O servidor demorou demasiado a responder. Tenta de novo.',
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 16));
    await expectation;
  });
}
