import 'package:flutter/material.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/monthly_plan.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/expenses/view_models/month_detail_view_model.dart';

/// The detail of a single month: its planned vs. actual spend and, once the
/// month is closed, the contributions snapshot.
class MonthDetailView extends StatefulWidget {
  const MonthDetailView({super.key, required this.month});

  /// The month to open, formatted `YYYY-MM`.
  final String month;

  @override
  State<MonthDetailView> createState() => _MonthDetailViewState();
}

class _MonthDetailViewState extends State<MonthDetailView> {
  MonthDetailViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _viewModel = MonthDetailViewModel(
      expensesRepository: dependencies.expensesRepository,
      month: widget.month,
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
      appBar: AppBar(title: const Text('Despesas mensais')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthHero(
                month: viewModel.month,
                plan: viewModel.plan,
                onPreviousMonth: viewModel.showPreviousMonth,
                onNextMonth: viewModel.showNextMonth,
              ),
              const SizedBox(height: AppSpacing.lg),
              _MonthBody(viewModel: viewModel),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthBody extends StatelessWidget {
  const _MonthBody({required this.viewModel});

  final MonthDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final plan = viewModel.plan;
    if (plan != null) {
      return _PlanContent(viewModel: viewModel, plan: plan);
    }
    if (viewModel.isLoading || viewModel.errorMessage != null) {
      return AsyncView(
        isLoading: viewModel.isLoading,
        errorMessage: viewModel.errorMessage,
        isEmpty: false,
        onRetry: viewModel.load,
        child: const SizedBox.shrink(),
      );
    }
    return _CreateMonthCard(viewModel: viewModel);
  }
}

class _PlanContent extends StatelessWidget {
  const _PlanContent({required this.viewModel, required this.plan});

  final MonthDetailViewModel viewModel;
  final MonthlyPlan plan;

  @override
  Widget build(BuildContext context) {
    final settlement = plan.settlement;
    final actionError = viewModel.actionError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actionError != null) ...[
          _ErrorBanner(message: actionError),
          const SizedBox(height: AppSpacing.lg),
        ],
        _EntriesCard(
          plan: plan,
          isBusy: viewModel.isBusy,
          onClose: viewModel.closeMonth,
          onSaveActual: viewModel.updateEntryActual,
        ),
        if (plan.closed && settlement != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ContributionsCard(settlement: settlement),
        ],
      ],
    );
  }
}

/// Shown when the selected month has not been created yet.
class _CreateMonthCard extends StatelessWidget {
  const _CreateMonthCard({required this.viewModel});

  final MonthDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final actionError = viewModel.actionError;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.event_busy_outlined,
            title: 'Mês não criado',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ao criar, copia-se o template aplicável a '
            '${AppFormatters.monthName(viewModel.month)}. '
            'O planeado fica logo fixo.',
            style: AppTextStyles.bodyMuted,
          ),
          if (actionError != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ErrorBanner(message: actionError),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Criar mês',
            icon: Icons.add,
            isLoading: viewModel.isBusy,
            onPressed: viewModel.createMonth,
          ),
        ],
      ),
    );
  }
}

/// A coral panel stating why the last write action failed.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppSizes.iconMedium,
            color: AppColors.dangerOnSoft,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.small.copyWith(
                color: AppColors.dangerOnSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The summary panel: real total, month selector and deviation.
class _MonthHero extends StatelessWidget {
  const _MonthHero({
    required this.month,
    required this.plan,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String month;
  final MonthlyPlan? plan;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final plan = this.plan;
    return Container(
      padding: EdgeInsets.all(AppBreakpoints.cardPadding(context)),
      decoration: const BoxDecoration(
        color: AppColors.mint,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DESPESA DO MÊS',
                  style: AppTextStyles.navSection.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _MonthStepper(
                month: month,
                onPrevious: onPreviousMonth,
                onNext: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _HeroValue(actual: plan?.actual ?? 0, planned: plan?.planned),
          if (plan != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _DeviationLine(plan: plan)),
                const SizedBox(width: AppSpacing.md),
                AppBadge(
                  label: plan.closed ? 'Fechado' : 'Aberto',
                  style: plan.closed
                      ? AppBadgeStyles.closed
                      : AppBadgeStyles.open,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The real total, with the planned total trailing it in small type.
class _HeroValue extends StatelessWidget {
  const _HeroValue({required this.actual, required this.planned});

  final double actual;
  final double? planned;

  @override
  Widget build(BuildContext context) {
    final planned = this.planned;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: AppFormatters.currency(actual),
            style: AppTextStyles.statDisplay.copyWith(color: AppColors.primary),
          ),
          if (planned != null)
            TextSpan(
              text: '  / ${AppFormatters.currency(planned)}',
              style: AppTextStyles.small.copyWith(color: AppColors.primaryDark),
            ),
        ],
      ),
    );
  }
}

/// A subtle line: how far the month's real spend deviates from the plan.
class _DeviationLine extends StatelessWidget {
  const _DeviationLine({required this.plan});

  final MonthlyPlan plan;

  @override
  Widget build(BuildContext context) {
    final diff = plan.diff;
    final over = plan.isOver;
    final under = diff < -0.005;
    if (!over && !under) {
      return Text(
        'No planeado',
        style: AppTextStyles.small.copyWith(color: AppColors.primaryDark),
      );
    }
    final pct = plan.planned > 0 ? (diff / plan.planned * 100) : 0.0;
    final sign = diff > 0 ? '+' : '';
    final direction = over ? 'acima' : 'abaixo';
    return Text(
      'Desvio $sign${AppFormatters.currency(diff)}  ·  '
      '${AppFormatters.percentage(pct.abs().round())} $direction',
      style: AppTextStyles.small.copyWith(
        color: over ? AppColors.over : AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The month selector: previous arrow, month name, next arrow.
class _MonthStepper extends StatelessWidget {
  const _MonthStepper({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final String month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIconButton(icon: Icons.chevron_left, onTap: onPrevious),
          Text(
            AppFormatters.monthName(month),
            style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
          ),
          _StepperIconButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          icon,
          size: AppSizes.iconMedium,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _EntriesCard extends StatelessWidget {
  const _EntriesCard({
    required this.plan,
    required this.isBusy,
    required this.onClose,
    required this.onSaveActual,
  });

  final MonthlyPlan plan;
  final bool isBusy;
  final VoidCallback onClose;
  final void Function(String entryId, double actual) onSaveActual;

  @override
  Widget build(BuildContext context) {
    final entries = plan.entries;
    final editable = !plan.closed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeading(
            icon: Icons.receipt_long_outlined,
            title: 'Despesas',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            Text('Este mês não tem categorias.', style: AppTextStyles.bodyMuted)
          else
            for (var index = 0; index < entries.length; index++) ...[
              if (index > 0) const Divider(),
              _EntryRow(
                entry: entries[index],
                onSaveActual: editable ? onSaveActual : null,
              ),
            ],
          if (editable) ...[
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Fechar mês',
                icon: Icons.lock_outlined,
                isLoading: isBusy,
                onPressed: () => _confirmClose(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Fechar ${AppFormatters.monthName(plan.month)}?'),
        content: const Text('Depois de fechado não pode ser alterado.'),
        actions: [
          AppButton(
            label: 'Cancelar',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton(
            label: 'Fechar mês',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onClose();
    }
  }
}

class _EntryRow extends StatefulWidget {
  const _EntryRow({required this.entry, required this.onSaveActual});

  final MonthlyPlanEntry entry;

  /// When provided, the real amount is editable and saved on focus loss.
  final void Function(String entryId, double actual)? onSaveActual;

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.entry.actual));
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.entry.actual != oldWidget.entry.actual) {
      _controller.text = _format(widget.entry.actual);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _save();
    }
  }

  void _save() {
    final onSaveActual = widget.onSaveActual;
    if (onSaveActual == null) {
      return;
    }
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || parsed < 0) {
      _controller.text = _format(widget.entry.actual);
      return;
    }
    if (parsed == widget.entry.actual) {
      return;
    }
    onSaveActual(widget.entry.id, parsed);
  }

  static String _format(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final editable = widget.onSaveActual != null;
    final accent = entry.isOver ? AppColors.over : AppColors.ink;
    final diff = entry.diff;
    final deltaLabel = diff >= 0
        ? '+${AppFormatters.currency(diff)}'
        : AppFormatters.currency(diff);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.categoryName,
                      style: AppTextStyles.sectionHeading,
                    ),
                    if (editable) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Planeado ${AppFormatters.currency(entry.planned)}',
                        style: AppTextStyles.small,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (editable)
                    SizedBox(
                      width: AppSizes.moneyFieldWidth,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.end,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                        decoration: const InputDecoration(
                          isDense: true,
                          suffixText: '€',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    )
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: AppFormatters.currency(entry.actual),
                            style: AppTextStyles.sectionHeading.copyWith(
                              color: accent,
                            ),
                          ),
                          TextSpan(
                            text:
                                '  / ${AppFormatters.currency(entry.planned)}',
                            style: AppTextStyles.small,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    deltaLabel,
                    style: AppTextStyles.small.copyWith(
                      color: entry.isOver
                          ? AppColors.over
                          : AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value: entry.progress,
              minHeight: AppSizes.progressBarHeight,
              backgroundColor: AppColors.lineSoft,
              color: entry.isOver ? AppColors.over : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionsCard extends StatelessWidget {
  const _ContributionsCard({required this.settlement});

  final MonthSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final isOk = settlement.status == SettlementStatus.ok;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeading(
            icon: Icons.payments_outlined,
            title: 'Contribuições',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!isOk)
            Text(
              settlement.message ?? 'Sem rendimento registado.',
              style: AppTextStyles.bodyMuted,
            )
          else
            for (var index = 0; index < settlement.people.length; index++) ...[
              if (index > 0) const Divider(),
              _ContributionRow(person: settlement.people[index]),
            ],
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.person});

  final MonthSettlementPerson person;

  @override
  Widget build(BuildContext context) {
    final transfer = _transfer();
    final amount = transfer.amount;
    final name = person.personName.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          _InitialAvatar(initial: initial),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.personName, style: AppTextStyles.sectionHeading),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  transfer.direction,
                  style: AppTextStyles.small.copyWith(color: transfer.color),
                ),
              ],
            ),
          ),
          if (amount != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              AppFormatters.currency(amount),
              style: AppTextStyles.sectionHeading.copyWith(
                color: transfer.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({double? amount, String direction, Color color}) _transfer() {
    if (person.transfersToJoint) {
      return (
        amount: person.transferToJoint,
        direction: 'para a conta conjunta',
        color: AppColors.primaryDark,
      );
    }
    if (person.transfersToPerson) {
      return (
        amount: person.transferToPerson,
        direction: 'da conta conjunta',
        color: AppColors.primaryDark,
      );
    }
    return (amount: null, direction: 'Está certo', color: AppColors.muted);
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSizes.buttonHeight,
          height: AppSizes.buttonHeight,
          decoration: const BoxDecoration(
            color: AppColors.mintSoft,
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(
            icon,
            size: AppSizes.iconMedium,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(title, style: AppTextStyles.sectionHeading),
      ],
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.buttonHeight,
      height: AppSizes.buttonHeight,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.terraSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyles.label.copyWith(color: AppColors.terraDark),
      ),
    );
  }
}
