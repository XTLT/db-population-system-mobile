import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/api/api_client.dart';
import 'package:population_mobile/api/person_api.dart';
import 'package:population_mobile/models/person.dart';

import '../test_helpers.dart';

Map<String, dynamic> bodyOf(RequestOptions options) {
  final data = options.data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String && data.isNotEmpty) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  return {};
}

Map<String, dynamic> personJson({
  String idCard = '110101199001011234',
  String name = '张三',
}) {
  return {
    'id_card': idCard,
    'name': name,
    'hu_hao': 'H001',
    'address': '某县某村',
    'age': '35',
    'phone': '13800000000',
  };
}

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  group('PersonApi.searchByName', () {
    test('GET /api/search?name=，解析 data.results 为 Person 列表', () async {
      final rec = installMockAdapter((options) => jsonResponse({
            'results': [personJson(), personJson(name: '李四')],
          }));
      final list = await PersonApi.searchByName('张');
      final req = rec.last()!;
      expect(req.path, '/api/search');
      expect(req.method, 'GET');
      expect(req.queryParameters['name'], '张');
      expect(list.length, 2);
      expect(list[0], isA<Person>());
      expect(list[0].name, '张三');
      expect(list[0].idCard, '110101199001011234');
      expect(list[1].name, '李四');
    });

    test('results 缺省时返回空列表', () async {
      installMockAdapter((options) => jsonResponse({}));
      expect(await PersonApi.searchByName('空'), isEmpty);
    });

    test('HTTP 500 带 error：抛出带服务端 error 文案的 Exception', () async {
      installMockAdapter((options) => jsonResponse({'error': '查询超时'}, statusCode: 500));
      expect(
        () => PersonApi.searchByName('x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('查询超时'))),
      );
    });
  });

  group('PersonApi.searchAdvanced', () {
    test('仅非空参数进入 query，固定 limit=100，data 顶层数组解析', () async {
      final rec = installMockAdapter((options) => jsonResponse([
            personJson(name: '王五'),
          ]));
      final list = await PersonApi.searchAdvanced(
        name: '王',
        idCard: '110101',
        ageMin: 18,
        // idCard/ageMax/disability 等留空
      );
      final q = rec.last()!.queryParameters;
      expect(rec.last()!.path, '/api/search/advanced');
      expect(q['name'], '王');
      expect(q['id_card'], '110101');
      expect(q['age_min'], 18);
      // 空值字段不应出现
      expect(q.containsKey('age_max'), false);
      expect(q.containsKey('disability'), false);
      expect(q.containsKey('address'), false);
      expect(q['limit'], 100);
      expect(list.length, 1);
      expect(list[0].name, '王五');
    });

    test('自定义 limit 与全部筛选字段拼装', () async {
      final rec = installMockAdapter((options) => jsonResponse([]));
      await PersonApi.searchAdvanced(
        huHao: 'H001',
        address: '某村',
        ageMax: 60,
        disability: '是',
        disLevel: '二级',
        dibao: '是',
        tekun: '否',
        tekunType: 'A',
        poorType: '低保',
        relation: '户主',
        isDead: '否',
        limit: 50,
      );
      final q = rec.last()!.queryParameters;
      expect(q['hu_hao'], 'H001');
      expect(q['address'], '某村');
      expect(q['age_max'], 60);
      expect(q['disability'], '是');
      expect(q['dis_level'], '二级');
      expect(q['dibao'], '是');
      expect(q['tekun'], '否');
      expect(q['tekun_type'], 'A');
      expect(q['poor_type'], '低保');
      expect(q['relation'], '户主');
      expect(q['is_dead'], '否');
      expect(q['limit'], 50);
    });

    test('空字符串参数被忽略（name="" 不进 query）', () async {
      final rec = installMockAdapter((options) => jsonResponse([]));
      await PersonApi.searchAdvanced(name: '', limit: 10);
      final q = rec.last()!.queryParameters;
      expect(q.containsKey('name'), false);
      expect(q['limit'], 10);
    });

    test('HTTP 500：抛出 Exception', () async {
      installMockAdapter((options) => jsonResponse({}, statusCode: 500));
      expect(() => PersonApi.searchAdvanced(), throwsA(isA<Exception>()));
    });
  });

  group('PersonApi.getPersonDetail / getPerson', () {
    test('getPersonDetail: GET /api/person/<id>，从 data.person 解析为 Person', () async {
      final rec = installMockAdapter((options) => jsonResponse({
            'person': personJson(name: '赵六'),
          }));
      final p = await PersonApi.getPersonDetail('110101199001011234');
      expect(rec.last()!.path, '/api/person/110101199001011234');
      expect(p.name, '赵六');
      expect(p.idCard, '110101199001011234');
    });

    test('getPerson: GET /api/person/<id>，原样透传 data.person（不构 model）', () async {
      final rec = installMockAdapter((options) => jsonResponse({
            'person': {'id_card': 'X', 'name': '原始'},
          }));
      final m = await PersonApi.getPerson('X');
      expect(rec.last()!.path, '/api/person/X');
      expect(m, isA<Map>());
      expect(m['name'], '原始');
    });

    test('非 200：抛出 Exception', () async {
      installMockAdapter((options) => jsonResponse({}, statusCode: 404));
      expect(() => PersonApi.getPersonDetail('nope'), throwsA(isA<Exception>()));
      expect(() => PersonApi.getPerson('nope'), throwsA(isA<Exception>()));
    });
  });

  group('PersonApi.add / update / delete', () {
    test('addPerson: POST /api/person，body 透传入参，success=true 返回 true', () async {
      final rec = installMockAdapter((options) => jsonResponse({'success': true}));
      final data = {'id_card': '110101199001011234', 'name': '新', 'hu_hao': 'H9'};
      final ok = await PersonApi.addPerson(data);
      final req = rec.last()!;
      expect(req.path, '/api/person');
      expect(req.method, 'POST');
      expect(bodyOf(req)['id_card'], '110101199001011234');
      expect(bodyOf(req)['name'], '新');
      expect(ok, true);
    });

    test('addPerson: success=false 返回 false', () async {
      installMockAdapter((options) => jsonResponse({'success': false}));
      expect(await PersonApi.addPerson({'name': 'x'}), false);
    });

    test('updatePerson: PUT /api/person/<id>，body 透传，成功返回 true', () async {
      final rec = installMockAdapter((options) => jsonResponse({'success': true}));
      final ok = await PersonApi.updatePerson(
        '110101199001011234',
        {'name': '改名', 'hu_hao': 'H1'},
      );
      final req = rec.last()!;
      expect(req.path, '/api/person/110101199001011234');
      expect(req.method, 'PUT');
      expect(bodyOf(req)['name'], '改名');
      expect(ok, true);
    });

    test('deletePerson: DELETE /api/person/<id>，成功返回 true', () async {
      final rec = installMockAdapter((options) => jsonResponse({'success': true}));
      expect(await PersonApi.deletePerson('110101199001011234'), true);
      final req = rec.last()!;
      expect(req.path, '/api/person/110101199001011234');
      expect(req.method, 'DELETE');
    });

    test('add/update/delete 网络错误：抛出 Exception', () async {
      installMockAdapter((options) => jsonResponse({}, statusCode: 500));
      expect(() => PersonApi.addPerson({'name': 'x'}), throwsA(isA<Exception>()));
      expect(() => PersonApi.updatePerson('id', {'a': 1}), throwsA(isA<Exception>()));
      expect(() => PersonApi.deletePerson('id'), throwsA(isA<Exception>()));
    });
  });

  group('PersonApi.getFamilyMembers', () {
    test('GET /api/family/<hu>，从 data.members 解析 Person 列表', () async {
      final rec = installMockAdapter((options) => jsonResponse({
            'members': [personJson(name: '户主'), personJson(name: '配偶')],
          }));
      final list = await PersonApi.getFamilyMembers('H001');
      expect(rec.last()!.path, '/api/family/H001');
      expect(list.length, 2);
      expect(list[0].name, '户主');
    });

    test('members 缺省返回空列表', () async {
      installMockAdapter((options) => jsonResponse({}));
      expect(await PersonApi.getFamilyMembers('H-X'), isEmpty);
    });

    test('非 200 抛 Exception', () async {
      installMockAdapter((options) => jsonResponse({}, statusCode: 500));
      expect(() => PersonApi.getFamilyMembers('H-X'), throwsA(isA<Exception>()));
    });
  });

  group('PersonApi.getStatistics / updateEducation', () {
    test('getStatistics: GET /api/statistics，透传 data', () async {
      final rec = installMockAdapter((options) => jsonResponse({'total': 100, 'male': 50}));
      final m = await PersonApi.getStatistics();
      expect(rec.last()!.path, '/api/statistics');
      expect(m['total'], 100);
    });

    test('getStatistics 非 200 抛 Exception', () async {
      installMockAdapter((options) => jsonResponse({}, statusCode: 500));
      expect(() => PersonApi.getStatistics(), throwsA(isA<Exception>()));
    });

    test('updateEducation: PUT /api/person/<id>/education，body 透传，成功 true', () async {
      final rec = installMockAdapter((options) => jsonResponse({'success': true}));
      final ok = await PersonApi.updateEducation('pid1', {'school_name': '一小'});
      final req = rec.last()!;
      expect(req.path, '/api/person/pid1/education');
      expect(req.method, 'PUT');
      expect(bodyOf(req)['school_name'], '一小');
      expect(ok, true);
    });

    test('updateEducation success=false 返回 false', () async {
      installMockAdapter((options) => jsonResponse({'success': false}));
      expect(await PersonApi.updateEducation('pid1', {}), false);
    });
  });
}
