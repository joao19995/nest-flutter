import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:nest/ui/features/dashboard/views/dashboard_view.dart';
import 'package:nest/ui/features/finances/views/month_transfers_view.dart';

import '../../../support/test_helpers.dart';

const String _month = '2026-10';

Map<String, dynamic> _yearSummary(
  int year,
  String month, {
  bool closed = false,
}) => {
  'year': year,
  'planned': 1000,
  'actual': closed ? 1000 : 500,
  'diff': closed ? 0 : -500,
  'diffPct': closed ? 0 : -50,
  'over': false,
  'hasData': true,
  'remainingMonths': 2,
  'perRemainingMonth': 0,
  'months': [
    {
      'month': month,
      'status': closed ? 'closed' : 'open',
      'planned': 1000,
      'actual': closed ? 1000 : 500,
      'progressPct': closed ? 100 : 50,
      'over': false,
      'filledEntries': closed ? 10 : 5,
      'totalEntries': 10,
    },
  ],
};

Map<String, dynamic> _goalMonth(String month, {bool closed = false}) => {
  'month': month,
  'planId': closed ? 'p1' : null,
  'closed': closed,
  'availableAmount': closed ? 1000 : 0,
  'allocations': closed
      ? [
          {
            'goalId': 'g1',
            'goalName': 'Viagem',
            'planned': 1000,
            'actual': 1000,
          },
        ]
      : <Object>[],
  'quotas': <Object>[],
};

Map<String, dynamic> _openGoalMonth(String month) => {
  'month': month,
  'planId': 'p1',
  'closed': false,
  'availableAmount': 1000,
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 1000, 'actual': 0},
  ],
  'quotas': <Object>[],
};

Map<String, dynamic> _monthPlan(String month, {bool closed = false}) => {
  'id': 'm1',
  'month': month,
  'templateId': 't1',
  'closed': closed,
  'entries': <Object>[],
  'settlement': null,
  'summary': {
    'month': month,
    'status': closed ? 'closed' : 'open',
    'planned': 1000,
    'actual': closed ? 1000 : 500,
    'progressPct': closed ? 100 : 50,
    'over': false,
    'filledEntries': closed ? 10 : 5,
    'totalEntries': 10,
  },
};

MockClient _client({
  bool failEvents = false,
  List<Object>? events,
  bool closed = false,
  bool? goalsClosed,
}) {
  final year = int.parse(_month.substring(0, 4));
  return MockClient((request) async {
    if (request.url.path == '/api/months/$_month') {
      return jsonResponse(_monthPlan(_month, closed: closed));
    }
    if (failEvents && request.url.path == '/api/events') {
      return jsonResponse(const {
        'error': 'Eventos indisponíveis',
      }, status: 500);
    }
    if (request.url.path.startsWith('/api/goal-plan/')) {
      final month = request.url.path.split('/').last;
      if (month != _month) {
        return jsonResponse(_goalMonth(month));
      }
      if (goalsClosed == false) {
        return jsonResponse(_openGoalMonth(month));
      }
      return jsonResponse(_goalMonth(month, closed: goalsClosed ?? closed));
    }
    switch (request.url.path) {
      case '/api/months/summary':
        return jsonResponse(_yearSummary(year, _month, closed: closed));
      case '/api/events':
        return jsonResponse(events ?? const <Object>[]);
      default:
        return jsonResponse(const {'error': 'not found'}, status: 404);
    }
  });
}

/// Builds the repositories against [client] and loads the dashboard once.
Future<DashboardViewModel> _loadedViewModel(
  MockClient client, {
  DateTime? now,
}) async {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  final viewModel = DashboardViewModel(
    expensesRepository: ExpensesRepository(client: api),
    goalsRepository: GoalsRepository(client: api),
    eventsRepository: EventsRepository(client: api),
    now: now ?? DateTime(2026, 10, 2, 12),
  );
  await viewModel.load();
  return viewModel;
}

/// Pumps the dashboard with an already loaded [vm].
Future<void> _pump(
  WidgetTester tester,
  DashboardViewModel vm, {
  VoidCallback? onOpenMonthTab,
  ValueChanged<String>? onOpenMonth,
}) async {
  final dependencies = testDependencies(
    MockClient((_) async => jsonResponse(const <Object>[])),
  );
  await tester.pumpWidget(
    wrapWithDependencies(
      dependencies,
      DashboardView(
        viewModel: vm,
        onOpenMonthTab: onOpenMonthTab,
        onOpenMonth: onOpenMonth,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const previous = '2026-09';

  testWidgets('opens with the month hero and its plan state', (tester) async {
    setPhoneSize(tester);
    final viewModel = await _loadedViewModel(_client());
    await _pump(tester, viewModel);

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Balanço do mês'), findsOneWidget);
    expect(
      find.text('${AppFormatters.monthName(_month)} por fechar'),
      findsOneWidget,
    );
    expect(find.text('Despesas'), findsOneWidget);
    expect(find.text('Objetivos'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'dashboard-month-$_month');
    expect(find.textContaining(AppFormatters.currency(500)), findsOneWidget);
    expect(find.text(AppFormatters.percentage(50)), findsOneWidget);
    expect(find.text('-50%'), findsOneWidget);
    expect(find.text('Sem plano'), findsNothing);
    expect(find.text('Objetivos do ano'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('steps the hero to a month without a plan', (tester) async {
    setPhoneSize(tester);
    final viewModel = await _loadedViewModel(_client());
    await _pump(tester, viewModel);

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();

    expect(find.text(AppFormatters.monthShort(previous)), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the close wizard from the action chip', (tester) async {
    setPhoneSize(tester);
    String? opened;
    final viewModel = await _loadedViewModel(_client());
    await _pump(tester, viewModel, onOpenMonth: (value) => opened = value);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(opened, isNull);
    expect(
      find.text('Fechar ${AppFormatters.monthName(_month)}'),
      findsOneWidget,
    );
    expect(find.text('Despesas'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not open the expenses when the hero is tapped', (
    tester,
  ) async {
    setPhoneSize(tester);
    String? opened;
    final viewModel = await _loadedViewModel(_client());
    await _pump(tester, viewModel, onOpenMonth: (value) => opened = value);

    await tester.tap(find.text('Balanço do mês'));
    expect(opened, isNull);
  });

  testWidgets('opens the final summary from a closed month', (tester) async {
    setPhoneSize(tester);
    final viewModel = await _loadedViewModel(_client(closed: true));
    await _pump(tester, viewModel);

    expect(find.text('Ver resumo'), findsOneWidget);

    await tester.tap(find.text('Ver resumo'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthTransfersView), findsOneWidget);
  });

  testWidgets('keeps the hero when the events section fails', (tester) async {
    setPhoneSize(tester);
    final viewModel = await _loadedViewModel(_client(failEvents: true));
    await _pump(tester, viewModel);

    expect(find.text('Balanço do mês'), findsOneWidget);
    expect(find.textContaining(AppFormatters.currency(500)), findsOneWidget);
    expect(find.text('Eventos indisponíveis'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('groups the upcoming events by day', (tester) async {
    setPhoneSize(tester);
    final midday = DateTime(2026, 10, 2, 12);
    final tomorrow = midday.add(const Duration(days: 1));
    final events = [
      {
        'id': 'e1',
        'title': 'Almoço',
        'startsAt': midday.toUtc().toIso8601String(),
        'active': true,
      },
      {
        'id': 'e2',
        'title': 'Jantar',
        'startsAt': tomorrow.toUtc().toIso8601String(),
        'active': true,
      },
    ];
    final viewModel = await _loadedViewModel(_client(events: events));
    await _pump(tester, viewModel);

    final eventsCard = find.ancestor(
      of: find.text('Hoje e próximos'),
      matching: find.byType(AppCard),
    );
    expect(
      find.descendant(of: eventsCard, matching: find.text('Hoje')),
      findsOneWidget,
    );
    expect(find.text('Amanhã'), findsOneWidget);
    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('Jantar'), findsOneWidget);
  });

  testWidgets('shows the full hero on day 2 of an open month', (tester) async {
    setPhoneSize(tester);
    final viewModel = await _loadedViewModel(_client());
    await _pump(tester, viewModel);

    expect(find.text('Balanço do mês'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'dashboard-month-$_month',
      ),
      findsOneWidget,
    );
  });

  testWidgets('focuses the previous open month on day 2', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/2026-09') {
        return jsonResponse(_monthPlan('2026-09'));
      }
      if (request.url.path == '/api/months/2026-10') {
        return jsonResponse(_monthPlan('2026-10'));
      }
      switch (request.url.path) {
        case '/api/months/summary':
          return jsonResponse({
            'year': 2026,
            'planned': 2000,
            'actual': 1000,
            'diff': -1000,
            'diffPct': -50,
            'over': false,
            'hasData': true,
            'remainingMonths': 2,
            'perRemainingMonth': 0,
            'months': [
              {
                'month': '2026-09',
                'status': 'open',
                'planned': 1000,
                'actual': 500,
                'progressPct': 50,
                'over': false,
                'filledEntries': 5,
                'totalEntries': 10,
              },
              {
                'month': '2026-10',
                'status': 'open',
                'planned': 1000,
                'actual': 500,
                'progressPct': 50,
                'over': false,
                'filledEntries': 5,
                'totalEntries': 10,
              },
            ],
          });
        case '/api/events':
          return jsonResponse(const <Object>[]);
        case '/api/goal-plan/2026-09':
          return jsonResponse(_goalMonth('2026-09'));
        case '/api/goal-plan/2026-10':
          return jsonResponse(_goalMonth('2026-10'));
        default:
          return jsonResponse(const {'error': 'not found'}, status: 404);
      }
    });
    final viewModel = await _loadedViewModel(client);
    await _pump(tester, viewModel);

    expect(find.text('FECHAR SETEMBRO'), findsOneWidget);
    expect(find.text('Setembro por fechar'), findsOneWidget);
    expect(find.text('O mês anterior ainda não está fechado.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'dashboard-month-2026-09',
      ),
      findsOneWidget,
    );

    // The focused month's balance reminder is not repeated as an alert row.
    expect(find.text('É altura de fazer o balanço de Setembro'), findsNothing);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Fechar Setembro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapses to one line on day 15 of a closed month', (
    tester,
  ) async {
    setPhoneSize(tester);
    var opens = 0;
    final viewModel = await _loadedViewModel(
      _client(closed: true),
      now: DateTime(2026, 10, 15, 12),
    );
    await _pump(tester, viewModel, onOpenMonthTab: () => opens++);

    expect(find.byType(Hero), findsNothing);
    expect(
      find.text('Outubro · Despesas fechadas · Objetivos fechados'),
      findsOneWidget,
    );

    await tester.tap(
      find.text('Outubro · Despesas fechadas · Objetivos fechados'),
    );
    await tester.pumpAndSettle();

    expect(opens, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the hero when stepping to a closed month', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/months/2026-09':
          return jsonResponse(_monthPlan('2026-09', closed: true));
        case '/api/months/2026-10':
          return jsonResponse(_monthPlan('2026-10'));
        case '/api/months/summary':
          return jsonResponse(_yearSummary(2026, _month));
        case '/api/goal-plan/2026-09':
          return jsonResponse(_goalMonth('2026-09', closed: true));
        case '/api/goal-plan/2026-10':
          return jsonResponse(_goalMonth('2026-10'));
        case '/api/events':
          return jsonResponse(const <Object>[]);
        default:
          return jsonResponse(const {'error': 'not found'}, status: 404);
      }
    });
    final viewModel = await _loadedViewModel(
      client,
      now: DateTime(2026, 10, 15, 12),
    );
    await _pump(tester, viewModel);

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();

    expect(find.byType(Hero), findsOneWidget);
    expect(
      find.textContaining('Despesas fechadas · Objetivos fechados'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the hero when expenses are closed but goals are open', (
    tester,
  ) async {
    setPhoneSize(tester);
    final viewModel = await _loadedViewModel(
      _client(closed: true, goalsClosed: false),
      now: DateTime(2026, 10, 15, 12),
    );
    await _pump(tester, viewModel);

    expect(find.byType(Hero), findsOneWidget);
    expect(find.text('Outubro por fechar'), findsOneWidget);
    expect(
      find.textContaining('Despesas fechadas · Objetivos fechados'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('orders events, tasks and the month card', (tester) async {
    setPhoneSize(tester);
    final viewModel = await _loadedViewModel(_client());
    await _pump(tester, viewModel);

    final events = tester.getTopLeft(find.text('Hoje e próximos')).dy;
    final tasks = tester.getTopLeft(find.text('Tarefas pendentes (0)')).dy;
    final monthCard = tester.getTopLeft(find.byType(Hero)).dy;

    expect(events, lessThan(tasks));
    expect(tasks, lessThan(monthCard));
  });

  testWidgets('survives a larger system text scale', (tester) async {
    setPhoneSize(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final viewModel = await _loadedViewModel(_client());
    await _pump(tester, viewModel);

    expect(tester.takeException(), isNull);
  });
}
