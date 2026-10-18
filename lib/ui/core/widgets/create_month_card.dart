import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_button.dart';
import 'package:nest/ui/core/widgets/app_card.dart';
import 'package:nest/ui/core/widgets/app_error_banner.dart';

/// The "create this month" call to action shown when a month has no saved plan.
///
/// Shared by the expense and goal month screens; [description] explains what
/// creating the month copies.
class CreateMonthCard extends StatelessWidget {
  const CreateMonthCard({
    super.key,
    required this.description,
    required this.isBusy,
    required this.onCreate,
    this.errorMessage,
  });

  /// The explanatory line under the heading.
  final String description;

  /// True while the create request is in flight.
  final bool isBusy;

  /// The last create failure, if any.
  final String? errorMessage;

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final error = errorMessage;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mês não criado', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.md),
          Text(description, style: AppTextStyles.bodyMuted(context.colors)),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBanner(message: error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Criar mês',
            icon: Icons.add,
            isLoading: isBusy,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}
