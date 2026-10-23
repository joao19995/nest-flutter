import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/ui/features/goals/view_models/goals_view_model.dart';

import '../../../support/test_helpers.dart';

GoalsViewModel _viewModel(MockClient client, {int year = 2026}) =>
    GoalsViewModel(
      goalsRepository: GoalsRepository(
        client: NestApiClient(
          httpClient: client,
          baseUrl: 'http://test.local',
          apiKey: '',
        ),
      ),
      year: year,
    );

Map<String, dynamic> _year() => <String, dynamic>{
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
    'annualTotal': 34565.6,
    'months': [
      {'month': '2026-01', 'available': 2040},
    ],
  },
};

List<Object> _goals() => <Object>[
  {'id': 'g1', 'name': 'Viagem', 'active': true},
  {'id': 'g2', 'name': 'Carro', 'active': true},
];

Map<String, dynamic> _applicableTemplate() => <String, dynamic>{
  'id': 't2',
  'validFrom': '2026-01',
  'entries': [
    {'goalId': 'g1', 'budget': 800, 'timeline': 'T1', 'priority': 'PEQUENO'},
    {'goalId': 'g2', 'budget': 925, 'timeline': 'T3', 'priority': 'GRANDE'},
  ],
};

MockClient _client() => MockClient((request) async {
  switch (request.url.path) {
    case '/api/goal-plan':
      return jsonResponse(_year());
    case '/api/goals':
      return jsonResponse(_goals());
    case '/api/goal-templates/applicable':
      return jsonResponse({'template': _applicableTemplate()});
    default:
      return jsonResponse(<Object>[], status: 404);
  }
});

void main() {
  test('load computes the year totals, months and goals', () async {
    final viewModel = _viewModel(_client());

    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.totalReserved, 1725);
    expect(viewModel.annualAvailable, 34565.6);
    expect(viewModel.unallocated, closeTo(32840.6, 0.001));

    expect(viewModel.months, hasLength(12));
    final january = viewModel.months.first;
    expect(january.month, '2026-01');
    expect(january.reserved, 1725);
    expect(january.available, 2040);
    expect(january.fundedCount, 2);
    expect(january.hasPlan, isTrue);
    expect(viewModel.months[1].hasPlan, isFalse);

    final carro = viewModel.goals.first;
    expect(carro.name, 'Carro');
    expect(carro.reserved, 925);
    expect(carro.target, 925);
    expect(carro.progress, 1);
    expect(carro.hasTarget, isTrue);
    expect(carro.timeline, GoalTimeline.t3);
    expect(carro.priority, GoalPriority.grande);
  });

  test('the template in force at the year start sets the targets', () async {
    final viewModel = _viewModel(_client());

    await viewModel.load();

    final viagem = viewModel.goals.firstWhere((goal) => goal.name == 'Viagem');
    expect(viagem.target, 800);
    expect(viagem.timeline, GoalTimeline.t1);
    expect(viagem.priority, GoalPriority.pequeno);
  });

  test('reports a failure without throwing', () async {
    final client = MockClient(
      (request) async =>
          jsonResponse(const {'error': 'Sem ligação.'}, status: 500),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, 'Sem ligação.');
    expect(viewModel.isEmpty, isTrue);
  });

  test('does not move past the year bounds', () async {
    final viewModel = _viewModel(_client(), year: 2000);
    await viewModel.load();

    expect(viewModel.canGoToPreviousYear, isFalse);
    viewModel.showPreviousYear();
    expect(viewModel.selectedYear, 2000);

    final latest = DateTime.now().year + 1;
    final newest = _viewModel(_client(), year: latest);
    await newest.load();
    expect(newest.canGoToNextYear, isFalse);
    newest.showNextYear();
    expect(newest.selectedYear, latest);
  });

  test('selecting the next year advances the year', () async {
    final thisYear = DateTime.now().year;
    final viewModel = _viewModel(_client(), year: thisYear);
    await viewModel.load();

    viewModel.showNextYear();

    expect(viewModel.selectedYear, thisYear + 1);
  });
}
