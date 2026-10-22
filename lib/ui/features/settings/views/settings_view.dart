import 'package:flutter/material.dart';
import 'package:nest/config/app_constants.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';

/// App preferences: appearance and product information.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = DependenciesScope.of(context).settingsController;
    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: Padding(
        padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Aparência',
                            style: AppTextStyles.sectionHeading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('Sistema'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Claro'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Escuro'),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (selection) =>
                                settings.setThemeMode(selection.first),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sobre',
                            style: AppTextStyles.sectionHeading,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            AppConstants.appName,
                            style: AppTextStyles.body.copyWith(
                              color: context.colors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Companheiro de finanças da casa para o dia a dia.',
                            style: AppTextStyles.bodyMuted(context.colors),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
