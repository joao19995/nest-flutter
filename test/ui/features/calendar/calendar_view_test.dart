import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/calendar/view_models/calendar_view_model.dart';
import 'package:nest/ui/features/calendar/views/calendar_view.dart';

import '../../../support/test_helpers.dart';

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Map<String, dynamic> _openMonth() => <String, dynamic>{
  'id': 'm1',
  'month': '2026-10',
  'closed': false,
  'entries': const <Object>[],
  'summary': {
    'month': '2026-10',
    'status': 'open',
    'planned': 1000,
    'actual': 800,
    'progressPct': 80,
    'over': false,
  },
  'settlement': null,
};

Future<CalendarViewModel> _pumpCalendar(
  WidgetTester tester, {
  Map<String, dynamic>? monthPlan,
}) async {
  final client = MockClient((request) async {
    if (request.url.path == '/api/events') {
      return jsonResponse(const [
        {
          'id': 'e1',
          'title': 'Consulta',
          'startsAt': '2026-10-15T12:00:00.000Z',
          'active': true,
        },
      ]);
    }
    if (request.url.path.startsWith('/api/months/')) {
      final plan = monthPlan;
      if (plan != null) {
        return jsonResponse(plan);
      }
      return jsonResponse(const {'error': 'Mês não encontrado.'}, status: 404);
    }
    return jsonResponse(const <Object>[]);
  });
  final apiClient = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  final viewModel = CalendarViewModel(
    eventsRepository: EventsRepository(client: apiClient),
    expensesRepository: ExpensesRepository(client: apiClient),
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
    expect(find.text('Balanço do mês'), findsOneWidget);
    expect(find.text('Sem plano · criar o mês'), findsOneWidget);
  });

  testWidgets('shows the open month balance in the marker', (tester) async {
    _setPhone(tester);
    await _pumpCalendar(tester, monthPlan: _openMonth());

    expect(find.text('Balanço do mês'), findsOneWidget);
    expect(find.textContaining('Por fechar'), findsOneWidget);
    expect(find.textContaining(AppFormatters.currency(800)), findsOneWidget);
  });

  testWidgets('selecting a day with an event shows it in the agenda', (
    tester,
  ) async {
    _setPhone(tester);
    await _pumpCalendar(tester);

    final day = DateTime.parse('2026-10-15T12:00:00.000Z').toLocal();
    await tester.tap(find.text('${day.day}'));
    await tester.pumpAndSettle();

    expect(
      find.text('1 evento · próximo às ${AppFormatters.time(day)}'),
      findsOneWidget,
    );
    expect(find.text('Consulta'), findsOneWidget);
  });
}
