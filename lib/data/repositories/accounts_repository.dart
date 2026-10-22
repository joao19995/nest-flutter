import 'package:nest/data/models/account_model.dart';
import 'package:nest/data/models/json_mapper.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/account.dart';

/// Reads and writes the household bank accounts.
class AccountsRepository {
  AccountsRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns the accounts ordered by name. Soft-deleted accounts are excluded
  /// unless [includeInactive].
  Future<List<Account>> fetchAccounts({bool includeInactive = false}) async {
    final path = includeInactive
        ? '/api/accounts?includeInactive=true'
        : '/api/accounts';
    final data = await _client.get(path);
    return mapJsonList(data, (json) => AccountModel.fromJson(json).toDomain());
  }

  /// Creates an account. [ownerPersonId] must be present in the body, so it is
  /// always sent — null marks a joint account.
  Future<Account> createAccount({
    required String name,
    String? ownerPersonId,
  }) async {
    final data = await _client.post('/api/accounts', {
      'name': name,
      'ownerPersonId': ownerPersonId,
    });
    return mapJson(data, (json) => AccountModel.fromJson(json).toDomain());
  }

  /// Updates the account [id]. Unlike categories, the account input has no
  /// `active` field: reactivating is done through [restoreAccount].
  Future<Account> updateAccount(
    String id, {
    required String name,
    String? ownerPersonId,
  }) async {
    final data = await _client.put('/api/accounts/$id', {
      'name': name,
      'ownerPersonId': ownerPersonId,
    });
    return mapJson(data, (json) => AccountModel.fromJson(json).toDomain());
  }

  /// Soft-deletes the account [id] (sets `active = false`).
  Future<void> deleteAccount(String id) => _client.delete('/api/accounts/$id');

  /// Restores a soft-deleted account [id].
  Future<Account> restoreAccount(String id) async {
    final data = await _client.post('/api/accounts/$id/restore', const {});
    return mapJson(data, (json) => AccountModel.fromJson(json).toDomain());
  }
}
