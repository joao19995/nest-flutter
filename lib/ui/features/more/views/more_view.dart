import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/accounts/views/accounts_view.dart';
import 'package:nest/ui/features/people/views/people_view.dart';
import 'package:nest/ui/features/settings/views/settings_view.dart';

/// The "Mais" hub: the overflow destination for the occasional screens that do
/// not deserve a permanent tab on small viewports. Each entry pushes its own
/// screen over the shell.
class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: Padding(
        padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MoreTile(
                  icon: Icons.people_outline,
                  label: 'Pessoas',
                  onTap: () => _push(context, const PeopleView()),
                ),
                const SizedBox(height: AppSpacing.md),
                _MoreTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Contas',
                  onTap: () => _push(context, const AccountsView()),
                ),
                const SizedBox(height: AppSpacing.md),
                _MoreTile(
                  icon: Icons.settings_outlined,
                  label: 'Definições',
                  onTap: () => _push(context, const SettingsView()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget view) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => view));
  }
}

/// A single tappable entry in the "Mais" hub.
class _MoreTile extends StatelessWidget {
  const _MoreTile({
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
