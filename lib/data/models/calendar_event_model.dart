import 'package:nest/domain/models/calendar_event.dart';

/// API-facing representation of a [CalendarEvent], with JSON mapping.
///
/// The API stores `startsAt` as a UTC instant; it is converted to the local
/// zone here so the rest of the app works in local time.
class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.active,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) =>
      CalendarEventModel(
        id: json['id'] as String,
        title: json['title'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
        active: json['active'] as bool? ?? true,
      );

  final String id;
  final String title;
  final DateTime startsAt;
  final bool active;

  CalendarEvent toDomain() =>
      CalendarEvent(id: id, title: title, startsAt: startsAt, active: active);
}
