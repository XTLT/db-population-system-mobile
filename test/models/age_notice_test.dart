import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/age_notice.dart';

void main() {
  Map<String, dynamic> sample() => {
        'month_label': '12 月',
        'month_key': '2026-12',
        'current_month': '2026-11',
        'total': 3,
        'groups': [
          {
            'age': 60,
            'total': 2,
            'handled_total': 0,
            'persons': [
              {
                'person_id': 'p1',
                'name': '张三',
                'id_card': '520325196611011234',
                'birthday': '1966-11-01',
                'address': '安村',
                'group_name': '一组',
                'phone': '13800000001',
                'target_month': '2026-11',
                'target_label': '11 月',
                'handled': false,
              },
              {
                'person_id': 'p2',
                'name': '李四',
                'id_card': '520325196612051237',
                'birthday': '1966-12-05',
                'address': '安村',
                'group_name': '',
                'phone': '',
                'target_month': '2026-12',
                'target_label': '12 月',
                'handled': false,
              },
            ],
          },
          {
            'age': 80,
            'total': 1,
            'handled_total': 0,
            'persons': [
              {
                'person_id': 'p3',
                'name': '王五',
                'id_card': '520325194612011238',
                'birthday': '1946-12-01',
                'address': '',
                'group_name': '三组',
                'phone': '',
                'target_month': '2026-12',
                'target_label': '12 月',
                'handled': false,
              },
            ],
          },
        ],
      };

  test('解析累积名单：跨月人员、两档分组', () {
    final data = AgeNoticeData.fromJson(sample());

    expect(data.monthLabel, '12 月');
    expect(data.monthKey, '2026-12');
    expect(data.currentMonth, '2026-11');
    expect(data.groups.length, 2);
    expect(data.total, 3);
    expect(data.pendingCount, 3);
    expect(data.handledCount, 0);
    expect(data.isEmpty, isFalse);
    // 同档里 11 月的人排在 12 月的人前面
    expect(data.groups.first.persons.first.targetMonth, '2026-11');
  });

  test('空名单算 isEmpty', () {
    final data = AgeNoticeData.fromJson({'groups': []});
    expect(data.total, 0);
    expect(data.pendingCount, 0);
    expect(data.isEmpty, isTrue);
  });

  test('点了已办理后当月仍留在名单里，只标记状态', () {
    final data = AgeNoticeData.fromJson(sample());
    final after = data.markHandled('p1', 60);

    expect(after.total, 3, reason: '当月不能从名单里消失');
    expect(after.pendingCount, 2);
    expect(after.handledCount, 1);

    final first = after.groups.first.persons.first;
    expect(first.personId, 'p1');
    expect(first.handled, isTrue);
    // 其他人的状态不受影响
    expect(after.groups.first.persons[1].handled, isFalse);
    expect(after.groups.last.persons.single.handled, isFalse);
  });

  test('60 岁办过不影响 80 岁那一档', () {
    final data = AgeNoticeData.fromJson({
      'groups': [
        {
          'age': 60,
          'persons': [
            {'person_id': 'x', 'name': '甲', 'handled': true},
          ],
        },
        {
          'age': 80,
          'persons': [
            {'person_id': 'x', 'name': '甲', 'handled': false},
          ],
        },
      ],
    });

    final after = data.markHandled('x', 80);
    expect(after.groups[0].persons.single.handled, isTrue);
    expect(after.groups[1].persons.single.handled, isTrue);
  });

  test('detailLine 带月份前缀并跳过空字段', () {
    final data = AgeNoticeData.fromJson(sample());
    final first = data.groups.first.persons.first;
    expect(first.detailLine, startsWith('11 月到龄'));
    expect(first.detailLine, contains('一组 安村'));
    expect(first.detailLine, contains('生日 1966-11-01'));
    expect(first.detailLine, contains('13800000001'));

    final second = data.groups.first.persons[1];
    expect(second.detailLine, startsWith('12 月到龄'));
    expect(second.detailLine, contains('生日 1966-12-05'));
    expect(second.detailLine, isNot(contains('13800000001')));
  });
}
