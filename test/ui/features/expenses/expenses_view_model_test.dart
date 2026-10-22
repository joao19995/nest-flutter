import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/expenses/view_models/expenses_view_model.dart';

import '../../../support/test_helpers.dart';

ExpensesViewModel _viewModel(MockClient client, {int year = 2026}) =>
    ExpensesViewModel(
      expensesRepository: ExpensesRepository(
        client: NestApiClient(
          httpClient: client,
          baseUrl: 'http://test.local',
          apiKey: '',
        ),
      ),
      year: year,
    );

Map<String, dynamic> _summary() => <String, dynamic>{
  'year': 2026,
  'planned': 12000,
  'actual': 13200,
  'diff': 1200,
  'diffPct': 10,
  'over': true,
  'hasData': true,
  'remainingMonths': 3,
  'perRemainingMonth': 400,
  'months': [
    {
      'month': '2026-01',
      'status': 'closed',
      'planned': 1000,
      'actual': 1200,
      'progressPct': 120,
      'over': true,
    },
  ],
};

MockClient _client() => MockClient(
  (request) async => request.url.path == '/api/months/summary'
      ? jsonResponse(_summary())
      : jsonResponse(<Object>[], status: 404),
);

void main() {
  test('load exposes the summary, its months and totals', () async {
    final viewModel = _viewModel(_client());

    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.isEmpty, isFalse);
    expect(viewModel.summary?.actual, 13200);
    expect(viewModel.months, hasLength(1));
    expect(viewModel.months.first.over, isTrue);
  });

  test('currentMonth is only set for the current year', () async {
    final currentYear = DateTime.now().year;

    final current = _viewModel(_client(), year: currentYear);
    await current.load();
    expect(current.currentMonth, isNotNull);
    expect(current.currentMonth, startsWith('$currentYear-'));

    final other = _viewModel(_client(), year: currentYear - 1);
    await other.load();
    expect(other.currentMonth, isNull);
  });

  test('empty summary reports isEmpty', () async {
    final client = MockClient(
      (request) async => jsonResponse(<String, dynamic>{
        'year': 2026,
        'planned': 0,
        'actual': 0,
        'diff': 0,
        'diffPct': 0,
        'over': false,
        'hasData': false,
        'remainingMonths': 12,
        'perRemainingMonth': 0,
        'months': <Object>[],
      }),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.isEmpty, isTrue);
    expect(viewModel.months, isEmpty);
  });

  test('reports a failure without throwing', () async {
    final client = MockClient(
      (request) async => jsonResponse(const {'error': 'Falhou.'}, status: 500),
    );

    final viewModel = _viewModel(client);
    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, 'Falhou.');
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
}
