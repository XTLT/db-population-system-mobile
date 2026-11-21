import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/age_notice.dart';

void main() {
  Map<String, dynamic> sample() => {
        'month_label': '12 月',
        'month_key': '2026-12',
        'total': 3,
        'groups': [
          {
            'age': 60,
            'total': 2,
            'persons': [
              {
                'person_id': 'p1',
                'name': '张三',
                'id_card': '520325196612011234',
                'birthday': '1966-12-01',
                'address': '安村',
                'group_name': '一组',
                'phone': '13800000001',
              },
              {
                'person_id': 'p2',
                'name': '李四',
                'id_card': '520325196612051237',
                'birthday': '1966-12-05',
                'address': '安村',
                'group_name': '',
                'phone': '',
              },
            ],
          },
          {
            'age': 80,
            'total': 1,
            'persons': [
              {
                'person_id': 'p3',
                'name': '王五',
                'id_card': '520325194612011238',
                'birthday': '1946-12-01',
                'address': '',
                'group_name': '三组',
                'phone': '',
              },
            ],
          },
        ],
      };

  test('解析到龄名单：两组、人数合计', () {
    final data = AgeNoticeData.fromJson(sample());

    expect(data.monthLabel, '12 月');
    expect(data.monthKey, '2026-12');
    expect(data.groups.length, 2);
    expect(data.groups.first.age, 60);
    expect(data.groups.first.persons.length, 2);
    expect(data.total, 3);
    expect(data.isEmpty, isFalse);
  });

  test('空名单算 isEmpty', () {
    final data = AgeNoticeData.fromJson({'groups': []});
    expect(data.total, 0);
    expect(data.isEmpty, isTrue);
  });

  test('办理一个人后本地移除，其他人还在', () {
    final data = AgeNoticeData.fromJson(sample());
    final after = data.without('p1', 60);

    expect(after.total, 2);
    expect(after.groups.first.persons.map((p) => p.personId), ['p2']);
    // 另一组不受影响
    expect(after.groups.last.persons.single.personId, 'p3');
  });

  test('同名不同组只移除指定档位', () {
    final data = AgeNoticeData.fromJson({
      'groups': [
        {
          'age': 60,
          'persons': [
            {'person_id': 'x', 'name': '甲'},
          ],
        },
        {
          'age': 80,
          'persons': [
            {'person_id': 'x', 'name': '甲'},
          ],
        },
      ],
    });

    final after = data.without('x', 60);
    expect(after.groups[0].persons, isEmpty);
    expect(after.groups[1].persons.length, 1);
  });

  test('detailLine 跳过空字段', () {
    final data = AgeNoticeData.fromJson(sample());
    final first = data.groups.first.persons.first;
    expect(first.detailLine, contains('一组 安村'));
    expect(first.detailLine, contains('生日 1966-12-01'));
    expect(first.detailLine, contains('13800000001'));

    final second = data.groups.first.persons[1];
    expect(second.detailLine, contains('生日 1966-12-05'));
    expect(second.detailLine, contains('安村'));
    expect(second.detailLine, isNot(contains('13800000001')));
  });
}
