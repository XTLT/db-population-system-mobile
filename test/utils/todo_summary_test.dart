import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/notification.dart';
import 'package:population_mobile/utils/todo_summary.dart';

void main() {
  group('summarizeDataHealth', () {
    test('合计取服务端值，突出显示前两个必填项，跳过非必填项', () {
      final data = <String, dynamic>{
        'total_alive': 3282,
        'total_issue_persons': 361,
        'total_issue_count': 283,
        'checks': [
          {'key': 'phone_empty', 'label': '电话为空', 'required': true, 'count': 226},
          {
            'key': 'student_no_guardian_phone',
            'label': '学生缺监护人电话',
            'required': false,
            'count': 152,
          },
          {'key': 'no_household_head', 'label': '本户无户主', 'required': true, 'count': 57},
          {'key': 'bad_id_card', 'label': '身份证格式错', 'required': true, 'count': 1},
        ],
      };

      final summary = summarizeDataHealth(data);

      expect(summary.issueCount, 283);
      expect(summary.issuePersons, 361);
      expect(summary.topItems, '电话为空 226 · 本户无户主 57');
      expect(summary.isEmpty, isFalse);
    });

    test('没有问题时 isEmpty 为真', () {
      final summary = summarizeDataHealth(<String, dynamic>{
        'total_issue_count': 0,
        'total_issue_persons': 0,
        'checks': const [],
      });
      expect(summary.isEmpty, isTrue);
      expect(summary.topItems, isEmpty);
    });

    test('旧服务端没有合计字段时，用必填项之和兜底', () {
      final summary = summarizeDataHealth(<String, dynamic>{
        'checks': [
          {'label': '电话为空', 'required': true, 'count': 226},
          {'label': '学生缺监护人电话', 'required': false, 'count': 152},
          // 有些序列化会把 true 写成 1
          {'label': '本户无户主', 'required': 1, 'count': 57},
        ],
      });

      expect(summary.issueCount, 283);
      expect(summary.isEmpty, isFalse);
    });
  });

  group('summarizeAgeNotifications', () {
    AppNotification age(String id, String title, bool read) => AppNotification(
          id: id,
          title: title,
          content: '',
          notificationType: 'business',
          isRead: read,
          createdAt: '2026-11-20 10:00:00',
        );

    test('只统计到龄通知，人数从标题解析，未读按条计', () {
      final list = [
        age('notif_age60_202611', '11 月到龄提醒：满 60 周岁（12 人）', false),
        age('notif_age80_202611', '11 月到龄提醒：满 80 周岁（3 人）', true),
        age('notif_system_1', '系统通知', false),
      ];

      final summary = summarizeAgeNotifications(list);

      expect(summary.persons, 15);
      expect(summary.unread, 1);
      expect(summary.monthLabel, '11 月');
      expect(summary.isEmpty, isFalse);
    });

    test('没有到龄通知时返回空汇总', () {
      final summary = summarizeAgeNotifications([
        age('notif_system_1', '系统通知', false),
      ]);
      expect(summary.isEmpty, isTrue);
      expect(summary.persons, 0);
      expect(summary.monthLabel, isEmpty);
    });

    test('标题没有月份时月份留空，人数照常累计', () {
      final summary = summarizeAgeNotifications([
        age('notif_age60_202611', '到龄提醒：满 60 周岁（5 人）', true),
      ]);
      expect(summary.persons, 5);
      expect(summary.monthLabel, isEmpty);
    });
  });
}
