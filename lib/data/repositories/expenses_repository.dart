import 'package:nest/data/models/expense_year_summary_model.dart';
import 'package:nest/data/models/json_mapper.dart';
import 'package:nest/data/models/monthly_plan_model.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/monthly_plan.dart';

/// Reads the yearly expense panorama and individual months.
class ExpensesRepository {
  ExpensesRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns the expense panorama of [year]: totals, deviation and every month.
  Future<ExpenseYearSummary> fetchYearSummary(int year) async {
    final data = await _client.get('/api/months/summary?year=$year');
    return mapJson(
      data,
      (json) => ExpenseYearSummaryModel.fromJson(json).toDomain(),
    );
  }

  /// Returns the plan of [month] (`YYYY-MM`), or `null` when it is not created.
  Future<MonthlyPlan?> fetchMonth(String month) async {
    try {
      final data = await _client.get('/api/months/$month');
      return mapJson(
        data,
        (json) => MonthlyPlanModel.fromJson(json).toDomain(),
      );
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
    return mapJson(data, (json) => MonthlyPlanModel.fromJson(json).toDomain());
  }

  /// Closes [month] (`YYYY-MM`) and records its settlement. Irreversible.
  Future<MonthlyPlan> closeMonth(String month) async {
    final data = await _client.post('/api/months/$month/close', const {});
    return mapJson(data, (json) => MonthlyPlanModel.fromJson(json).toDomain());
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
    return mapJson(data, (json) => MonthlyPlanModel.fromJson(json).toDomain());
  }

  /// Saves several real amounts in one request, all or nothing.
  ///
  /// [actuals] maps each entry id to the amount spent. Returns the whole
  /// refreshed month so callers can replace their state atomically.
  Future<MonthlyPlan> updateEntriesActual(
    String month,
    Map<String, double> actuals,
  ) async {
    final data = await _client.patch('/api/months/$month/entries', {
      'entries': [
        for (final update in actuals.entries)
          {'id': update.key, 'actual': update.value},
      ],
    });
    return mapJson(data, (json) => MonthlyPlanModel.fromJson(json).toDomain());
  }

  /// Computes the contributions of [month] (`YYYY-MM`) without closing it.
  ///
  /// The server returns the same shape as the recorded settlement, so the
  /// client can show the transfers before the irreversible close.
  Future<MonthSettlement> fetchSettlementPreview(String month) async {
    final data = await _client.get('/api/months/$month/settlement-preview');
    return mapJson(
      data,
      (json) => MonthSettlementModel.fromJson(json).toDomain(),
    );
  }
}
