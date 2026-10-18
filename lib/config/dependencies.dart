import 'package:nest/data/repositories/events_repository.dart';
import 'package:nest/data/repositories/expenses_repository.dart';
import 'package:nest/data/repositories/goals_repository.dart';
import 'package:nest/data/repositories/people_repository.dart';
import 'package:nest/data/repositories/todo_lists_repository.dart';
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
    eventsRepository = EventsRepository(client: this.apiClient);
    expensesRepository = ExpensesRepository(client: this.apiClient);
    goalsRepository = GoalsRepository(client: this.apiClient);
    todoListsRepository = TodoListsRepository(client: this.apiClient);
  }

  final NestApiClient apiClient;
  late final PeopleRepository peopleRepository;
  late final EventsRepository eventsRepository;
  late final ExpensesRepository expensesRepository;
  late final GoalsRepository goalsRepository;
  late final TodoListsRepository todoListsRepository;

  /// Releases the underlying HTTP client.
  void dispose() => apiClient.dispose();
}
