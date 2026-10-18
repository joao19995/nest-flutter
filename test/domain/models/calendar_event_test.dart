import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/calendar_event.dart';

void main() {
  group('CalendarEvent', () {
    final event = CalendarEvent(
      id: 'e1',
      title: 'Consulta',
      startsAt: DateTime(2026, 10, 20, 9, 30),
    );

    test('occursOn matches the same local calendar day only', () {
      expect(event.occursOn(DateTime(2026, 10, 20)), isTrue);
      expect(event.occursOn(DateTime(2026, 10, 20, 23, 59)), isTrue);
      expect(event.occursOn(DateTime(2026, 10, 21)), isFalse);
      expect(event.occursOn(DateTime(2025, 10, 20)), isFalse);
    });
  });
}
