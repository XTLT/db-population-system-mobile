import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/notification.dart';

void main() {
  group('AppNotification Model Tests', () {
    test('fromJson 应字段级解析，is_read == "是" 时 isRead=true', () {
      final json = {
        'id': 'n-1',
        'title': '系统升级',
        'content': '今晚22点升级',
        'notification_type': 'system',
        'target_user': 'all',
        'sender_name': 'admin',
        'is_read': '是',
        'created_at': '2026-09-30T10:00:00',
        'read_at': '2026-09-30T10:05:00',
      };

      final n = AppNotification.fromJson(json);

      expect(n.id, 'n-1');
      expect(n.title, '系统升级');
      expect(n.content, '今晚22点升级');
      expect(n.notificationType, 'system');
      expect(n.targetUser, 'all');
      expect(n.senderName, 'admin');
      expect(n.isRead, true);
      expect(n.createdAt, '2026-09-30T10:00:00');
      expect(n.readAt, '2026-09-30T10:05:00');
    });

    test('fromJson is_read 非"是"时 isRead=false（含缺省）', () {
      final unread = AppNotification.fromJson({
        'id': 'n-2',
        'title': 't',
        'content': 'c',
        'notification_type': 'business',
        'created_at': '2026-09-30',
        'is_read': '否',
      });
      expect(unread.isRead, false);

      final missing = AppNotification.fromJson({
        'id': 'n-3',
        'title': 't',
        'content': 'c',
        'created_at': '2026-09-30',
      });
      expect(missing.isRead, false);
      expect(missing.notificationType, 'system'); // 默认值
      expect(missing.targetUser, '');
      expect(missing.senderName, '');
      expect(missing.readAt, '');
    });

    test('toJson 应把 isRead 映射回 是/否', () {
      final read = AppNotification(
        id: 'n-4',
        title: 't',
        content: 'c',
        notificationType: 'business',
        isRead: true,
        createdAt: '2026-09-30',
      );
      expect(read.toJson()['is_read'], '是');

      final unread = AppNotification(
        id: 'n-5',
        title: 't',
        content: 'c',
        notificationType: 'system',
        isRead: false,
        createdAt: '2026-09-30',
      );
      expect(unread.toJson()['is_read'], '否');
    });

    test('toJson 往返保持其余字段', () {
      final n = AppNotification(
        id: 'n-6',
        title: '标题',
        content: '内容',
        notificationType: 'system',
        targetUser: 'u1',
        senderName: 'admin',
        isRead: true,
        createdAt: '2026-09-30T08:00:00',
        readAt: '2026-09-30T09:00:00',
      );
      final back = AppNotification.fromJson(n.toJson());
      expect(back.id, n.id);
      expect(back.title, n.title);
      expect(back.content, n.content);
      expect(back.notificationType, n.notificationType);
      expect(back.targetUser, n.targetUser);
      expect(back.senderName, n.senderName);
      expect(back.isRead, n.isRead);
      expect(back.createdAt, n.createdAt);
      expect(back.readAt, n.readAt);
    });

    test('getNotificationTypeText 应正确映射', () {
      expect(
          AppNotification(id: '', title: '', content: '', notificationType: 'system', createdAt: '')
              .getNotificationTypeText(),
          '系统通知');
      expect(
          AppNotification(id: '', title: '', content: '', notificationType: 'business', createdAt: '')
              .getNotificationTypeText(),
          '业务通知');
      expect(
          AppNotification(id: '', title: '', content: '', notificationType: 'other', createdAt: '')
              .getNotificationTypeText(),
          '通知');
    });
  });
}
