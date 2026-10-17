import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// Reveals its [children] one after another with a fade and an 8 px slide.
///
/// A single controller drives the whole group, so the entrance is timer-free
/// (it settles predictably in tests). Children added after the first run
/// appear immediately rather than re-animating the list.
class AppStagger extends StatefulWidget {
  const AppStagger({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<AppStagger> createState() => _AppStaggerState();
}

class _AppStaggerState extends State<AppStagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _totalDuration,
  )..forward();

  Duration get _totalDuration {
    final count = widget.children.length;
    if (count <= 1) {
      return AppMotion.entry;
    }
    return AppMotion.entry + AppMotion.stagger * (count - 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (var index = 0; index < count; index++)
          _StaggerItem(
            animation: _controller,
            index: index,
            count: count,
            child: widget.children[index],
          ),
      ],
    );
  }
}

class _StaggerItem extends StatelessWidget {
  const _StaggerItem({
    required this.animation,
    required this.index,
    required this.count,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final entryMs = AppMotion.entry.inMilliseconds;
    final staggerMs = AppMotion.stagger.inMilliseconds;
    final totalMs = entryMs + staggerMs * (count - 1);
    final start = count <= 1 ? 0.0 : (staggerMs * index) / totalMs;
    final end = (start + entryMs / totalMs).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: AppMotion.easing),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * AppSpacing.sm),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
