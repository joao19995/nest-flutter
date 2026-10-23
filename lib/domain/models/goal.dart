/// A household savings goal.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.active,
    this.iconKey,
  });

  final String id;
  final String name;
  final bool active;

  /// Semantic icon key chosen by the user (e.g. `plane`, `piggy-bank`).
  ///
  /// `null` means the goal uses the default icon.
  final String? iconKey;

  Goal copyWith({String? name, bool? active, String? iconKey}) => Goal(
    id: id,
    name: name ?? this.name,
    active: active ?? this.active,
    iconKey: iconKey ?? this.iconKey,
  );
}
