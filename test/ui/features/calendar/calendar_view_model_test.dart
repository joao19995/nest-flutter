import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/calendar/view_models/calendar_view_model.dart';

import '../../../support/test_helpers.dart';

CalendarViewModel _viewModel(MockClient client) => CalendarViewModel(
  eventsRepository: EventsRepository(
    client: NestApiClient(
      httpClient: client,
      baseUrl: 'http://test.local',
      apiKey: '',
    ),
  ),
  today: DateTime(2026, 10, 20),
);

const _octoberEvent = {
  'id': 'e1',
  'title': 'Consulta',
  'startsAt': '2026-10-15T12:00:00.000Z',
  'active': true,
};

void main() {
  group('buildGridDays', () {
    test('starts on the Monday on or before the first of the month', () {
      final days = CalendarViewModel.buildGridDays(DateTime(2026, 10));

      expect(days.first, DateTime(2026, 9, 28));
      expect(days.first.weekday, DateTime.monday);
      expect(days.length % 7, 0);
      expect(days.last, DateTime(2026, 11));
    });

    test('covers every day of the month', () {
      final days = CalendarViewModel.buildGridDays(DateTime(2026, 2));

      expect(days.contains(DateTime(2026, 2)), isTrue);
      expect(days.contains(DateTime(2026, 2, 28)), isTrue);
    });
  });

  test('load fetches the padded grid window and groups by day', () async {
    Uri? requestUri;
    final client = MockClient((request) async {
      if (request.url.path == '/api/events' && request.method == 'GET') {
        requestUri = request.url;
        return jsonResponse(const [_octoberEvent]);
      }
      return jsonResponse(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(requestUri?.queryParameters['from'], '2026-09-27');
    expect(requestUri?.queryParameters['to'], '2026-11-02');
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.monthEventCount, 1);

    final localDay = DateTime.parse('2026-10-15T12:00:00.000Z').toLocal();
    expect(viewModel.eventsFor(localDay).single.id, 'e1');
  });

  test('create posts the instant as UTC and inserts the event', () async {
    Object? body;
    final client = MockClient((request) async {
      if (request.url.path == '/api/events' && request.method == 'GET') {
        return jsonResponse(const <Object>[]);
      }
      if (request.url.path == '/api/events' && request.method == 'POST') {
        body = jsonDecode(request.body);
        return jsonResponse(const {
          'id': 'e2',
          'title': 'Jantar',
          'startsAt': '2026-10-22T18:00:00.000Z',
          'active': true,
        }, status: 201);
      }
      return jsonResponse(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    final ok = await viewModel.createEvent(
      title: 'Jantar',
      startsAt: DateTime(2026, 10, 22, 19),
    );

    expect(ok, isTrue);
    final sent = body! as Map<String, dynamic>;
    expect(sent['title'], 'Jantar');
    expect(
      DateTime.parse(sent['startsAt'] as String),
      DateTime(2026, 10, 22, 19).toUtc(),
    );
    expect(viewModel.monthEventCount, 1);
  });

  test('delete is optimistic and can be undone with restore', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/api/events' && request.method == 'GET') {
        return jsonResponse(const [_octoberEvent]);
      }
      paths.add('${request.method} ${request.url.path}');
      return jsonResponse(const {'id': 'e1'});
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    final day = DateTime.parse('2026-10-15T12:00:00.000Z').toLocal();
    final event = viewModel.eventsFor(day).single;

    final deleted = await viewModel.deleteEvent(event);
    expect(deleted, isTrue);
    expect(viewModel.eventsFor(day), isEmpty);

    await viewModel.restoreEvent(event);
    expect(viewModel.eventsFor(day).single.id, 'e1');
    expect(paths, ['DELETE /api/events/e1', 'POST /api/events/e1/restore']);
  });

  test('selectDay in another month switches the visible month', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/events') {
        return jsonResponse(const <Object>[]);
      }
      return jsonResponse(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    expect(viewModel.visibleMonth, DateTime(2026, 10));

    await viewModel.selectDay(DateTime(2026, 11, 3));

    expect(viewModel.visibleMonth, DateTime(2026, 11));
    expect(viewModel.selectedDay, DateTime(2026, 11, 3));
  });
}
