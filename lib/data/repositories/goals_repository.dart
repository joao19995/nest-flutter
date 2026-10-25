import 'package:nest/data/models/goal_close_preview_model.dart';
import 'package:nest/data/models/goal_model.dart';
import 'package:nest/data/models/goal_month_model.dart';
import 'package:nest/data/models/goal_template_model.dart';
import 'package:nest/data/models/goal_year_model.dart';
import 'package:nest/data/models/goal_year_summary_model.dart';
import 'package:nest/data/models/json_mapper.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/domain/models/goal_close_preview.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/domain/models/goal_year.dart';
import 'package:nest/domain/models/goal_year_summary.dart';

/// Reads the savings goals and their yearly plans.
class GoalsRepository {
  GoalsRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns the goal catalogue. Soft-deleted goals are excluded unless
  /// [includeInactive].
  Future<List<Goal>> fetchGoals({bool includeInactive = false}) async {
    final path = includeInactive
        ? '/api/goals?includeInactive=true'
        : '/api/goals';
    final data = await _client.get(path);
    return mapJsonList(data, (json) => GoalModel.fromJson(json).toDomain());
  }

  /// Creates a goal in the catalogue, optionally with an [iconKey].
  Future<Goal> createGoal({required String name, String? iconKey}) async {
    final data = await _client.post('/api/goals', {
      'name': name,
      'iconKey': ?iconKey,
    });
    return mapJson(data, (json) => GoalModel.fromJson(json).toDomain());
  }

  /// Renames [id] and, when given, updates its [iconKey].
  Future<Goal> updateGoal(
    String id, {
    required String name,
    String? iconKey,
  }) async {
    final data = await _client.put('/api/goals/$id', {
      'name': name,
      'iconKey': ?iconKey,
    });
    return mapJson(data, (json) => GoalModel.fromJson(json).toDomain());
  }

  /// Soft-deletes the goal [id] (sets `active = false`). Fails with a 409 when
  /// a template version still funds the goal for an open month.
  Future<void> deleteGoal(String id) => _client.delete('/api/goals/$id');

  /// Restores a soft-deleted goal [id].
  Future<Goal> restoreGoal(String id) async {
    final data = await _client.post('/api/goals/$id/restore', const {});
    return mapJson(data, (json) => GoalModel.fromJson(json).toDomain());
  }

  /// Returns the annual goal-template versions, oldest first.
  Future<List<GoalTemplate>> fetchGoalTemplates() async {
    final data = await _client.get('/api/goal-templates');
    return mapJsonList(
      data,
      (json) => GoalTemplateModel.fromJson(json).toDomain(),
    );
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
    return mapJson(
      data,
      (json) => GoalTemplateModel.fromJson(
        requireJsonObject(json['template']),
      ).toDomain(),
    );
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
    return mapJson(
      data,
      (json) => GoalTemplateModel.fromJson(
        requireJsonObject(json['template']),
      ).toDomain(),
    );
  }

  /// Returns the goal-template version in force for [month] (`YYYY-MM`), or
  /// `null` when none applies. Server-side domain rule (`resolveApplicableGoalTemplate`).
  Future<GoalTemplate?> fetchApplicableGoalTemplate(String month) async {
    final data = await _client.get(
      '/api/goal-templates/applicable?month=$month',
    );
    return mapJson(data, (json) {
      final template = json['template'];
      if (template is! Map<String, dynamic>) {
        return null;
      }
      return GoalTemplateModel.fromJson(template).toDomain();
    });
  }

  /// Returns the saved plans and funding of [year].
  Future<GoalYear> fetchGoalYear(int year) async {
    final data = await _client.get('/api/goal-plan?year=$year');
    return mapJson(data, (json) => GoalYearModel.fromJson(json).toDomain());
  }

  /// Returns the server's yearly goals panorama for [year], including each
  /// goal's completion projection.
  Future<GoalYearSummary> fetchGoalYearSummary(int year) async {
    final data = await _client.get('/api/goal-plan/summary?year=$year');
    return mapJson(
      data,
      (json) => GoalYearSummaryModel.fromJson(json).toDomain(),
    );
  }

  /// Returns the full view of [month] (`YYYY-MM`) — plan, available amount and
  /// per-person quotas — or `null` when the month has not been created.
  Future<GoalMonthView?> fetchGoalMonth(String month) async {
    try {
      final data = await _client.get('/api/goal-plan/$month');
      return mapJson(data, (json) => GoalMonthModel.fromJson(json).toDomain());
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
    return mapJson(data, (json) => GoalPlanModel.fromJson(json).toDomain());
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
    return mapJson(data, (json) => GoalMonthModel.fromJson(json).toDomain());
  }

  /// Previews what closing [month] (`YYYY-MM`) would do, without writing.
  Future<GoalClosePreview> fetchGoalClosePreview(String month) async {
    final data = await _client.get('/api/goal-plan/$month/close-preview');
    return mapJson(
      data,
      (json) => GoalClosePreviewModel.fromJson(json).toDomain(),
    );
  }

  /// Closes [month] (`YYYY-MM`) and returns the frozen month view.
  Future<GoalMonthView> closeGoalPlan(String month) async {
    final data = await _client.post('/api/goal-plan/$month/close', const {});
    return mapJson(data, (json) => GoalMonthModel.fromJson(json).toDomain());
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
}
