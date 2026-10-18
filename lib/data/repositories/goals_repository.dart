import 'package:nest/data/models/goal_model.dart';
import 'package:nest/data/models/goal_month_model.dart';
import 'package:nest/data/models/goal_template_model.dart';
import 'package:nest/data/models/goal_year_model.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/domain/models/goal_year.dart';

/// Reads the savings goals and their yearly plans.
class GoalsRepository {
  GoalsRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns the goal catalogue, including inactive goals.
  Future<List<Goal>> fetchGoals() async {
    final data = await _client.get('/api/goals?includeInactive=true');
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => GoalModel.fromJson(json).toDomain())
        .toList(growable: false);
  }

  /// Returns the goal-template version in force for [month] (`YYYY-MM`), or
  /// `null` when none applies. Server-side domain rule (`resolveApplicableGoalTemplate`).
  Future<GoalTemplate?> fetchApplicableGoalTemplate(String month) async {
    final data = await _client.get(
      '/api/goal-templates/applicable?month=$month',
    );
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final template = data['template'];
    if (template is! Map<String, dynamic>) {
      return null;
    }
    return GoalTemplateModel.fromJson(template).toDomain();
  }

  /// Returns the saved plans and funding of [year].
  Future<GoalYear> fetchGoalYear(int year) async {
    final data = await _client.get('/api/goal-plan?year=$year');
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return GoalYearModel.fromJson(data).toDomain();
  }

  /// Returns the full view of [month] (`YYYY-MM`) — plan, available amount and
  /// per-person quotas — or `null` when the month has not been created.
  Future<GoalMonthView?> fetchGoalMonth(String month) async {
    try {
      final data = await _client.get('/api/goal-plan/$month');
      if (data is! Map<String, dynamic>) {
        throw const ApiFailure('Resposta inesperada do servidor.');
      }
      return GoalMonthModel.fromJson(data).toDomain();
    } on ApiFailure catch (failure) {
      if (failure.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Creates [month] (`YYYY-MM`) from the applicable template's snapshot.
  Future<GoalPlan> createGoalPlan(String month) async {
    final data = await _client.post('/api/goal-plan', {'month': month});
    return _plan(data);
  }

  /// Saves the reserved amount of [goalId] within [month] (`YYYY-MM`) and
  /// returns the fresh month view (plan and quotas).
  Future<GoalMonthView> updateGoalAllocation(
    String month,
    String goalId,
    double actual,
  ) async {
    final data = await _client.patch(
      '/api/goal-plan/$month/allocations/$goalId',
      {'actual': actual},
    );
    return _view(data);
  }

  /// Redistributes an open month's planned amounts from the applicable
  /// template, so the month can be closed with a full allocation.
  Future<void> adjustGoalPlanFromTemplate(String month) => _client.post(
    '/api/goal-plan/adjust',
    {'month': month, 'fromTemplate': true},
  );

  /// Closes [month] (`YYYY-MM`) and returns the frozen month view.
  Future<GoalMonthView> closeGoalPlan(String month) async {
    final data = await _client.post('/api/goal-plan/$month/close', const {});
    return _view(data);
  }

  GoalPlan _plan(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return GoalPlanModel.fromJson(data).toDomain();
  }

  GoalMonthView _view(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return GoalMonthModel.fromJson(data).toDomain();
  }
}
