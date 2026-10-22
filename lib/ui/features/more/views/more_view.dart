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
            child: NavTileGroup(
              tiles: [
                NavTile(
                  icon: Icons.people_outline,
                  label: 'Pessoas',
                  onTap: () => _push(context, const PeopleView()),
                ),
                NavTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Contas',
                  onTap: () => _push(context, const AccountsView()),
                ),
                NavTile(
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
