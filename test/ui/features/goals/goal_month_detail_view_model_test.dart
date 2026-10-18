import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/goals/view_models/goal_month_detail_view_model.dart';

GoalMonthDetailViewModel _viewModel(
  MockClient client, {
  String month = '2026-01',
}) => GoalMonthDetailViewModel(
  goalsRepository: GoalsRepository(
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

List<Object> _quotaFixtures() => <Object>[
  {
    'personId': 'p1',
    'name': 'João',
    'earning': 2500,
    'share': 0.625,
    'amount': 625,
    'parts': [
      {'goalId': 'g1', 'name': 'Viagem', 'amount': 600},
      {'goalId': 'g2', 'name': 'Carro', 'amount': 25},
    ],
  },
  {
    'personId': 'p2',
    'name': 'Nathalia',
    'earning': 1500,
    'share': 0.375,
    'amount': 375,
    'parts': [
      {'goalId': 'g2', 'name': 'Carro', 'amount': 375},
    ],
  },
];

Map<String, dynamic> _view({
  String? planId = 'p1',
  bool closed = false,
  double a1 = 600,
  double a2 = 400,
}) => <String, dynamic>{
  'month': '2026-01',
  'planId': planId,
  'closed': closed,
  'availableAmount': 1000,
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': a1},
    {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': a2},
  ],
  'quotas': _quotaFixtures(),
};

Map<String, dynamic> _missing() => <String, dynamic>{
  'month': '2026-03',
  'planId': null,
  'closed': false,
  'availableAmount': 1000,
  'allocations': <Object>[],
  'quotas': <Object>[],
};

Map<String, dynamic> _plan({
  bool closed = false,
  double a1 = 600,
  double a2 = 400,
}) => <String, dynamic>{
  'id': 'p1',
  'month': '2026-01',
  'availableAmount': 1000,
  'closed': closed,
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': a1},
    {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': a2},
  ],
};

void main() {
  test('load exposes the plan, totals and server-computed quotas', () async {
    final viewModel = _viewModel(MockClient((request) async => _json(_view())));

    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.reserved, 1000);
    expect(viewModel.planned, 1000);
    expect(viewModel.available, 1000);
    expect(viewModel.isOpen, isTrue);

    expect(viewModel.transfers, hasLength(2));
    final joao = viewModel.transfers.firstWhere((t) => t.name == 'João');
    expect(joao.earning, 2500);
    expect(joao.amount, 625);
    expect(joao.parts, hasLength(2));
  });

  test('an uncreated month is an empty plan with no quotas', () async {
    final viewModel = _viewModel(
      MockClient((request) async => _json(_missing())),
      month: '2026-03',
    );

    await viewModel.load();

    expect(viewModel.plan, isNull);
    expect(viewModel.transfers, isEmpty);
    expect(viewModel.available, 1000);
    expect(viewModel.errorMessage, isNull);
  });

  test('createMonth posts the month and reloads the view', () async {
    var created = false;
    final writes = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _json(created ? _view() : _missing());
      }
      writes.add('${request.method} ${request.url.path}');
      created = true;
      return _json(_plan(), status: 201);
    });

    final viewModel = _viewModel(client, month: '2026-03');
    await viewModel.load();
    await viewModel.createMonth();

    expect(writes, contains('POST /api/goal-plan'));
    expect(viewModel.plan, isNotNull);
  });

  test('editing a reserved value patches then requests fresh quotas', () async {
    String? patchedPath;
    Object? patchBody;
    Object? quotasBody;
    final client = MockClient((request) async {
      if (request.method == 'PATCH') {
        patchedPath = request.url.path;
        patchBody = jsonDecode(request.body);
        return _json(_plan(a1: 800));
      }
      if (request.url.path == '/api/goal-plan/quotas') {
        quotasBody = jsonDecode(request.body);
        return _json({'quotas': _quotaFixtures()});
      }
      return _json(_view(a1: 800));
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.updateAllocationActual('g1', 800);

    expect(patchedPath, '/api/goal-plan/2026-01/allocations/g1');
    expect((patchBody as Map<String, dynamic>)['actual'], 800);
    final sent = quotasBody as Map<String, dynamic>;
    expect(sent['month'], '2026-01');
    expect((sent['allocations'] as List).first, {
      'goalId': 'g1',
      'name': 'Viagem',
      'amount': 800,
    });
    expect(viewModel.transfers, hasLength(2));
    expect(viewModel.isBusy, isFalse);
  });

  test('closeMonth fills untouched goals then closes and reloads', () async {
    var closed = false;
    final writes = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _json(closed ? _view(closed: true) : _view(a1: 0, a2: 0));
      }
      writes.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/close')) {
        closed = true;
        return _json(_plan(closed: true));
      }
      if (request.url.path.endsWith('/adjust')) {
        return _json(const <String, dynamic>{});
      }
      return _json(_plan());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.closeMonth();

    expect(
      writes.where((call) => call.startsWith('PATCH')).length,
      2,
      reason: 'both untouched goals default to their planned amount',
    );
    expect(writes, contains('POST /api/goal-plan/2026-01/close'));
    expect(
      writes.any((call) => call.contains('/adjust')),
      isFalse,
      reason: 'the plan is already fully allocated',
    );
    expect(viewModel.plan?.closed, isTrue);
  });

  test('a failed write records the action error', () async {
    final client = MockClient((request) async {
      if (request.method == 'PATCH') {
        return _json(const {'error': 'Não guardou.'}, status: 500);
      }
      return _json(_view());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.updateAllocationActual('g1', 800);

    expect(viewModel.actionError, 'Não guardou.');
    expect(viewModel.isBusy, isFalse);
  });
}
