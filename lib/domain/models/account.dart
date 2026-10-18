/// A household bank account.
///
/// A null [ownerPersonId] marks a joint account; otherwise the account belongs
/// to the person with that id.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.ownerPersonId,
    required this.active,
  });

  final String id;
  final String name;

  /// The owning person's id, or null for a joint account.
  final String? ownerPersonId;

  /// Whether the account is visible (soft-deleted accounts are inactive).
  final bool active;

  /// Whether this account is shared by the whole household.
  bool get isJoint => ownerPersonId == null;
}
