import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';

import '../../support/test_helpers.dart';

EventsRepository _repository(MockClient client) => EventsRepository(
  client: NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

Map<String, dynamic> _event() => {
  'id': 'e1',
  'title': 'Jantar',
  'startsAt': '2026-10-20T19:30:00.000Z',
  'active': true,
};

void main() {
  test('fetchEvents sends the date range and maps the events', () async {
    Uri? uri;
    final events =
        await _repository(
          MockClient((request) async {
            uri = request.url;
            return jsonResponse([_event()]);
          }),
        ).fetchEvents(
          from: DateTime(2026, 10),
          to: DateTime(2026, 10, 31),
          includeInactive: true,
        );

    expect(events.single.title, 'Jantar');
    expect(uri?.queryParameters['from'], '2026-10-01');
    expect(uri?.queryParameters['to'], '2026-10-31');
    expect(uri?.queryParameters['includeInactive'], 'true');
  });

  test('writes hit the expected routes', () async {
    final paths = <String>[];
    final repository = _repository(
      MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        return jsonResponse(_event());
      }),
    );

    await repository.createEvent(
      title: 'Jantar',
      startsAt: DateTime.utc(2026, 10, 20, 19, 30),
    );
    await repository.updateEvent(
      'e1',
      title: 'Jantar',
      startsAt: DateTime.utc(2026, 10, 20, 19, 30),
    );
    await repository.deleteEvent('e1');
    await repository.restoreEvent('e1');

    expect(paths, [
      'POST /api/events',
      'PUT /api/events/e1',
      'DELETE /api/events/e1',
      'POST /api/events/e1/restore',
    ]);
  });

  test('fails on an invalid list payload', () async {
    await expectLater(
      _repository(
        MockClient((request) async => jsonResponse(const {'not': 'a list'})),
      ).fetchEvents(from: DateTime(2026), to: DateTime(2027)),
      throwsA(isA<ApiFailure>()),
    );
  });
}
