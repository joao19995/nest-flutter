import 'package:flutter/material.dart';
import 'package:nest/domain/models/goal_year_summary.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/goal_badges.dart';
import 'package:nest/ui/features/goals/goal_icons.dart';
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
    final colors = context.colors;
    final complete = goal.progress >= 1;
    final projection = goal.projection;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          if (goal.hasTarget)
            AppProgressRing(
              progress: goal.progress,
              size: AppSizes.progressRingSmall,
              strokeWidth: AppSizes.progressRingSmallStroke,
              color: complete ? colors.primaryDark : colors.primary,
              trackColor: colors.lineSoft,
              label: AppFormatters.percentage((goal.progress * 100).round()),
              labelColor: colors.ink,
            )
          else
            Icon(
              Icons.flag_outlined,
              size: AppSizes.iconDisplay,
              color: colors.faint,
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GoalIcon(
                      name: goal.name,
                      iconKey: goal.iconKey,
                      size: AppSizes.goalIconSmall,
                      iconSize: AppSizes.iconSmall,
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
                if (goal.timeline != null || goal.priority != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GoalMetaChips(
                    timeline: goal.timeline,
                    priority: goal.priority,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                if (complete)
                  const _CompleteIndicator()
                else
                  _TargetLine(goal: goal),
                if (projection != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _ProjectionLine(projection: projection),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The server's projected completion at the current pace, when available.
class _ProjectionLine extends StatelessWidget {
  const _ProjectionLine({required this.projection});

  final GoalCompletionProjection projection;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ao ritmo atual, chegas a '
      '${AppFormatters.currency(projection.projectedAmount)} em '
      '${AppFormatters.monthKeyTitle(projection.projectedMonth)}',
      style: AppTextStyles.small(context.colors),
    );
  }
}

/// The "Completo" badge with a one-shot saved tick.
class _CompleteIndicator extends StatefulWidget {
  const _CompleteIndicator();

  @override
  State<_CompleteIndicator> createState() => _CompleteIndicatorState();
}

class _CompleteIndicatorState extends State<_CompleteIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.large);
    _animation = CurvedAnimation(parent: _controller, curve: AppMotion.easing);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBadge(label: 'Completo', style: AppBadgeStyles.open(context.colors)),
        const SizedBox(width: AppSpacing.xs),
        AppSavedTick(animation: _animation),
      ],
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
    return Text(
      'Falta ${AppFormatters.currency(goal.missing)} '
      'de ${AppFormatters.currency(goal.target)}',
      style: AppTextStyles.small(context.colors),
    );
  }
}
