import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/calendar_event_model.dart';
import 'package:nest/domain/models/calendar_event.dart';

void main() {
  group('CalendarEventModel', () {
    test('converts the UTC instant to a local time', () {
      final model = CalendarEventModel.fromJson(const {
        'id': 'e1',
        'title': 'Consulta',
        'startsAt': '2026-10-20T09:30:00.000Z',
        'active': true,
      });

      final CalendarEvent event = model.toDomain();

      expect(event.id, 'e1');
      expect(event.title, 'Consulta');
      expect(event.active, isTrue);
      expect(event.startsAt.isUtc, isFalse);
      expect(event.startsAt.toUtc(), DateTime.utc(2026, 10, 20, 9, 30));
    });

    test('defaults a missing active flag to true', () {
      final model = CalendarEventModel.fromJson(const {
        'id': 'e1',
        'title': 'Aniversário',
        'startsAt': '2026-10-20T00:00:00.000Z',
      });

      expect(model.toDomain().active, isTrue);
    });
  });
}
