import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_card.dart';

/// A dashboard metric card: icon chip, large value, and label.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.buttonHeight,
            height: AppSizes.buttonHeight,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: AppSizes.iconLarge, color: accent),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTextStyles.statDisplay.copyWith(color: accent)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.small(context.colors)),
        ],
      ),
    );
  }
}
