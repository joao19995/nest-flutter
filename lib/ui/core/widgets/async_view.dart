import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_button.dart';
import 'package:nest/ui/core/widgets/app_skeleton.dart';

/// Renders the four mandatory async states for a screen: loading, error,
/// empty and data. There is no acceptable blank screen or silent failure.
class AsyncView extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
    this.emptyMessage = 'Sem dados.',
    this.emptyIcon = Icons.inbox_outlined,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingSkeleton();
    }
    final error = errorMessage;
    if (error != null) {
      return _StateMessage(
        icon: Icons.error_outline,
        title: 'Não foi possível carregar',
        message: error,
        action: AppButton(
          label: 'Tentar de novo',
          icon: Icons.refresh,
          onPressed: onRetry,
        ),
      );
    }
    if (isEmpty) {
      return _StateMessage(icon: emptyIcon, title: emptyMessage);
    }
    return child;
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton(height: 20, width: 180),
        SizedBox(height: AppSpacing.md),
        AppSkeleton(),
        SizedBox(height: AppSpacing.sm),
        AppSkeleton(),
        SizedBox(height: AppSpacing.sm),
        AppSkeleton(width: 220),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final action = this.action;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconDisplay, color: context.colors.faint),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionHeading,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted(context.colors),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
