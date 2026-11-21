import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/services/person_offline_store.dart';

void main() {
  final persons = <Map<String, dynamic>>[
    {
      'name': '张三',
      'id_card': '520100199001011234',
      'hu_hao': '001',
      'phone': '13800001111',
      'address': '某某村一组',
      'group_name': '一组',
    },
    {
      'name': '张小明',
      'id_card': '520100201001015678',
      'hu_hao': '001',
      'phone': '13800002222',
      'address': '某某村一组',
      'group_name': '一组',
    },
    {
      'name': '李四',
      'id_card': '520100198001019999',
      'hu_hao': '002',
      'phone': '13900003333',
      'address': '某某村二组',
      'group_name': '二组',
    },
  ];

  test('身份证精确命中排在最前', () {
    final hits = PersonOfflineStore.filterPersons(
      persons,
      '520100199001011234',
    );
    expect(hits.length, 1);
    expect(hits.first['name'], '张三');
  });

  test('身份证末位/片段可模糊命中', () {
    final hits = PersonOfflineStore.filterPersons(persons, '1234');
    expect(hits.any((p) => p['name'] == '张三'), isTrue);
  });

  test('姓名模糊命中，户号精确命中全户', () {
    final byName = PersonOfflineStore.filterPersons(persons, '张');
    expect(byName.map((e) => e['name']), containsAll(['张三', '张小明']));

    final byHuHao = PersonOfflineStore.filterPersons(persons, '001');
    expect(byHuHao.length, greaterThanOrEqualTo(2));
    expect(
      byHuHao.map((e) => e['name']),
      containsAll(['张三', '张小明']),
    );
  });

  test('电话精确命中', () {
    final hits = PersonOfflineStore.filterPersons(persons, '13900003333');
    expect(hits.first['name'], '李四');
  });

  test('空查询返回空列表', () {
    expect(PersonOfflineStore.filterPersons(persons, '  '), isEmpty);
  });

  test('结果数量受 limit 限制', () {
    final many = List.generate(
      400,
      (i) => {'name': '村民$i', 'id_card': 'X$i'},
    );
    final hits = PersonOfflineStore.filterPersons(many, '村民', limit: 50);
    expect(hits.length, 50);
  });
}
