import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A static placeholder block used in loading states.
class AppSkeleton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lineSoft,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}
