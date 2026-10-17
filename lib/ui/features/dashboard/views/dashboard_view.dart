import 'package:flutter/material.dart';
import 'package:nest/config/app_constants.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:nest/ui/features/people/views/people_view.dart';

/// The first screen: a read-only operational snapshot.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  DashboardViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _viewModel = DashboardViewModel(
      peopleRepository: dependencies.peopleRepository,
      accountsRepository: dependencies.accountsRepository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: viewModel.isEmpty,
            onRetry: viewModel.load,
            emptyMessage: 'Ainda não há dados para mostrar.',
            child: _DashboardContent(viewModel: viewModel),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumo', style: AppTextStyles.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        Text('Visão geral do agregado.', style: AppTextStyles.bodyMuted),
        const SizedBox(height: AppSpacing.lg),
        _StatGrid(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Gerir pessoas',
          icon: Icons.people_outline,
          variant: AppButtonVariant.secondary,
          onPressed: () => _openPeople(context),
        ),
      ],
    );
  }

  void _openPeople(BuildContext context) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const PeopleView()));
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      AppStatCard(
        label: 'Membros',
        value: '${viewModel.peopleCount}',
        icon: Icons.people_outline,
        accent: AppColors.primary,
      ),
      AppStatCard(
        label: 'Contas',
        value: '${viewModel.accountsCount}',
        icon: Icons.account_balance_outlined,
        accent: AppColors.terraDark,
      ),
      AppStatCard(
        label: 'Contas conjuntas',
        value: '${viewModel.jointAccountsCount}',
        icon: Icons.groups_outlined,
        accent: AppColors.inkSoft,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.md) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index != cards.length - 1)
                const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}
