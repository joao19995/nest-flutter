import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A standard Nest surface: white fill, hairline border, subtle card shadow.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(AppBreakpoints.cardPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}
