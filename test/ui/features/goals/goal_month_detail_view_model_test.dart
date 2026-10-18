import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/goals/view_models/goal_month_detail_view_model.dart';

GoalMonthDetailViewModel _viewModel(
  MockClient client, {
  String month = '2026-01',
}) {
  final api = NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  );
  return GoalMonthDetailViewModel(
    goalsRepository: GoalsRepository(client: api),
    peopleRepository: PeopleRepository(client: api),
    month: month,
  );
}

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _plan({
  double a1 = 600,
  double a2 = 400,
  bool closed = false,
}) => <String, dynamic>{
  'month': '2026-01',
  'planId': 'p1',
  'id': 'p1',
  'closed': closed,
  'availableAmount': 1000,
  'allocations': [
    {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': a1},
    {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': a2},
  ],
};

Map<String, dynamic> _missing() => <String, dynamic>{
  'month': '2026-03',
  'planId': null,
  'closed': false,
  'availableAmount': 0,
  'allocations': <Object>[],
};

List<Object> _people() => <Object>[
  {'id': 'p1', 'name': 'João', 'dailySpendingPercentage': 25},
  {'id': 'p2', 'name': 'Nathalia', 'dailySpendingPercentage': 25},
];

List<Object> _incomes(String personId) => <Object>[
  {
    'id': 'i-$personId',
    'personId': personId,
    'amount': personId == 'p1' ? 2500 : 1500,
    'validFrom': '2000-01-01',
  },
];

/// Answers the people / income reads shared by every case, else null.
http.Response? _peopleRoutes(http.Request request) {
  if (request.url.path == '/api/people') {
    return _json(_people());
  }
  final match = RegExp(
    r'^/api/people/([^/]+)/income$',
  ).firstMatch(request.url.path);
  if (match != null) {
    return _json(_incomes(match.group(1)!));
  }
  return null;
}

void main() {
  test('load distributes the month reserved across earners', () async {
    final viewModel = _viewModel(
      MockClient((request) async => _peopleRoutes(request) ?? _json(_plan())),
    );

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

    final nathalia = viewModel.transfers.firstWhere(
      (t) => t.name == 'Nathalia',
    );
    expect(nathalia.amount, 375);
  });

  test('June and December double the earning used for the split', () async {
    final january = _viewModel(
      MockClient((request) async => _peopleRoutes(request) ?? _json(_plan())),
    );
    await january.load();
    expect(january.transfers.firstWhere((t) => t.name == 'João').earning, 2500);

    final june = _viewModel(
      MockClient((request) async => _peopleRoutes(request) ?? _json(_plan())),
      month: '2026-06',
    );
    await june.load();
    expect(june.transfers.firstWhere((t) => t.name == 'João').earning, 5000);
  });

  test('a missing month is a null plan with no transfers', () async {
    final viewModel = _viewModel(
      MockClient(
        (request) async => _peopleRoutes(request) ?? _json(_missing()),
      ),
      month: '2026-03',
    );
    await viewModel.load();

    expect(viewModel.plan, isNull);
    expect(viewModel.transfers, isEmpty);
    expect(viewModel.errorMessage, isNull);
  });

  test('createMonth posts the month and reloads it', () async {
    var created = false;
    final writes = <String>[];
    final client = MockClient((request) async {
      final people = _peopleRoutes(request);
      if (people != null) {
        return people;
      }
      if (request.method == 'GET' &&
          request.url.path.startsWith('/api/goal-plan/')) {
        return _json(created ? _plan() : _missing());
      }
      writes.add('${request.method} ${request.url.path}');
      if (request.method == 'POST') {
        created = true;
        return _json(_plan(), status: 201);
      }
      return _json(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client, month: '2026-03');
    await viewModel.load();
    await viewModel.createMonth();

    expect(writes, contains('POST /api/goal-plan'));
    expect(viewModel.plan, isNotNull);
  });

  test('updateAllocationActual patches the goal', () async {
    String? patchedPath;
    Object? body;
    final client = MockClient((request) async {
      final people = _peopleRoutes(request);
      if (people != null) {
        return people;
      }
      if (request.method == 'PATCH') {
        patchedPath = request.url.path;
        body = jsonDecode(request.body);
        return _json(_plan(a1: 800));
      }
      return _json(_plan());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.updateAllocationActual('g1', 800);

    expect(patchedPath, '/api/goal-plan/p1/allocations/g1');
    expect((body as Map<String, dynamic>)['actual'], 800);
    expect(viewModel.isBusy, isFalse);
  });

  test('closeMonth fills untouched goals and closes', () async {
    final writes = <String>[];
    final client = MockClient((request) async {
      final people = _peopleRoutes(request);
      if (people != null) {
        return people;
      }
      if (request.method == 'GET') {
        return _json(_plan(a1: 0, a2: 0));
      }
      writes.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/close')) {
        return _json(_plan(closed: true));
      }
      if (request.url.path.endsWith('/adjust')) {
        return _json(const <String, dynamic>{});
      }
      if (request.url.path.contains('/allocations/')) {
        return _json(_plan());
      }
      return _json(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.closeMonth();

    expect(
      writes.where((call) => call.startsWith('PATCH')).length,
      2,
      reason: 'both untouched goals default to their planned amount',
    );
    expect(writes, contains('POST /api/goal-plan/p1/close'));
    expect(
      writes.any((call) => call.contains('/adjust')),
      isFalse,
      reason: 'the plan is already fully allocated',
    );
    expect(viewModel.plan?.closed, isTrue);
  });

  test('a failed write records the action error', () async {
    final client = MockClient((request) async {
      final people = _peopleRoutes(request);
      if (people != null) {
        return people;
      }
      if (request.method == 'PATCH') {
        return _json(const {'error': 'Não guardou.'}, status: 500);
      }
      return _json(_plan());
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.updateAllocationActual('g1', 800);

    expect(viewModel.actionError, 'Não guardou.');
    expect(viewModel.isBusy, isFalse);
  });
}
