import 'package:flutter/widgets.dart';

/// Maps a horizontal swipe to the previous or next period.
///
/// Wraps a whole screen (or a period panel) so the month/year can be changed
/// by swiping, not only through the arrows. Vertical scrolling and taps pass
/// through untouched.
class PeriodSwipeDetector extends StatelessWidget {
  const PeriodSwipeDetector({
    super.key,
    required this.child,
    this.onPrevious,
    this.onNext,
  });

  final Widget child;

  /// Called on a rightward swipe; null disables it.
  final VoidCallback? onPrevious;

  /// Called on a leftward swipe; null disables it.
  final VoidCallback? onNext;

  static const double _minimumVelocity = 200;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > _minimumVelocity) {
          onPrevious?.call();
        } else if (velocity < -_minimumVelocity) {
          onNext?.call();
        }
      },
      child: child,
    );
  }
}
