import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A standard Nest surface: white fill, hairline border, subtle card shadow.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// When provided, the whole card becomes tappable with an ink ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? EdgeInsets.all(AppBreakpoints.cardPadding(context)),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.mdAll,
                child: content,
              ),
            ),
    );
  }
}
