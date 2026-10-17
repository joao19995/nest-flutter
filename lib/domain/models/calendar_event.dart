/// A dated household event shown in the calendar.
///
/// [startsAt] is always a local time: the data layer converts from the API's
/// UTC instant on the way in, and back to UTC on the way out.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.active,
  });

  /// The event's unique identifier.
  final String id;

  /// The event's display title.
  final String title;

  /// The local instant the event starts at.
  final DateTime startsAt;

  /// Whether the event is active. Deletion is a soft delete (`active = false`)
  /// and can be reverted through the restore endpoint.
  final bool active;

  /// True when the event falls on the same local calendar day as [day].
  bool occursOn(DateTime day) =>
      startsAt.year == day.year &&
      startsAt.month == day.month &&
      startsAt.day == day.day;

  /// Returns a copy of this event with the given fields replaced.
  CalendarEvent copyWith({String? title, DateTime? startsAt, bool? active}) =>
      CalendarEvent(
        id: id,
        title: title ?? this.title,
        startsAt: startsAt ?? this.startsAt,
        active: active ?? this.active,
      );
}
