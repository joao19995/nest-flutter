import 'package:flutter/material.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_chip.dart';

/// Display helpers for a goal's timeline.
extension GoalTimelineStyle on GoalTimeline {
  /// The compact label shown in forms and chips.
  String get label => switch (this) {
    GoalTimeline.t1 => 'T1',
    GoalTimeline.t2 => 'T2',
    GoalTimeline.t3 => 'T3',
    GoalTimeline.t4 => 'T4',
    GoalTimeline.annual => 'Anual',
  };

  /// The badge colours for this timeline.
  BadgeStyle badgeStyle(NestColors colors) => switch (this) {
    GoalTimeline.t1 => AppBadgeStyles.open(colors),
    GoalTimeline.t2 => AppBadgeStyles.closed(colors),
    GoalTimeline.t3 => AppBadgeStyles.outline(colors),
    GoalTimeline.t4 => AppBadgeStyles.muted(colors),
    GoalTimeline.annual => AppBadgeStyles.closed(colors),
  };
}

/// Display helpers for a goal's priority.
extension GoalPriorityStyle on GoalPriority {
  /// The label shown in forms and chips.
  String get label => switch (this) {
    GoalPriority.grande => 'Grande',
    GoalPriority.pequeno => 'Pequeno',
    GoalPriority.niceToHave => 'Nice to have',
  };

  /// The badge colours for this priority.
  BadgeStyle badgeStyle(NestColors colors) => switch (this) {
    GoalPriority.grande => AppBadgeStyles.destructive(colors),
    GoalPriority.pequeno => AppBadgeStyles.open(colors),
    GoalPriority.niceToHave => AppBadgeStyles.muted(colors),
  };
}

/// The timeline and priority chips for a goal, when the template supplies them.
class GoalMetaChips extends StatelessWidget {
  const GoalMetaChips({super.key, this.timeline, this.priority});

  final GoalTimeline? timeline;
  final GoalPriority? priority;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final timeline = this.timeline;
    final priority = this.priority;
    if (timeline == null && priority == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        if (timeline != null)
          AppChip(label: timeline.label, style: timeline.badgeStyle(colors)),
        if (priority != null)
          AppChip(label: priority.label, style: priority.badgeStyle(colors)),
      ],
    );
  }
}
