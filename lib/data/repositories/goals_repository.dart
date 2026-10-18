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

  /// Creates a goal in the catalogue.
  Future<Goal> createGoal({required String name}) async {
    final data = await _client.post('/api/goals', {'name': name});
    return _goal(data);
  }

  /// Renames the goal [id]. The catalogue input accepts only the name.
  Future<Goal> updateGoal(String id, {required String name}) async {
    final data = await _client.put('/api/goals/$id', {'name': name});
    return _goal(data);
  }

  /// Soft-deletes the goal [id] (sets `active = false`). Fails with a 409 when
  /// a template version still funds the goal for an open month.
  Future<void> deleteGoal(String id) => _client.delete('/api/goals/$id');

  /// Restores a soft-deleted goal [id].
  Future<Goal> restoreGoal(String id) async {
    final data = await _client.post('/api/goals/$id/restore', const {});
    return _goal(data);
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

  /// Allocates a detected salary raise to [goalId]: the server tops up the
  /// goal's budget (renormalising the percentages to 100%), creates a new
  /// template version starting at [validFrom] (`YYYY-MM`) and recalculates the
  /// year, all in one transaction.
  Future<void> allocateRaise({
    required String validFrom,
    required String goalId,
    required double extra,
  }) => _client.post('/api/goal-templates/raise', {
    'validFrom': validFrom,
    'goalId': goalId,
    'extra': extra,
  });

  /// Creates a template version starting at [validFrom] (`YYYY-MM`). The
  /// server recalculates the year and returns the created version.
  Future<GoalTemplate> createGoalTemplate({
    required String validFrom,
    required double annualTotal,
    required List<GoalTemplateEntry> entries,
  }) async {
    final data = await _client.post('/api/goal-templates', {
      'validFrom': validFrom,
      'annualTotal': annualTotal,
      'entries': [for (final entry in entries) _entryJson(entry)],
    });
    return _templateResult(data);
  }

  /// Replaces the entries of the template [id]. The version's month does not
  /// change; entries removed are dropped from the version.
  Future<GoalTemplate> updateGoalTemplate(
    String id, {
    required double annualTotal,
    required List<GoalTemplateEntry> entries,
  }) async {
    final data = await _client.put('/api/goal-templates/$id', {
      'annualTotal': annualTotal,
      'entries': [for (final entry in entries) _entryJson(entry)],
    });
    return _templateResult(data);
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

  Goal _goal(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return GoalModel.fromJson(data).toDomain();
  }

  GoalTemplate _templateResult(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    final template = data['template'];
    if (template is! Map<String, dynamic>) {
      throw const ApiFailure('Resposta inesperada do servidor.');
    }
    return GoalTemplateModel.fromJson(template).toDomain();
  }

  static Map<String, dynamic> _entryJson(GoalTemplateEntry entry) => {
    'goalId': entry.goalId,
    'percentage': entry.percentage,
    'budget': entry.budget,
    'timeline': _timelineApi(entry.timeline),
    'priority': _priorityApi(entry.priority),
    'notes': entry.notes,
  };

  static String _timelineApi(GoalTimeline timeline) => switch (timeline) {
    GoalTimeline.t1 => 'T1',
    GoalTimeline.t2 => 'T2',
    GoalTimeline.t3 => 'T3',
    GoalTimeline.t4 => 'T4',
    GoalTimeline.annual => 'ANUAL',
  };

  static String _priorityApi(GoalPriority priority) => switch (priority) {
    GoalPriority.grande => 'GRANDE',
    GoalPriority.pequeno => 'PEQUENO',
    GoalPriority.niceToHave => 'NICE_TO_HAVE',
  };

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
