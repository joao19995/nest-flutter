/// A bank/cash account.
///
/// A `null` [ownerPersonId] means the joint household account; otherwise the
/// account belongs to an individual member.
class Account {
  const Account({
    required this.id,
    required this.name,
    this.ownerPersonId,
    required this.active,
  });

  final String id;
  final String name;
  final String? ownerPersonId;
  final bool active;

  /// True when this is the joint household account.
  bool get isJoint => ownerPersonId == null;
}
