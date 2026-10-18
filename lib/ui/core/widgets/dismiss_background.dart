import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// The red delete affordance revealed behind a swipe-to-dismiss row.
///
/// Use as a `Dismissible`'s `background` ([Alignment.centerLeft]) and
/// `secondaryBackground` ([Alignment.centerRight]).
class DismissBackground extends StatelessWidget {
  const DismissBackground({super.key, required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.dangerSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(
        Icons.delete_outline,
        size: AppSizes.iconLarge,
        color: context.colors.dangerOnSoft,
      ),
    );
  }
}
