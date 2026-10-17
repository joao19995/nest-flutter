import 'package:flutter/material.dart';
import 'package:nest/domain/models/person.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/people/view_models/people_view_model.dart';
import 'package:nest/ui/features/people/views/person_form_sheet.dart';

/// Lists household members and opens the create form.
class PeopleView extends StatefulWidget {
  const PeopleView({super.key});

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView> {
  PeopleViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _viewModel = PeopleViewModel(
      peopleRepository: dependencies.peopleRepository,
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
      appBar: AppBar(title: const Text('Pessoas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateForm(viewModel),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: viewModel.isEmpty,
            onRetry: viewModel.load,
            emptyMessage: 'Ainda não há pessoas.',
            child: _PeopleList(people: viewModel.people),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateForm(PeopleViewModel viewModel) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) =>
          PersonFormSheet(onSubmit: viewModel.createPerson),
    );
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList({required this.people});

  final List<Person> people;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: people.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _PersonCard(person: people[index]),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, style: AppTextStyles.sectionHeading),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gasto diário: ${person.dailySpendingPercentage}% · '
                  'Emergência: ${person.emergencyFundMonths} meses',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const AppBadge(
            label: 'ATIVO',
            style: AppBadgeStyles.open,
            showDot: true,
          ),
        ],
      ),
    );
  }
}
