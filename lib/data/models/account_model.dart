import 'package:nest/domain/models/account.dart';

/// API-facing representation of an [Account], with JSON mapping.
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    this.ownerPersonId,
    required this.active,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
    id: json['id'] as String,
    name: json['name'] as String,
    ownerPersonId: json['ownerPersonId'] as String?,
    active: json['active'] as bool,
  );

  final String id;
  final String name;
  final String? ownerPersonId;
  final bool active;

  Account toDomain() =>
      Account(id: id, name: name, ownerPersonId: ownerPersonId, active: active);
}
