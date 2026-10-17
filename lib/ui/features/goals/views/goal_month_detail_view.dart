import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nest/domain/models/goal_transfer.dart';
import 'package:nest/domain/models/goal_year.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/view_models/goal_month_detail_view_model.dart';

/// The detail of a single goals month: what each goal is planned and reserved
/// for, and who transfers what to fund it.
class GoalMonthDetailView extends StatefulWidget {
  const GoalMonthDetailView({super.key, required this.month});

  /// The month to open, formatted `YYYY-MM`.
  final String month;

  @override
  State<GoalMonthDetailView> createState() => _GoalMonthDetailViewState();
}

class _GoalMonthDetailViewState extends State<GoalMonthDetailView> {
  /// The page whose month is [GoalMonthDetailView.month]. Pages shift from
  /// here, so the carousel is effectively unbounded.
  static const int _anchor = 1000;

  late final PageController _controller = PageController(initialPage: _anchor);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objetivos mensais')),
      body: PageView.builder(
        controller: _controller,
        itemBuilder: (context, index) => _GoalMonthPage(
          month: _shift(widget.month, index - _anchor),
          onPreviousMonth: () => _animateBy(-1),
          onNextMonth: () => _animateBy(1),
        ),
      ),
    );
  }

  void _animateBy(int delta) {
    if (!_controller.hasClients) {
      return;
    }
    final current = _controller.page?.round() ?? _anchor;
    _controller.animateToPage(
      current + delta,
      duration: AppMotion.dialog,
      curve: AppMotion.easing,
    );
  }

  /// Shifts a `YYYY-MM` month by [delta] months.
  static String _shift(String month, int delta) {
    final parts = month.split('-');
    final year = int.tryParse(parts.isNotEmpty ? parts[0] : '');
    final monthNumber = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (year == null || monthNumber == null) {
      return month;
    }
    final shifted = DateTime(year, monthNumber + delta);
    return '${shifted.year}-${shifted.month.toString().padLeft(2, '0')}';
  }
}

/// One month in the pager, owning its own presentation state.
class _GoalMonthPage extends StatefulWidget {
  const _GoalMonthPage({
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  State<_GoalMonthPage> createState() => _GoalMonthPageState();
}

class _GoalMonthPageState extends State<_GoalMonthPage> {
  GoalMonthDetailViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _viewModel = GoalMonthDetailViewModel(
      goalsRepository: dependencies.goalsRepository,
      peopleRepository: dependencies.peopleRepository,
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
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => SingleChildScrollView(
        padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'goal-month-${viewModel.month}',
              flightShuttleBuilder: _heroShuttle,
              child: MonthSummaryHero(
                title: 'Objetivos do mês',
                month: viewModel.month,
                actual: viewModel.reserved,
                planned: viewModel.planned,
                closed: viewModel.plan?.closed ?? false,
                hasPlan: viewModel.plan != null,
                onPreviousMonth: widget.onPreviousMonth,
                onNextMonth: widget.onNextMonth,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MonthBody(viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}

/// The Hero flight shows a plain surface that fades from the list's light
/// card into the hero's dark gradient (and back), so the motion reads well in
/// both directions without the complex hero content having to fit the
/// morphing rectangle mid-flight.
Widget _heroShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final surface = flightContext.colors.surface;
      final t = AppMotion.easing.transform(animation.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(surface, AppColors.ink, t)!,
              Color.lerp(surface, AppColors.primaryDark, t)!,
            ],
          ),
          borderRadius: AppRadius.lgAll,
        ),
      );
    },
  );
}

class _MonthBody extends StatelessWidget {
  const _MonthBody({required this.viewModel});

  final GoalMonthDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final plan = viewModel.plan;
    if (plan != null) {
      return _Content(viewModel: viewModel, plan: plan);
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

class _Content extends StatelessWidget {
  const _Content({required this.viewModel, required this.plan});

  final GoalMonthDetailViewModel viewModel;
  final GoalPlan plan;

  @override
  Widget build(BuildContext context) {
    final actionError = viewModel.actionError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actionError != null) ...[
          AppErrorBanner(message: actionError),
          const SizedBox(height: AppSpacing.lg),
        ],
        _GoalsCard(
          plan: plan,
          isBusy: viewModel.isBusy,
          onSaveActual: viewModel.updateAllocationActual,
          onClose: viewModel.closeMonth,
        ),
        const SizedBox(height: AppSpacing.lg),
        _TransfersCard(
          transfers: viewModel.transfers,
          reserved: viewModel.reserved,
        ),
      ],
    );
  }
}

/// Shown when the selected month has not been created yet.
class _CreateMonthCard extends StatelessWidget {
  const _CreateMonthCard({required this.viewModel});

  final GoalMonthDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final actionError = viewModel.actionError;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mês não criado', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ao criar, copia-se o disponível calculado para '
            '${AppFormatters.monthName(viewModel.month)}.',
            style: AppTextStyles.bodyMuted(context.colors),
          ),
          if (actionError != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBanner(message: actionError),
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

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.plan,
    required this.isBusy,
    required this.onSaveActual,
    required this.onClose,
  });

  final GoalPlan plan;
  final bool isBusy;
  final void Function(String goalId, double actual) onSaveActual;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final allocations = plan.allocations;
    final editable = !plan.closed;
    final plannedTotal = allocations.fold<double>(
      0,
      (sum, item) => sum + item.planned,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Objetivos', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (allocations.isEmpty)
            Text(
              'Este mês não tem objetivos.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (var index = 0; index < allocations.length; index++)
                  _GoalRow(
                    allocation: allocations[index],
                    onSaveActual: editable ? onSaveActual : null,
                  ),
              ],
            ),
          if (editable) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _summaryLabel(plan, plannedTotal),
                    style: AppTextStyles.small(context.colors),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: 'Fechar mês',
                  icon: Icons.lock_outlined,
                  isLoading: isBusy,
                  onPressed: () => _confirmClose(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _summaryLabel(GoalPlan plan, double plannedTotal) {
    final missing = plan.availableAmount - plannedTotal;
    final status = missing > 0.005
        ? ' · falta ${AppFormatters.currency(missing)}'
        : missing < -0.005
        ? ' · a mais ${AppFormatters.currency(-missing)}'
        : ' · certo';
    return 'Planeado ${AppFormatters.currency(plannedTotal)} '
        'de ${AppFormatters.currency(plan.availableAmount)}$status · '
        'Reservado ${AppFormatters.currency(plan.reserved)}';
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Guardar e fechar ${AppFormatters.monthName(plan.month)}?'),
        content: const Text('O planeado e o reservado ficam imutáveis.'),
        actions: [
          AppButton(
            label: 'Cancelar',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton(
            label: 'Guardar e fechar',
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

class _GoalRow extends StatefulWidget {
  const _GoalRow({required this.allocation, required this.onSaveActual});

  final GoalAllocation allocation;

  /// When provided, the reserved amount is editable and saved on focus loss.
  final void Function(String goalId, double actual)? onSaveActual;

  @override
  State<_GoalRow> createState() => _GoalRowState();
}

class _GoalRowState extends State<_GoalRow>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(vsync: this, duration: AppMotion.confirm);
    _controller = TextEditingController(text: _format(_displayValue()));
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _GoalRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        widget.allocation.actual != oldWidget.allocation.actual) {
      _controller.text = _format(_displayValue());
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _tick.dispose();
    super.dispose();
  }

  /// Untouched reserved lines default to the planned amount.
  double _displayValue() {
    final allocation = widget.allocation;
    if (widget.onSaveActual != null && allocation.actual == 0) {
      return allocation.planned;
    }
    return allocation.actual;
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
      _controller.text = _format(widget.allocation.actual);
      return;
    }
    if (parsed == widget.allocation.actual) {
      return;
    }
    onSaveActual(widget.allocation.goalId, parsed);
    HapticFeedback.selectionClick();
    _tick.forward(from: 0);
  }

  static String _format(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final allocation = widget.allocation;
    final editable = widget.onSaveActual != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allocation.goalName,
                  style: AppTextStyles.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Planeado ${AppFormatters.currency(allocation.planned)}',
                  style: AppTextStyles.small(context.colors),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (editable)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSavedTick(animation: _tick),
                const SizedBox(width: AppSpacing.sm),
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
                ),
              ],
            )
          else
            Text(
              AppFormatters.currency(allocation.actual),
              style: AppTextStyles.sectionHeading.copyWith(
                color: context.colors.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _TransfersCard extends StatelessWidget {
  const _TransfersCard({required this.transfers, required this.reserved});

  final List<GoalTransfer> transfers;
  final double reserved;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Transferências', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (transfers.isEmpty)
            Text(
              'Sem valores reservados neste mês: nada a transferir.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (var index = 0; index < transfers.length; index++)
                  _TransferRow(transfer: transfers[index], reserved: reserved),
              ],
            ),
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.transfer, required this.reserved});

  final GoalTransfer transfer;
  final double reserved;

  @override
  Widget build(BuildContext context) {
    final name = transfer.name.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final quota = (transfer.share * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialAvatar(initial: initial),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.name,
                      style: AppTextStyles.label(
                        context.colors,
                      ).copyWith(color: context.colors.ink),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ganho ${AppFormatters.currency(transfer.earning)} · '
                      'quota $quota% de ${AppFormatters.currency(reserved)}',
                      style: AppTextStyles.small(context.colors),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Transfere ${AppFormatters.currency(transfer.amount)} '
            'para os objetivos',
            style: AppTextStyles.small(context.colors).copyWith(
              color: context.colors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final part in transfer.parts) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${AppFormatters.currency(part.amount)} para ${part.name}',
              style: AppTextStyles.small(context.colors),
            ),
          ],
        ],
      ),
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
      decoration: BoxDecoration(
        color: context.colors.terraSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyles.label(
          context.colors,
        ).copyWith(color: context.colors.terraDark),
      ),
    );
  }
}
