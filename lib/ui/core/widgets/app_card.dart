import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A Material 3 elevated card: surface fill, rounded corners and a soft
/// shadow — no hairline border (that pairing is the web look).
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
        color: context.colors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.card(context.colors),
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.lgAll,
                child: content,
              ),
            ),
    );
  }
}
