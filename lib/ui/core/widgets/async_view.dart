import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_empty_state.dart';
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
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyMessage;
  final IconData emptyIcon;

  /// The optional label of the empty state's action button.
  final String? emptyActionLabel;

  /// Called when the empty state's action button is pressed.
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingSkeleton();
    }
    final error = errorMessage;
    if (error != null) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: 'Não foi possível carregar',
        message: error,
        actionLabel: 'Tentar de novo',
        onAction: onRetry,
      );
    }
    if (isEmpty) {
      return AppEmptyState(
        icon: emptyIcon,
        title: emptyMessage,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
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
        AppSkeleton(
          height: AppSizes.skeletonHeadingHeight,
          width: AppSizes.skeletonHeadingWidth,
        ),
        SizedBox(height: AppSpacing.md),
        AppSkeleton(),
        SizedBox(height: AppSpacing.sm),
        AppSkeleton(),
        SizedBox(height: AppSpacing.sm),
        AppSkeleton(width: AppSizes.skeletonShortWidth),
      ],
    );
  }
}
