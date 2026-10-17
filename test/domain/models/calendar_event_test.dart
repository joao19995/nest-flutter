import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/calendar_event.dart';

void main() {
  group('CalendarEvent', () {
    final event = CalendarEvent(
      id: 'e1',
      title: 'Consulta',
      startsAt: DateTime(2026, 10, 20, 9, 30),
      active: true,
    );

    test('occursOn matches the same local calendar day only', () {
      expect(event.occursOn(DateTime(2026, 10, 20)), isTrue);
      expect(event.occursOn(DateTime(2026, 10, 20, 23, 59)), isTrue);
      expect(event.occursOn(DateTime(2026, 10, 21)), isFalse);
      expect(event.occursOn(DateTime(2025, 10, 20)), isFalse);
    });

    test('copyWith replaces only the given fields', () {
      final rescheduled = event.copyWith(startsAt: DateTime(2026, 11, 1, 14));

      expect(rescheduled.id, 'e1');
      expect(rescheduled.title, 'Consulta');
      expect(rescheduled.startsAt, DateTime(2026, 11, 1, 14));
      expect(rescheduled.active, isTrue);

      final cancelled = event.copyWith(active: false);
      expect(cancelled.active, isFalse);
      expect(cancelled.title, 'Consulta');
    });
  });
}
