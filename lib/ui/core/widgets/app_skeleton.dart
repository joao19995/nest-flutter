import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A placeholder block used in loading states; it pulses gently.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.height = AppSpacing.lg,
    this.width,
    this.radius = AppRadius.sm,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.pulse,
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.colors.lineSoft,
          borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
        ),
      ),
    );
  }
}
