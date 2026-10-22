import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_card.dart';
import 'package:nest/ui/core/widgets/app_error_banner.dart';

/// Shared list of template versions, used by the expense and goal editors.
///
/// Each version is a tappable row with its month and a caller-provided
/// subtitle, so both features keep their own domain wording.
class TemplateVersionsList<T> extends StatelessWidget {
  const TemplateVersionsList({
    super.key,
    required this.templates,
    required this.monthLabel,
    required this.subtitle,
    required this.onTap,
    this.errorMessage,
    this.onDismissError,
  });

  final List<T> templates;
  final String Function(T template) monthLabel;
  final String Function(T template) subtitle;
  final ValueChanged<T> onTap;
  final String? errorMessage;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    final error = errorMessage;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            AppErrorBanner(message: error, onDismiss: onDismissError),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            padding: EdgeInsets.symmetric(
              horizontal: AppBreakpoints.cardPadding(context),
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                for (var index = 0; index < templates.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _TemplateVersionRow(
                    month: monthLabel(templates[index]),
                    subtitle: subtitle(templates[index]),
                    onTap: () => onTap(templates[index]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateVersionRow extends StatelessWidget {
  const _TemplateVersionRow({
    required this.month,
    required this.subtitle,
    required this.onTap,
  });

  final String month;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(month, style: AppTextStyles.sectionHeading),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMuted(context.colors),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppSizes.iconMedium,
                color: context.colors.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
