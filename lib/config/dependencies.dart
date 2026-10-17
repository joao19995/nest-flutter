import 'package:nest/data/repositories/accounts_repository.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';

/// The application's composition root.
///
/// Constructs the API client and repositories once and exposes them to the
/// widget tree via `DependenciesScope`. No DI package is used — the graph is
/// small and explicit.
class AppDependencies {
  AppDependencies({NestApiClient? apiClient})
    : apiClient = apiClient ?? NestApiClient() {
    peopleRepository = PeopleRepository(client: this.apiClient);
    accountsRepository = AccountsRepository(client: this.apiClient);
    expensesRepository = ExpensesRepository(client: this.apiClient);
    goalsRepository = GoalsRepository(client: this.apiClient);
  }

  final NestApiClient apiClient;
  late final PeopleRepository peopleRepository;
  late final AccountsRepository accountsRepository;
  late final ExpensesRepository expensesRepository;
  late final GoalsRepository goalsRepository;

  /// Releases the underlying HTTP client.
  void dispose() => apiClient.dispose();
}
