import 'package:flutter/widgets.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// Slides the period content horizontally when [period] changes.
///
/// Mirrors the month pager's transition: moving forward brings the new content
/// in from the right, moving back brings it in from the left. The period key
/// must sort chronologically (e.g. `2026` or `2026-10`).
class AnimatedPeriodSwitcher extends StatefulWidget {
  const AnimatedPeriodSwitcher({
    super.key,
    required this.period,
    required this.child,
  });

  final String period;
  final Widget child;

  @override
  State<AnimatedPeriodSwitcher> createState() => _AnimatedPeriodSwitcherState();
}

class _AnimatedPeriodSwitcherState extends State<AnimatedPeriodSwitcher> {
  int _direction = 1;

  @override
  void didUpdateWidget(covariant AnimatedPeriodSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      _direction = widget.period.compareTo(oldWidget.period) > 0 ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodKey = ValueKey(widget.period);
    return AnimatedSwitcher(
      duration: AppMotion.dialog,
      switchInCurve: AppMotion.easing,
      switchOutCurve: AppMotion.easing,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == periodKey;
        final begin = Offset(
          (incoming ? _direction : -_direction).toDouble(),
          0,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: KeyedSubtree(key: periodKey, child: widget.child),
    );
  }
}
