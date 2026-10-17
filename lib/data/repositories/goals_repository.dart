import 'package:nest/data/models/goal_model.dart';
import 'package:nest/data/models/goal_month_model.dart';
import 'package:nest/data/models/goal_template_model.dart';
import 'package:nest/data/models/goal_year_model.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';
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

  /// Returns the annual goal-template versions, oldest first.
  Future<List<GoalTemplate>> fetchGoalTemplates() async {
    final data = await _client.get('/api/goal-templates');
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => GoalTemplateModel.fromJson(json).toDomain())
        .toList(growable: false);
  }

  /// Returns the saved plans and funding of [year].
  Future<GoalYear> fetchGoalYear(int year) async {
    final data = await _client.get('/api/goal-plan?year=$year');
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return GoalYearModel.fromJson(data).toDomain();
  }

  /// Returns the saved plan of [month] (`YYYY-MM`), or `null` when the month
  /// has not been created. Loads only the requested month.
  Future<GoalPlan?> fetchGoalMonth(String month) async {
    final data = await _client.get('/api/goal-plan?month=$month');
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return GoalMonthModel.fromJson(data).toDomain();
  }

  /// Creates [month] (`YYYY-MM`) from the applicable template's snapshot.
  Future<GoalPlan> createGoalPlan(String month) async {
    final data = await _client.post('/api/goal-plan', {'month': month});
    return _plan(data);
  }

  /// Saves the reserved amount of [goalId] within [planId].
  Future<GoalPlan> updateGoalAllocation(
    String planId,
    String goalId,
    double actual,
  ) async {
    final data = await _client.patch(
      '/api/goal-plan/$planId/allocations/$goalId',
      {'actual': actual},
    );
    return _plan(data);
  }

  /// Redistributes an open month's planned amounts from the applicable
  /// template, so the month can be closed with a full allocation.
  Future<void> adjustGoalPlanFromTemplate(String month) => _client.post(
    '/api/goal-plan/adjust',
    {'month': month, 'fromTemplate': true},
  );

  /// Closes the month [planId], making its allocation immutable.
  Future<GoalPlan> closeGoalPlan(String planId) async {
    final data = await _client.post('/api/goal-plan/$planId/close', const {});
    return _plan(data);
  }

  GoalPlan _plan(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return GoalPlanModel.fromJson(data).toDomain();
  }
}
