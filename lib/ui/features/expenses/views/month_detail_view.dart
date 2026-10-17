import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  /// The page whose month is [MonthDetailView.month]. Pages shift from here,
  /// so the carousel is effectively unbounded.
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
      appBar: AppBar(title: const Text('Despesas mensais')),
      body: PageView.builder(
        controller: _controller,
        itemBuilder: (context, index) => _MonthPage(
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
class _MonthPage extends StatefulWidget {
  const _MonthPage({
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  State<_MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<_MonthPage> {
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
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => SingleChildScrollView(
        padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'expense-month-${viewModel.month}',
              flightShuttleBuilder: _heroShuttle,
              child: MonthSummaryHero(
                title: 'Despesa do mês',
                month: viewModel.month,
                actual: viewModel.plan?.actual ?? 0,
                planned: viewModel.plan?.planned ?? 0,
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
          AppErrorBanner(message: actionError),
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
          Text('Mês não criado', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ao criar, copia-se o template aplicável a '
            '${AppFormatters.monthName(viewModel.month)}. '
            'O planeado fica logo fixo.',
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
          Text('Despesas', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            Text(
              'Este mês não tem categorias.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (var index = 0; index < entries.length; index++)
                  _EntryRow(
                    entry: entries[index],
                    onSaveActual: editable ? onSaveActual : null,
                  ),
              ],
            ),
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

class _EntryRowState extends State<_EntryRow>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(vsync: this, duration: AppMotion.confirm);
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
    _tick.dispose();
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
    HapticFeedback.selectionClick();
    _tick.forward(from: 0);
  }

  static String _format(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final editable = widget.onSaveActual != null;
    final accent = entry.isOver ? context.colors.over : context.colors.ink;
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
              CategoryIcon(category: entry.categoryName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.categoryName,
                      style: AppTextStyles.sectionHeading,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Planeado ${AppFormatters.currency(entry.planned)}',
                      style: AppTextStyles.small(context.colors),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                      AppFormatters.currency(entry.actual),
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: accent,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    deltaLabel,
                    style: AppTextStyles.small(context.colors).copyWith(
                      color: entry.isOver
                          ? context.colors.over
                          : context.colors.primaryDark,
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
              backgroundColor: context.colors.lineSoft,
              color: entry.isOver
                  ? context.colors.over
                  : context.colors.primary,
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
          Text('Contribuições', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (!isOk)
            Text(
              settlement.message ?? 'Sem rendimento registado.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (var index = 0; index < settlement.people.length; index++)
                  _ContributionRow(person: settlement.people[index]),
              ],
            ),
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
    final transfer = _transfer(context.colors);
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
                  style: AppTextStyles.small(
                    context.colors,
                  ).copyWith(color: transfer.color),
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

  ({double? amount, String direction, Color color}) _transfer(
    NestColors colors,
  ) {
    if (person.transfersToJoint) {
      return (
        amount: person.transferToJoint,
        direction: 'para a conta conjunta',
        color: colors.primaryDark,
      );
    }
    if (person.transfersToPerson) {
      return (
        amount: person.transferToPerson,
        direction: 'da conta conjunta',
        color: colors.primaryDark,
      );
    }
    return (amount: null, direction: 'Está certo', color: colors.muted);
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
