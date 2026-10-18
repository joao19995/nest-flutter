import 'package:nest/data/models/expense_year_summary_model.dart';
import 'package:nest/data/models/monthly_plan_model.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/domain/models/monthly_plan.dart';

/// Reads the yearly expense panorama and individual months.
class ExpensesRepository {
  ExpensesRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns the expense panorama of [year]: totals, deviation and every month.
  Future<ExpenseYearSummary> fetchYearSummary(int year) async {
    final data = await _client.get('/api/months/summary?year=$year');
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return ExpenseYearSummaryModel.fromJson(data).toDomain();
  }

  /// Returns the plan of [month] (`YYYY-MM`), or `null` when it is not created.
  Future<MonthlyPlan?> fetchMonth(String month) async {
    try {
      final data = await _client.get('/api/months/$month');
      if (data is! Map<String, dynamic>) {
        throw const ApiFailure('Resposta inesperada do servidor.');
      }
      return MonthlyPlanModel.fromJson(data).toDomain();
    } on ApiFailure catch (failure) {
      if (failure.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Creates [month] (`YYYY-MM`) by copying the applicable template.
  Future<MonthlyPlan> createMonth(String month) async {
    final data = await _client.post('/api/months', {'month': month});
    return _plan(data);
  }

  /// Closes [month] (`YYYY-MM`) and records its settlement. Irreversible.
  Future<MonthlyPlan> closeMonth(String month) async {
    final data = await _client.post('/api/months/$month/close', const {});
    return _plan(data);
  }

  /// Saves the real amount spent on [entryId] within [month] (`YYYY-MM`).
  Future<MonthlyPlan> updateEntryActual(
    String month,
    String entryId,
    double actual,
  ) async {
    final data = await _client.patch('/api/months/$month/entries/$entryId', {
      'actual': actual,
    });
    return _plan(data);
  }

  MonthlyPlan _plan(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return MonthlyPlanModel.fromJson(data).toDomain();
  }
}
