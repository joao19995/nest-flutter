import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A dark, gradient-backed panel that hosts the headline figure of a screen.
///
/// Keeps every hero (year, month, household) identical in surface, padding
/// and depth so the tabs share one visual language.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppBreakpoints.cardPadding(context)),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.card(context.colors),
      ),
      child: child,
    );
  }
}
