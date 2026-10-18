/// A household savings goal.
class Goal {
  const Goal({required this.id, required this.name, required this.active});

  final String id;
  final String name;
  final bool active;

  Goal copyWith({String? name, bool? active}) =>
      Goal(id: id, name: name ?? this.name, active: active ?? this.active);
}
