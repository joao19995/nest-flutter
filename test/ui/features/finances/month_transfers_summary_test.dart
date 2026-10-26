import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/month_transfers.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/finances/views/month_transfers_summary.dart';

MonthTransfers _twoPersonMonth() => const MonthTransfers(
  month: '2026-01',
  closed: true,
  expenses: null,
  goals: [],
  goalsReserved: 0,
  goalsHasIncome: true,
  totals: MonthTransfersTotals(toJoint: 300, fromJoint: 320, toGoals: 350),
  people: [
    MonthTransfersPerson(
      personId: 'p1',
      personName: 'Ana',
      toJoint: 300,
      fromJoint: 0,
      toGoals: 250,
      goals: [
        MonthTransfersGoalPart(goalId: 'g1', name: 'Viagem', amount: 150),
        MonthTransfersGoalPart(goalId: 'g2', name: 'Carro', amount: 100),
      ],
    ),
    MonthTransfersPerson(
      personId: 'p2',
      personName: 'João',
      toJoint: 0,
      fromJoint: 320,
      toGoals: 100,
      goals: [],
    ),
  ],
);

MonthTransfers _emptyMonth() => const MonthTransfers(
  month: '2026-01',
  closed: true,
  expenses: null,
  goals: [],
  goalsReserved: 0,
  goalsHasIncome: false,
  totals: MonthTransfersTotals(toJoint: 0, fromJoint: 0, toGoals: 0),
  people: [
    MonthTransfersPerson(
      personId: 'p1',
      personName: 'Ana',
      toJoint: 0,
      fromJoint: 0,
      toGoals: 0,
      goals: [],
    ),
  ],
);

Future<void> _pumpSummary(WidgetTester tester, MonthTransfers transfers) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MonthTransfersSummary(
            transfers: transfers,
            iconKeyByGoal: const {},
          ),
        ),
      ),
    ),
  );
}

String? _copiedText() {
  // The clipboard mock records the payload; read it through the last call.
  final setCalls = _platformCalls
      .where((call) => call.method == 'Clipboard.setData')
      .toList();
  if (setCalls.isEmpty) {
    return null;
  }
  final arguments = setCalls.last.arguments as Map<Object?, Object?>;
  return arguments['text'] as String?;
}

final List<MethodCall> _platformCalls = [];

void main() {
  setUp(() {
    _platformCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          _platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('copies the formatted two-person summary', (tester) async {
    await _pumpSummary(tester, _twoPersonMonth());

    await tester.ensureVisible(find.text('Copiar resumo'));
    await tester.tap(find.text('Copiar resumo'));
    await tester.pumpAndSettle();

    final expected = [
      'Transferências de Janeiro',
      'Ana → Conjunta: ${AppFormatters.currency(300)}',
      'Ana → Viagem: ${AppFormatters.currency(150)}',
      'Ana → Carro: ${AppFormatters.currency(100)}',
      'Conjunta → João: ${AppFormatters.currency(320)}',
      'João → Objetivos: ${AppFormatters.currency(100)}',
    ].join('\n');

    expect(_copiedText(), expected);
    expect(find.text('Resumo copiado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to the empty message when nothing transfers', (
    tester,
  ) async {
    await _pumpSummary(tester, _emptyMonth());

    await tester.ensureVisible(find.text('Copiar resumo'));
    await tester.tap(find.text('Copiar resumo'));
    await tester.pumpAndSettle();

    expect(
      _copiedText(),
      'Transferências de Janeiro\nSem transferências neste mês.',
    );
    expect(tester.takeException(), isNull);
  });
}
