import 'package:nest/data/models/calendar_event_model.dart';
import 'package:nest/data/models/json_mapper.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/calendar_event.dart';

/// Reads and writes the household calendar events.
class EventsRepository {
  EventsRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns the events between [from] and [to] (both inclusive, by date),
  /// in chronological order. Inactive events are excluded unless
  /// [includeInactive].
  Future<List<CalendarEvent>> fetchEvents({
    required DateTime from,
    required DateTime to,
    bool includeInactive = false,
  }) async {
    final buffer = StringBuffer(
      '/api/events?from=${_date(from)}&to=${_date(to)}',
    );
    if (includeInactive) {
      buffer.write('&includeInactive=true');
    }
    final data = await _client.get(buffer.toString());
    return mapJsonList(
      data,
      (json) => CalendarEventModel.fromJson(json).toDomain(),
    );
  }

  /// Creates an event with [title] starting at the local [startsAt].
  Future<CalendarEvent> createEvent({
    required String title,
    required DateTime startsAt,
  }) async {
    final data = await _client.post('/api/events', {
      'title': title,
      'startsAt': _instant(startsAt),
    });
    return mapJson(
      data,
      (json) => CalendarEventModel.fromJson(json).toDomain(),
    );
  }

  /// Updates the event [id] with a new [title] and [startsAt].
  Future<CalendarEvent> updateEvent(
    String id, {
    required String title,
    required DateTime startsAt,
  }) async {
    final data = await _client.put('/api/events/$id', {
      'title': title,
      'startsAt': _instant(startsAt),
      'active': true,
    });
    return mapJson(
      data,
      (json) => CalendarEventModel.fromJson(json).toDomain(),
    );
  }

  /// Soft-deletes the event [id] (sets `active = false`).
  Future<void> deleteEvent(String id) => _client.delete('/api/events/$id');

  /// Restores a soft-deleted event [id].
  Future<void> restoreEvent(String id) =>
      _client.post('/api/events/$id/restore', const {});

  /// Formats a local date as `YYYY-MM-DD` for the `from`/`to` query.
  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Formats a local instant as a UTC ISO-8601 string for the request body.
  static String _instant(DateTime instant) => instant.toUtc().toIso8601String();
}
