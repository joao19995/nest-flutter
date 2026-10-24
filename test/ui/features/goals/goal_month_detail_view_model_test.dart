import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/goals/view_models/goal_month_detail_view_model.dart';

import '../../../support/test_helpers.dart';

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
  'funding': {
    'month': '2026-01',
    'incomeNormal': 2500,
    'bonus': 0,
    'dailyAllowance': 500,
    'contributionRequired': 1000,
    'available': 1000,
  },
  'totals': {'planned': 1000, 'actual': a1 + a2, 'reserved': 1000},
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': a1},
    {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': a2},
  ],
  'quotas': _quotaFixtures(),
};

Map<String, dynamic> _closePreview({
  bool adjusted = false,
  List<Object>? defaulted,
}) => <String, dynamic>{
  'month': '2026-01',
  'availableAmount': 1000,
  'plannedTotal': 1000,
  'reservedTotal': 1000,
  'unallocated': 0,
  'adjustedFromTemplate': adjusted,
  'affectedFutureMonths': adjusted ? ['2026-02'] : <Object>[],
  'defaulted':
      defaulted ??
      [
        {'goalId': 'g1', 'goalName': 'Viagem', 'amount': 600},
        {'goalId': 'g2', 'goalName': 'Carro', 'amount': 400},
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

Map<String, dynamic> _plan() => <String, dynamic>{
  'id': 'p1',
  'month': '2026-03',
  'availableAmount': 1000,
  'closed': false,
  'allocations': <Object>[],
};

List<Object> _goals() => <Object>[
  {'id': 'g1', 'name': 'Viagem', 'active': true, 'iconKey': 'plane'},
  {'id': 'g2', 'name': 'Carro', 'active': true, 'iconKey': 'car'},
];

bool _isGoalsRequest(dynamic request) => request.url.path == '/api/goals';

void main() {
  test('load exposes the plan, totals and server-computed quotas', () async {
    final viewModel = _viewModel(
      MockClient(
        (request) async => _isGoalsRequest(request)
            ? jsonResponse(_goals())
            : jsonResponse(_view()),
      ),
    );

    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.reserved, 1000);
    expect(viewModel.planned, 1000);
    expect(viewModel.available, 1000);
    expect(viewModel.isOpen, isTrue);
    expect(viewModel.iconKeyByGoal['g1'], 'plane');
    expect(viewModel.funding?.incomeNormal, 2500);
    expect(viewModel.totals?.reserved, 1000);

    expect(viewModel.transfers, hasLength(2));
    final joao = viewModel.transfers.firstWhere((t) => t.name == 'João');
    expect(joao.earning, 2500);
    expect(joao.amount, 625);
    expect(joao.parts, hasLength(2));
  });

  test('an uncreated month is an empty plan with no quotas', () async {
    final viewModel = _viewModel(
      MockClient((request) async => jsonResponse(_missing())),
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
      if (_isGoalsRequest(request)) {
        return jsonResponse(_goals());
      }
      if (request.method == 'GET') {
        return jsonResponse(created ? _view() : _missing());
      }
      writes.add('${request.method} ${request.url.path}');
      created = true;
      return jsonResponse(_plan(), status: 201);
    });

    final viewModel = _viewModel(client, month: '2026-03');
    await viewModel.load();
    await viewModel.createMonth();

    expect(writes, contains('POST /api/goal-plan'));
    expect(viewModel.plan, isNotNull);
  });

  test('editing a reserved value adopts the returned month view', () async {
    String? patchedPath;
    Object? patchBody;
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (_isGoalsRequest(request)) {
        return jsonResponse(_goals());
      }
      if (request.method == 'PATCH') {
        patchedPath = request.url.path;
        patchBody = jsonDecode(request.body);
        return jsonResponse(_view(a1: 800));
      }
      return jsonResponse(_view());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.updateAllocationActual('g1', 800);

    expect(patchedPath, '/api/goal-plan/2026-01/allocations/g1');
    expect((patchBody as Map<String, dynamic>)['actual'], 800);
    expect(viewModel.transfers, hasLength(2));
    expect(
      paths.any((path) => path.contains('/quotas')),
      isFalse,
      reason: 'the PATCH response already carries the quotas',
    );
    expect(viewModel.isBusy, isFalse);
  });

  test('closeMonth posts the atomic close and adopts the view', () async {
    final writes = <String>[];
    final client = MockClient((request) async {
      if (_isGoalsRequest(request)) {
        return jsonResponse(_goals());
      }
      if (request.method == 'GET') {
        return jsonResponse(_view(a1: 0, a2: 0));
      }
      writes.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/close')) {
        return jsonResponse(_view(closed: true));
      }
      return jsonResponse(_view());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.closeMonth();

    expect(writes, ['POST /api/goal-plan/2026-01/close']);
    expect(viewModel.plan?.closed, isTrue);
  });

  test('loadClosePreview exposes the projected close', () async {
    final client = MockClient((request) async {
      if (_isGoalsRequest(request)) {
        return jsonResponse(_goals());
      }
      if (request.url.path.endsWith('/close-preview')) {
        return jsonResponse(_closePreview(adjusted: true));
      }
      return jsonResponse(_view());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.loadClosePreview();

    expect(viewModel.isPreviewLoading, isFalse);
    expect(viewModel.previewError, isNull);
    expect(viewModel.closePreview?.adjustedFromTemplate, isTrue);
    expect(viewModel.closePreview?.defaulted, hasLength(2));
    expect(viewModel.closePreview?.quotas, hasLength(2));
  });

  test('a failed preview records the preview error', () async {
    final client = MockClient((request) async {
      if (_isGoalsRequest(request)) {
        return jsonResponse(_goals());
      }
      if (request.url.path.endsWith('/close-preview')) {
        return jsonResponse(const {'error': 'Não calculou.'}, status: 500);
      }
      return jsonResponse(_view());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.loadClosePreview();

    expect(viewModel.previewError, 'Não calculou.');
    expect(viewModel.closePreview, isNull);
    expect(viewModel.isPreviewLoading, isFalse);
  });

  test(
    'the close ignores a loaded preview and makes no extra writes',
    () async {
      final writes = <String>[];
      final client = MockClient((request) async {
        if (_isGoalsRequest(request)) {
          return jsonResponse(_goals());
        }
        if (request.url.path.endsWith('/close-preview')) {
          return jsonResponse(_closePreview(adjusted: true));
        }
        if (request.method == 'GET') {
          return jsonResponse(_view(a1: 0, a2: 0));
        }
        writes.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/close')) {
          return jsonResponse(_view(closed: true));
        }
        return jsonResponse(_view());
      });

      final viewModel = _viewModel(client);
      await viewModel.load();
      await viewModel.loadClosePreview();
      await viewModel.closeMonth();

      expect(writes, ['POST /api/goal-plan/2026-01/close']);
      expect(viewModel.plan?.closed, isTrue);
    },
  );

  test('a failed write records the action error', () async {
    final client = MockClient((request) async {
      if (_isGoalsRequest(request)) {
        return jsonResponse(_goals());
      }
      if (request.method == 'PATCH') {
        return jsonResponse(const {'error': 'Não guardou.'}, status: 500);
      }
      return jsonResponse(_view());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.updateAllocationActual('g1', 800);

    expect(viewModel.actionError, 'Não guardou.');
    expect(viewModel.isBusy, isFalse);
  });
}
