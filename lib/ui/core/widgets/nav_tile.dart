import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_card.dart';

/// A tappable navigation card: an icon, a label and a trailing chevron.
///
/// Shared by the feature tabs' configuration entry points (goals, expenses).
class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconLarge, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTextStyles.sectionHeading)),
          Icon(
            Icons.chevron_right,
            size: AppSizes.iconLarge,
            color: context.colors.faint,
          ),
        ],
      ),
    );
  }
}

/// Lays out navigation [tiles] in a row on wide viewports and a column on
/// narrow ones, so the entry points stay reachable on a phone.
class NavTileGroup extends StatelessWidget {
  const NavTileGroup({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.sm) {
          return Row(
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: tiles[index]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < tiles.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              tiles[index],
            ],
          ],
        );
      },
    );
  }
}
