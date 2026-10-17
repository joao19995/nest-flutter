import 'package:nest/data/models/account_model.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/account.dart';

/// Reads accounts (personal and joint).
class AccountsRepository {
  AccountsRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns accounts, ordered by name (as served by the API).
  ///
  /// By default only active accounts are returned; pass [includeInactive] to
  /// also include soft-deleted ones.
  Future<List<Account>> fetchAccounts({bool includeInactive = false}) async {
    final path = includeInactive
        ? '/api/accounts?includeInactive=true'
        : '/api/accounts';
    final data = await _client.get(path);
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => AccountModel.fromJson(json).toDomain())
        .toList(growable: false);
  }
}
