import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// The settings hub (Definições): a list of settings, each opening its own
/// screen.
///
/// Placeholder wired into the navigation so the new shell can be reviewed
/// before the sections are built.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: const _ComingSoon(icon: Icons.settings_outlined),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconDisplay, color: context.colors.faint),
          const SizedBox(height: AppSpacing.md),
          Text('Em breve.', style: AppTextStyles.bodyMuted(context.colors)),
        ],
      ),
    );
  }
}
