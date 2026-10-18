import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/view_models/goals_view_model.dart';

/// The per-goal accumulation for a year: how much each goal has reserved
/// against its annual target.
class GoalsBreakdownView extends StatelessWidget {
  const GoalsBreakdownView({
    super.key,
    required this.year,
    required this.goals,
  });

  final int year;
  final List<GoalSummary> goals;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acumulado')),
      body: Padding(
        padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Objetivos de $year',
                    style: AppTextStyles.navSection(context.colors),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GoalsCard(goals: goals),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals});

  final List<GoalSummary> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return AppCard(
        child: Text(
          'Ainda não há objetivos.',
          style: AppTextStyles.bodyMuted(context.colors),
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppBreakpoints.cardPadding(context),
        vertical: AppSpacing.sm,
      ),
      child: AppStagger(
        children: [
          for (var index = 0; index < goals.length; index++)
            _GoalRow(goal: goals[index]),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final GoalSummary goal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: AppTextStyles.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                AppFormatters.currency(goal.reserved),
                style: AppTextStyles.sectionHeading.copyWith(
                  color: context.colors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: AppSizes.progressBarHeight,
              backgroundColor: context.colors.lineSoft,
              color: goal.hasTarget && goal.progress >= 1
                  ? context.colors.primaryDark
                  : context.colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _TargetLine(goal: goal),
        ],
      ),
    );
  }
}

/// A subtle line: the goal's progress against its annual target.
class _TargetLine extends StatelessWidget {
  const _TargetLine({required this.goal});

  final GoalSummary goal;

  @override
  Widget build(BuildContext context) {
    if (!goal.hasTarget) {
      return Text('Sem orçamento', style: AppTextStyles.small(context.colors));
    }
    if (goal.missing <= 0.005) {
      return Text(
        'Completo · ${AppFormatters.currency(goal.target)}',
        style: AppTextStyles.small(context.colors).copyWith(
          color: context.colors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      'Falta ${AppFormatters.currency(goal.missing)} '
      'de ${AppFormatters.currency(goal.target)}',
      style: AppTextStyles.small(context.colors),
    );
  }
}
