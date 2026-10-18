import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/category_templates_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/category_template.dart';

CategoryTemplatesRepository _repository(MockClient mock) =>
    CategoryTemplatesRepository(
      client: NestApiClient(
        httpClient: mock,
        baseUrl: 'http://test.local',
        apiKey: '',
      ),
    );

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _entry() => {
  'categoryId': 'c1',
  'accountId': 'a1',
  'expectedAmount': 800,
  'active': true,
  'categoryName': 'Renda',
  'categoryType': 'FIXED',
  'categoryActive': true,
  'accountName': 'Conjunta',
  'accountActive': true,
};

void main() {
  test(
    'fetchCategoryTemplates maps the list and tolerates a non-list',
    () async {
      final templates = await _repository(
        MockClient(
          (request) async => _json([
            {
              'id': 't1',
              'validFrom': '2026-01',
              'entries': [_entry()],
            },
          ]),
        ),
      ).fetchCategoryTemplates();

      expect(templates.single.validFrom, '2026-01');
      expect(templates.single.entries.single.expectedAmount, 800);

      final empty = await _repository(
        MockClient((request) async => _json(const {'not': 'a list'})),
      ).fetchCategoryTemplates();
      expect(empty, isEmpty);
    },
  );

  test(
    'fetchApplicableCategoryTemplate reads the month and maps the pair',
    () async {
      String? month;
      final repository = _repository(
        MockClient((request) async {
          month = request.url.queryParameters['month'];
          return _json({
            'template': {
              'id': 't1',
              'validFrom': '2026-01',
              'entries': [_entry()],
            },
            'defaultAccountId': 'a1',
          });
        }),
      );

      final applicable = await repository.fetchApplicableCategoryTemplate(
        '2026-04',
      );

      expect(month, '2026-04');
      expect(applicable.template?.validFrom, '2026-01');
      expect(applicable.defaultAccountId, 'a1');
    },
  );

  test('createCategoryTemplate posts validFrom and entries', () async {
    String? path;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({
          'id': 't1',
          'validFrom': '2026-11',
          'entries': [_entry()],
        }, status: 201);
      }),
    );

    final created = await repository.createCategoryTemplate(
      validFrom: '2026-11',
      entries: const [
        CategoryTemplateEntryDraft(
          categoryId: 'c1',
          accountId: 'a1',
          expectedAmount: 800,
        ),
      ],
    );

    expect(path, '/api/category-templates');
    expect(body?['validFrom'], '2026-11');
    final entries = (body?['entries'] as List).cast<Map<String, dynamic>>();
    expect(entries.single['categoryId'], 'c1');
    expect(entries.single['accountId'], 'a1');
    expect(entries.single['expectedAmount'], 800);
    expect(entries.single['active'], isTrue);
    expect(created.validFrom, '2026-11');
  });

  test('updateCategoryTemplate puts only the entries', () async {
    String? path;
    String? method;
    Map<String, dynamic>? body;
    final repository = _repository(
      MockClient((request) async {
        path = request.url.path;
        method = request.method;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({
          'id': 't1',
          'validFrom': '2026-01',
          'entries': [_entry()],
        });
      }),
    );

    await repository.updateCategoryTemplate('t1', const [
      CategoryTemplateEntryDraft(
        categoryId: 'c1',
        accountId: 'a1',
        expectedAmount: 900,
      ),
    ]);

    expect(method, 'PUT');
    expect(path, '/api/category-templates/t1');
    expect(body?.containsKey('validFrom'), isFalse);
    final entries = (body?['entries'] as List).cast<Map<String, dynamic>>();
    expect(entries.single['expectedAmount'], 900);
  });
}
