import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/monthly_plan_model.dart';
import 'package:nest/domain/models/category.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/monthly_plan.dart';

void main() {
  group('MonthlyPlanModel', () {
    test('maps a closed month with entries and settlement', () {
      final json = <String, dynamic>{
        'id': 'm1',
        'month': '2026-01',
        'templateId': 't1',
        'closed': true,
        'entries': [
          {
            'id': 'e1',
            'categoryName': 'Casa',
            'categoryType': 'FIXED',
            'accountName': 'JoA�o',
            'planned': 450,
            'actual': 471.94,
          },
          {
            'id': 'e2',
            'categoryName': 'Internet',
            'categoryType': 'VARIABLE',
            'accountName': 'Conjunta',
            'planned': 20,
            'actual': 20,
          },
        ],
        'settlement': {
          'status': 'ok',
          'contributionRequired': 470,
          'jointSurplus': 12.5,
          'people': [
            {
              'personName': 'João',
              'income': 2500,
              'quota': 235,
              'personalActual': 200,
              'transferToJoint': 35,
              'transferToPerson': 0,
            },
          ],
        },
        'summary': {
          'month': '2026-01',
          'status': 'closed',
          'planned': 470,
          'actual': 491.94,
          'progressPct': 104.7,
          'over': true,
        },
      };

      final MonthlyPlan plan = MonthlyPlanModel.fromJson(json).toDomain();

      expect(plan.month, '2026-01');
      expect(plan.closed, isTrue);
      expect(plan.entries, hasLength(2));
      expect(plan.planned, 470);
      expect(plan.actual, 491.94);
      expect(plan.isOver, isTrue);

      final casa = plan.entries.first;
      expect(casa.categoryName, 'Casa');
      expect(casa.type, CategoryType.fixed);
      expect(casa.accountName, 'JoA�o');
      expect(casa.planned, 450);
      expect(casa.actual, 471.94);
      expect(casa.actualSet, isTrue);
      expect(plan.entries.last.type, CategoryType.variable);

      final settlement = plan.settlement;
      expect(settlement, isNotNull);
      expect(settlement?.status, SettlementStatus.ok);
      expect(settlement?.jointSurplus, 12.5);
      expect(settlement?.people, hasLength(1));
      expect(settlement?.people.first.transfersToJoint, isTrue);
    });

    test('maps an open month with no settlement', () {
      final plan = MonthlyPlanModel.fromJson(<String, dynamic>{
        'id': 'm2',
        'month': '2026-02',
        'templateId': 't1',
        'closed': false,
        'entries': <Object>[],
        'settlement': null,
      }).toDomain();

      expect(plan.closed, isFalse);
      expect(plan.entries, isEmpty);
      expect(plan.isEmpty, isTrue);
      expect(plan.settlement, isNull);
    });

    test('maps actualSet and falls back to the stored amount', () {
      final plan = MonthlyPlanModel.fromJson(<String, dynamic>{
        'id': 'm4',
        'month': '2026-04',
        'templateId': 't1',
        'closed': false,
        'entries': [
          {
            'id': 'e1',
            'categoryName': 'Renda',
            'categoryType': 'FIXED',
            'accountName': 'Conjunta',
            'planned': 800,
            'actual': 0,
            'actualSet': true,
          },
          {
            'id': 'e2',
            'categoryName': 'Luz',
            'categoryType': 'VARIABLE',
            'accountName': 'Conjunta',
            'planned': 60,
            'actual': 0,
            'actualSet': false,
          },
          {
            'id': 'e3',
            'categoryName': 'Água',
            'categoryType': 'VARIABLE',
            'accountName': 'Conjunta',
            'planned': 30,
            'actual': 30,
          },
        ],
        'settlement': null,
      }).toDomain();

      expect(plan.entries[0].actualSet, isTrue);
      expect(plan.entries[1].actualSet, isFalse);
      expect(plan.entries[2].actualSet, isTrue);
    });

    test('maps a no-income settlement', () {
      final plan = MonthlyPlanModel.fromJson(<String, dynamic>{
        'id': 'm3',
        'month': '2026-03',
        'templateId': 't1',
        'closed': true,
        'entries': <Object>[],
        'settlement': {
          'status': 'no-income',
          'message': 'Sem rendimento registado.',
        },
      }).toDomain();

      expect(plan.settlement?.status, SettlementStatus.noIncome);
      expect(plan.settlement?.message, 'Sem rendimento registado.');
      expect(plan.settlement?.people, isEmpty);
    });
  });
}
