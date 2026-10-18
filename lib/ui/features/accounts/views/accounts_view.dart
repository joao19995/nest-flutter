import 'package:flutter/material.dart';
import 'package:nest/domain/models/account.dart';
import 'package:nest/domain/models/person.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/accounts/view_models/accounts_view_model.dart';

/// The household bank accounts: the personal ones and the joint ones.
///
/// Each row opens the edit sheet; swiping it away soft-deletes the account and
/// offers an undo. The eye action toggles the soft-deleted accounts so they can
/// be restored.
class AccountsView extends StatefulWidget {
  const AccountsView({super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView>
    with ViewModelState<AccountsView, AccountsViewModel> {
  @override
  AccountsViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return AccountsViewModel(
      accountsRepository: dependencies.accountsRepository,
      peopleRepository: dependencies.peopleRepository,
    );
  }

  @override
  void onViewModelCreated(AccountsViewModel viewModel) => viewModel.load();

  Future<void> _openForm(Account? account) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _AccountFormSheet(
        initialName: account?.name ?? '',
        initialOwnerId: account?.ownerPersonId,
        isEditing: account != null,
        people: viewModel.people,
        onSave: (name, ownerPersonId) => account == null
            ? viewModel.createAccount(name: name, ownerPersonId: ownerPersonId)
            : viewModel.updateAccount(
                account,
                name: name,
                ownerPersonId: ownerPersonId,
              ),
        onDelete: account == null ? null : () => _deleteWithUndo(account),
      ),
    );
  }

  Future<void> _deleteWithUndo(Account account) async {
    final deleted = await viewModel.deleteAccount(account);
    if (!deleted || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${account.name}" apagada.'),
          action: SnackBarAction(
            label: 'Anular',
            onPressed: () => viewModel.restoreAccount(account),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Contas'),
          actions: [
            AppButton.icon(
              icon: viewModel.includeInactive
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              tooltip: viewModel.includeInactive
                  ? 'Ocultar inativas'
                  : 'Mostrar inativas',
              onPressed: () =>
                  viewModel.setIncludeInactive(!viewModel.includeInactive),
            ),
            AppButton.icon(
              icon: Icons.add,
              tooltip: 'Nova conta',
              onPressed: () => _openForm(null),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: AsyncView(
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                isEmpty: viewModel.isEmpty,
                onRetry: viewModel.load,
                emptyMessage: 'Ainda não há contas.',
                emptyIcon: Icons.account_balance_outlined,
                child: _AccountsContent(
                  viewModel: viewModel,
                  onEdit: _openForm,
                  onDelete: _deleteWithUndo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountsContent extends StatelessWidget {
  const _AccountsContent({
    required this.viewModel,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountsViewModel viewModel;
  final ValueChanged<Account> onEdit;
  final ValueChanged<Account> onDelete;

  @override
  Widget build(BuildContext context) {
    final accounts = viewModel.accounts;
    final actionError = viewModel.actionError;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _countLabel(accounts.length),
            style: AppTextStyles.bodyMuted(context.colors),
          ),
          const SizedBox(height: AppSpacing.md),
          if (actionError != null) ...[
            AppErrorBanner(
              message: actionError,
              onDismiss: viewModel.clearActionError,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            padding: EdgeInsets.symmetric(
              horizontal: AppBreakpoints.cardPadding(context),
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                for (var index = 0; index < accounts.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _AccountRow(
                    account: accounts[index],
                    ownerName: viewModel.ownerName(accounts[index]),
                    onEdit: () => onEdit(accounts[index]),
                    onDelete: () => onDelete(accounts[index]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _countLabel(int count) =>
      count == 1 ? '1 conta' : '$count contas';
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.ownerName,
    required this.onEdit,
    required this.onDelete,
  });

  final Account account;
  final String? ownerName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = account.isJoint
        ? 'Conta conjunta'
        : 'Pessoal · ${ownerName ?? 'Pessoa desconhecida'}';
    return Dismissible(
      key: ValueKey(account.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: const DismissBackground(alignment: Alignment.centerLeft),
      secondaryBackground: const DismissBackground(
        alignment: Alignment.centerRight,
      ),
      child: Material(
        color: context.colors.surface,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                _AccountGlyph(isJoint: account.isJoint),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: account.active
                              ? context.colors.ink
                              : context.colors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMuted(context.colors),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!account.active) ...[
                  AppBadge(
                    label: 'INATIVA',
                    style: AppBadgeStyles.destructive(context.colors),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Icon(
                  Icons.chevron_right,
                  size: AppSizes.iconMedium,
                  color: context.colors.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The circular ownership glyph: a group for a joint account, a person for a
/// personal one.
class _AccountGlyph extends StatelessWidget {
  const _AccountGlyph({required this.isJoint});

  final bool isJoint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.categoryIcon,
      height: AppSizes.categoryIcon,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.mintSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isJoint ? Icons.groups_outlined : Icons.person_outline,
        size: AppSizes.iconLarge,
        color: context.colors.primaryDark,
      ),
    );
  }
}

/// The create / edit form, shown as a bottom sheet.
class _AccountFormSheet extends StatefulWidget {
  const _AccountFormSheet({
    required this.initialName,
    required this.initialOwnerId,
    required this.isEditing,
    required this.people,
    required this.onSave,
    this.onDelete,
  });

  final String initialName;
  final String? initialOwnerId;
  final bool isEditing;
  final List<Person> people;
  final Future<String?> Function(String name, String? ownerPersonId) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  /// The dropdown value that maps to a joint account (`ownerPersonId = null`).
  static const String _jointOwnerId = '';

  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late String _ownerId = widget.initialOwnerId ?? _jointOwnerId;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final failure = await widget.onSave(
      name,
      _ownerId == _jointOwnerId ? null : _ownerId,
    );
    if (!mounted) {
      return;
    }
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _error = failure;
      });
    }
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar conta?',
      message: 'A conta deixa de aparecer nas listas.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    Navigator.of(context).pop();
    await onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return BottomSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing ? 'Editar conta' : 'Nova conta',
            style: AppTextStyles.pageTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            autofocus: !widget.isEditing,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            maxLength: _nameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex.: Conta à ordem',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _ownerId,
            decoration: const InputDecoration(
              labelText: 'Proprietária',
              prefixIcon: Icon(Icons.person_outline, size: AppSizes.iconMedium),
            ),
            items: [
              const DropdownMenuItem(
                value: _jointOwnerId,
                child: Text('Conta conjunta'),
              ),
              for (final person in widget.people)
                DropdownMenuItem(value: person.id, child: Text(person.name)),
            ],
            onChanged: (value) =>
                setState(() => _ownerId = value ?? _jointOwnerId),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBanner(message: error),
          ],
          const SizedBox(height: AppSpacing.xl),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) {
              final enabled = _name.text.trim().isNotEmpty;
              return AppButton(
                label: widget.isEditing ? 'Guardar' : 'Criar conta',
                isFullWidth: true,
                isLoading: _isSaving,
                onPressed: enabled ? _save : null,
              );
            },
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Eliminar conta',
              icon: Icons.delete_outline,
              variant: AppButtonVariant.ghost,
              isFullWidth: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

const int _nameMaxLength = 100;
