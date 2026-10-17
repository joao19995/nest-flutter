import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/calendar/view_models/calendar_view_model.dart';
import 'package:nest/ui/features/calendar/views/calendar_view.dart';

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<CalendarViewModel> _pumpCalendar(WidgetTester tester) async {
  final client = MockClient((request) async {
    if (request.url.path == '/api/events') {
      return _json(const [
        {
          'id': 'e1',
          'title': 'Consulta',
          'startsAt': '2026-10-15T12:00:00.000Z',
          'active': true,
        },
      ]);
    }
    return _json(const <Object>[]);
  });
  final viewModel = CalendarViewModel(
    eventsRepository: EventsRepository(
      client: NestApiClient(
        httpClient: client,
        baseUrl: 'http://test.local',
        apiKey: '',
      ),
    ),
    today: DateTime(2026, 10, 20),
  );
  await viewModel.load();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CalendarView(viewModel: viewModel),
    ),
  );
  await tester.pumpAndSettle();
  return viewModel;
}

void main() {
  testWidgets('renders the month grid and an empty agenda for today', (
    tester,
  ) async {
    _setPhone(tester);
    await _pumpCalendar(tester);

    expect(find.text('Calendário'), findsOneWidget);
    expect(find.text('Outubro 2026'), findsOneWidget);
    expect(find.text('Sem eventos'), findsOneWidget);
    expect(find.text('Nada agendado para este dia.'), findsOneWidget);
  });

  testWidgets('selecting a day with an event shows it in the agenda', (
    tester,
  ) async {
    _setPhone(tester);
    await _pumpCalendar(tester);

    final day = DateTime.parse('2026-10-15T12:00:00.000Z').toLocal();
    await tester.tap(find.text('${day.day}'));
    await tester.pumpAndSettle();

    expect(find.text('1 evento'), findsOneWidget);
    expect(find.text('Consulta'), findsOneWidget);
  });
}
