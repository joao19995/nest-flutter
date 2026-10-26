import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/features/agenda/views/agenda_view.dart';
import 'package:nest/ui/features/calendar/views/calendar_view.dart';
import 'package:nest/ui/features/todos/views/todos_view.dart';

import '../../../support/test_helpers.dart';

List<Object> _lists() => <Object>[
  {
    'id': 'l1',
    'name': 'Casa',
    'position': 1000,
    'active': true,
    'items': <Object>[],
  },
];

/// Both sides keep a switcher in the tree, so tap the one on screen.
Future<void> _tapSegment(
  WidgetTester tester,
  String label, {
  required bool inCalendar,
}) async {
  await tester.tap(
    find.descendant(
      of: find.byType(inCalendar ? CalendarView : TodosView),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on Tarefas and defers the calendar', (tester) async {
    setPhoneSize(tester);
    final requested = <String>[];
    final client = MockClient((request) async {
      requested.add(request.url.path);
      if (request.url.path == '/api/todo-lists') {
        return jsonResponse(_lists());
      }
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const AgendaView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Tarefas'), findsOneWidget);
    expect(requested, contains('/api/todo-lists'));
    expect(requested, isNot(contains('/api/events')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches sections and keeps the tasks loaded once', (
    tester,
  ) async {
    setPhoneSize(tester);
    final requested = <String>[];
    final client = MockClient((request) async {
      requested.add(request.url.path);
      if (request.url.path == '/api/todo-lists') {
        return jsonResponse(_lists());
      }
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const AgendaView()),
    );
    await tester.pumpAndSettle();

    await _tapSegment(tester, 'Calendário', inCalendar: false);

    expect(requested, contains('/api/events'));
    expect(find.text('EVENTOS DO MÊS'), findsOneWidget);

    await _tapSegment(tester, 'Tarefas', inCalendar: true);

    expect(find.text('Casa'), findsOneWidget);
    expect(
      requested.where((path) => path == '/api/todo-lists').length,
      1,
      reason: 'the tasks list must not reload when returning to it',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('starts on the calendar when initialSection says so', (
    tester,
  ) async {
    setPhoneSize(tester);
    final requested = <String>[];
    final client = MockClient((request) async {
      requested.add(request.url.path);
      if (request.url.path == '/api/todo-lists') {
        return jsonResponse(_lists());
      }
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const AgendaView(initialSection: AgendaSection.calendar),
      ),
    );
    await tester.pumpAndSettle();

    expect(requested, contains('/api/events'));
    expect(find.text('EVENTOS DO MÊS'), findsOneWidget);
    expect(requested, isNot(contains('/api/todo-lists')));

    await _tapSegment(tester, 'Tarefas', inCalendar: true);

    expect(requested, contains('/api/todo-lists'));
    expect(find.text('Casa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('follows and updates an injected section signal', (tester) async {
    setPhoneSize(tester);
    final requested = <String>[];
    final client = MockClient((request) async {
      requested.add(request.url.path);
      if (request.url.path == '/api/todo-lists') {
        return jsonResponse(_lists());
      }
      return jsonResponse(const <Object>[]);
    });
    final signal = ValueNotifier<AgendaSection>(AgendaSection.tasks);
    addTearDown(signal.dispose);

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        AgendaView(sectionSignal: signal),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(requested, isNot(contains('/api/events')));

    signal.value = AgendaSection.calendar;
    await tester.pumpAndSettle();

    expect(requested, contains('/api/events'));
    expect(find.text('EVENTOS DO MÊS'), findsOneWidget);

    await _tapSegment(tester, 'Tarefas', inCalendar: true);

    expect(signal.value, AgendaSection.tasks);
    expect(find.text('Casa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches sections on a 320px surface at 1.5 text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists') {
        return jsonResponse(_lists());
      }
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const AgendaView()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await _tapSegment(tester, 'Calendário', inCalendar: false);

    expect(find.text('Hoje'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tapSegment(tester, 'Tarefas', inCalendar: true);

    expect(find.text('Casa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
