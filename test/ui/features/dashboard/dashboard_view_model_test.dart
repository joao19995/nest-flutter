import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/features/dashboard/view_models/dashboard_view_model.dart';

import '../../../support/test_helpers.dart';

Map<String, dynamic> _yearSummary() => const {
  'year': 2026,
  'planned': 0,
  'actual': 0,
  'diff': 0,
  'diffPct': 0,
  'over': false,
  'remainingMonths': 2,
  'perRemainingMonth': 0,
  'hasData': true,
  'months': [
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
    {
      'month': '2026-11',
      'status': 'missing',
      'planned': 0,
      'actual': 0,
      'progressPct': 0,
      'over': false,
      'filledEntries': 0,
      'totalEntries': 0,
    },
  ],
};

List<Object> _events() => const [
  {
    'id': 'e1',
    'title': 'Consulta',
    'startsAt': '2026-10-18T09:30:00.000Z',
    'active': true,
  },
  {
    'id': 'e2',
    'title': 'Jantar',
    'startsAt': '2026-10-18T19:00:00.000Z',
    'active': true,
  },
];

Map<String, dynamic> _goalYear() => const {
  'plans': [
    {
      'id': 'p1',
      'month': '2026-01',
      'availableAmount': 1725,
      'closed': true,
      'allocations': [
        {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 800, 'actual': 800},
        {'goalId': 'g2', 'goalName': 'Carro', 'planned': 925, 'actual': 925},
      ],
    },
  ],
  'funding': {
    'year': 2026,
    'annualTotal': 20000,
    'months': [
      {
        'month': '2026-01',
        'incomeNormal': 4500,
        'bonus': 0,
        'dailyAllowance': 1125,
        'contributionRequired': 1335,
        'available': 2040,
      },
    ],
  },
};

List<Object> _goals() => const [
  {'id': 'g1', 'name': 'Viagem', 'active': true},
  {'id': 'g2', 'name': 'Carro', 'active': true},
];

Map<String, dynamic> _template() => const {
  'id': 't1',
  'validFrom': '2026-01',
  'annualTotal': 20000,
  'entries': [
    {'goalId': 'g1', 'percentage': 20, 'budget': 800},
    {'goalId': 'g2', 'percentage': 80, 'budget': 4000},
  ],
};

Map<String, dynamic> _month() => const {
  'id': 'm1',
  'month': '2026-10',
  'templateId': 't1',
  'closed': true,
  'entries': <Object>[],
  'settlement': null,
  'summary': {
    'month': '2026-10',
    'status': 'open',
    'planned': 1500,
    'actual': 1240,
    'progressPct': 82.67,
    'over': false,
    'filledEntries': 5,
    'totalEntries': 10,
  },
};

DashboardViewModel _viewModel(
  MockClient client, {
  DateTime? now,
  DateTime Function()? clock,
}) {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  return DashboardViewModel(
    expensesRepository: ExpensesRepository(client: api),
    goalsRepository: GoalsRepository(client: api),
    eventsRepository: EventsRepository(client: api),
    now: now ?? DateTime(2026, 10, 18, 15),
    clock: clock,
  );
}

MockClient _client({bool failEvents = false}) => MockClient((request) async {
  if (failEvents && request.url.path == '/api/events') {
    return jsonResponse(const {'error': 'Eventos indisponíveis'}, status: 500);
  }
  switch (request.url.path) {
    case '/api/months/summary':
      return jsonResponse(_yearSummary());
    case '/api/events':
      return jsonResponse(_events());
    case '/api/goal-plan':
      return jsonResponse(_goalYear());
    case '/api/goals':
      return jsonResponse(_goals());
    case '/api/goal-templates/applicable':
      return jsonResponse({'template': _template()});
    case '/api/months/2026-10':
      return jsonResponse(_month());
    default:
      return jsonResponse(const <Object>[], status: 404);
  }
});

Map<String, dynamic> _yearSummaryFor(int year) => {
  'year': year,
  'planned': 0,
  'actual': 0,
  'diff': 0,
  'diffPct': 0,
  'over': false,
  'remainingMonths': 0,
  'perRemainingMonth': 0,
  'hasData': true,
  'months': [
    {
      'month': '$year-01',
      'status': 'closed',
      'planned': 0,
      'actual': 0,
      'progressPct': 0,
      'over': false,
    },
    {
      'month': '$year-12',
      'status': 'closed',
      'planned': 0,
      'actual': 0,
      'progressPct': 0,
      'over': false,
    },
  ],
};

void main() {
  test('aggregates alerts, events, goals and the month hero', () async {
    final viewModel = _viewModel(_client());

    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.monthSection.errorMessage, isNull);
    expect(viewModel.eventsSection.errorMessage, isNull);
    expect(viewModel.greeting, 'Boa tarde');
    final alerts = viewModel.alerts;
    expect(alerts, hasLength(2));
    expect(alerts.first.message, 'Outubro por fechar');
    expect(alerts.first.month, '2026-10');
    expect(alerts.first.kind, DashboardAlertKind.toClose);
    expect(alerts.last.message, 'Novembro ainda não criado');
    expect(alerts.last.month, '2026-11');
    expect(alerts.last.kind, DashboardAlertKind.toCreate);
    expect(viewModel.upcomingEvents, hasLength(2));
    expect(viewModel.upcomingEvents.first.title, 'Consulta');

    expect(viewModel.goals, hasLength(2));
    final carro = viewModel.goals.first;
    expect(carro.name, 'Carro');
    expect(carro.reserved, 925);
    expect(carro.target, 4000);
    expect(carro.missing, 3075);

    expect(viewModel.month, '2026-10');
    expect(viewModel.monthSummary, isNotNull);
    expect(viewModel.monthSummary?.actual, 1240);
    expect(viewModel.monthSummary?.planned, 1500);

    expect(viewModel.yearMonths, hasLength(2));
    expect(viewModel.yearMonths.first.month, '2026-10');
    expect(viewModel.yearMonths.last.month, '2026-11');

    final ritual = viewModel.ritual;
    expect(ritual, isNotNull);
    expect(ritual?.month, '2026-10');
    expect(ritual?.expensesStatus, ExpenseMonthStatus.open);
    expect(ritual?.filledEntries, 5);
    expect(ritual?.totalEntries, 10);
    expect(ritual?.goalsStatus, ExpenseMonthStatus.missing);
    expect(ritual?.goalsReserved, 0);
    expect(ritual?.goalsPlanned, 0);
    expect(ritual?.isClosed, isFalse);
    expect(ritual?.isMissing, isFalse);
  });

  test('steps the header month and clears the summary when missing', () async {
    final viewModel = _viewModel(_client());

    await viewModel.load();

    expect(viewModel.canGoToPreviousMonth, isTrue);
    await viewModel.showPreviousMonth();

    expect(viewModel.month, '2026-09');
    expect(viewModel.monthSummary, isNull);
  });

  test('steps the goals year and reloads the goals', () async {
    final viewModel = _viewModel(_client());

    await viewModel.load();

    expect(viewModel.goalsYear, 2026);
    expect(viewModel.canGoToPreviousGoalsYear, isTrue);

    await viewModel.showPreviousGoalsYear();

    expect(viewModel.goalsYear, 2025);
    expect(viewModel.goals, hasLength(2));
  });

  test('keeps the other sections when one request fails', () async {
    final viewModel = _viewModel(_client(failEvents: true));

    await viewModel.load();

    expect(viewModel.monthSummary?.actual, 1240);
    expect(viewModel.alerts, hasLength(2));
    expect(viewModel.goals, hasLength(2));
    expect(viewModel.eventsSection.errorMessage, 'Eventos indisponíveis');
    expect(viewModel.upcomingEvents, isEmpty);
    expect(viewModel.monthSection.errorMessage, isNull);
    expect(viewModel.goalsSection.errorMessage, isNull);
  });

  test('refresh reads the clock again', () async {
    var current = DateTime(2026, 10, 18, 15);
    final viewModel = _viewModel(_client(), now: current, clock: () => current);

    await viewModel.load();
    expect(viewModel.greeting, 'Boa tarde');
    expect(viewModel.today, DateTime(2026, 10, 18));

    current = DateTime(2026, 10, 19, 9);
    await viewModel.refresh();

    expect(viewModel.greeting, 'Bom dia');
    expect(viewModel.today, DateTime(2026, 10, 19));
  });

  test('orders goals by timeline, priority and missing amount', () async {
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/months/summary':
          return jsonResponse(_yearSummary());
        case '/api/events':
          return jsonResponse(const <Object>[]);
        case '/api/goal-plan':
          return jsonResponse(const {
            'plans': [
              {
                'id': 'p1',
                'month': '2026-01',
                'availableAmount': 2000,
                'closed': true,
                'allocations': [
                  {
                    'goalId': 'g1',
                    'goalName': 'Viagem',
                    'planned': 1000,
                    'actual': 100,
                  },
                  {
                    'goalId': 'g2',
                    'goalName': 'Carro',
                    'planned': 1000,
                    'actual': 900,
                  },
                ],
              },
            ],
            'funding': {
              'year': 2026,
              'annualTotal': 2000,
              'months': <Object>[],
            },
          });
        case '/api/goals':
          return jsonResponse(_goals());
        case '/api/goal-templates/applicable':
          return jsonResponse(const {
            'template': {
              'id': 't1',
              'validFrom': '2026-01',
              'annualTotal': 2000,
              'entries': [
                {
                  'goalId': 'g2',
                  'percentage': 50,
                  'budget': 1000,
                  'timeline': 'T4',
                  'priority': 'NICE_TO_HAVE',
                },
                {
                  'goalId': 'g1',
                  'percentage': 50,
                  'budget': 1000,
                  'timeline': 'T1',
                  'priority': 'GRANDE',
                },
              ],
            },
          });
        case '/api/months/2026-10':
          return jsonResponse(_month());
        default:
          return jsonResponse(const <Object>[], status: 404);
      }
    });
    final viewModel = _viewModel(client);

    await viewModel.load();

    expect(viewModel.goals.map((goal) => goal.name).toList(), [
      'Viagem',
      'Carro',
    ]);
  });

  test('loads the year strip for the displayed month year', () async {
    final requestedYears = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/api/months/summary') {
        final year = request.url.queryParameters['year'] ?? '';
        requestedYears.add(year);
        return jsonResponse(_yearSummaryFor(int.parse(year)));
      }
      switch (request.url.path) {
        case '/api/events':
          return jsonResponse(const <Object>[]);
        case '/api/goal-plan':
          return jsonResponse(_goalYear());
        case '/api/goals':
          return jsonResponse(const <Object>[]);
        case '/api/goal-templates/applicable':
          return jsonResponse(const {'template': null});
        default:
          return jsonResponse(const <Object>[], status: 404);
      }
    });
    final viewModel = _viewModel(client, now: DateTime(2026, 1, 15, 12));

    await viewModel.load();
    expect(viewModel.yearMonths.first.month, '2026-01');

    await viewModel.showPreviousMonth();

    expect(viewModel.month, '2025-12');
    expect(viewModel.monthSummary, isNull);
    expect(viewModel.yearMonths.first.month, '2025-01');
    expect(viewModel.stripSection.isLoading, isFalse);
    expect(requestedYears, contains('2025'));
  });
}
