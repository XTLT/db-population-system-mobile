// NotificationApi 单元测试（传输层 mock）
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/notification_api.dart';
import 'package:population_mobile/models/notification.dart';

import '../test_helpers.dart';

Map<String, dynamic> _notifJson(String id) => {
      'id': id,
      'title': '通知$id',
      'content': '内容$id',
      'notification_type': 'system',
      'target_user': '',
      'sender_name': 'admin',
      'is_read': '是',
      'created_at': '2024-01-01 10:00:00',
      'read_at': '2024-01-01 11:00:00',
    };

void main() {
  ensureTestBinding();

  group('NotificationApi.getNotifications', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async => jsonResponse({
            'notifications': [_notifJson('n1'), _notifJson('n2')],
          }));
    });

    test('GET /api/notifications 携带 limit，解析为 AppNotification', () async {
      final list = await NotificationApi.getNotifications(limit: 10);
      final req = rec.last()!;
      expect(req.method, 'GET');
      expect(req.path, '/api/notifications');
      expect(req.queryParameters['limit'], 10);
      expect(list, hasLength(2));
      expect(list[0], isA<AppNotification>());
      expect(list[0].id, 'n1');
      expect(list[0].isRead, isTrue); // is_read == '是'
    });

    test('notifications 缺省返回空列表', () async {
      installMockAdapter((options) async => jsonResponse({}));
      expect(await NotificationApi.getNotifications(), isEmpty);
    });

    test('500 时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        NotificationApi.getNotifications(),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('获取通知列表失败'))),
      );
    });
  });

  group('NotificationApi.getUnreadCount', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('GET /api/notifications/unread-count 返回 count', () async {
      rec = installMockAdapter(
          (options) async => jsonResponse({'count': 7}));
      expect(await NotificationApi.getUnreadCount(), 7);
      expect(rec.last()!.method, 'GET');
      expect(rec.last()!.path, '/api/notifications/unread-count');
    });

    test('count 缺省时返回 0', () async {
      installMockAdapter((options) async => jsonResponse({}));
      expect(await NotificationApi.getUnreadCount(), 0);
    });

    test('500 时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        NotificationApi.getUnreadCount(),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('获取未读数量失败'))),
      );
    });
  });

  group('NotificationApi.markAsRead', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('POST /api/notifications/n1/read 且 success=true 返回 true', () async {
      rec = installMockAdapter(
          (options) async => jsonResponse({'success': true}));
      expect(await NotificationApi.markAsRead('n1'), isTrue);
      expect(rec.last()!.method, 'POST');
      expect(rec.last()!.path, '/api/notifications/n1/read');
    });

    test('success=false 返回 false', () async {
      installMockAdapter(
          (options) async => jsonResponse({'success': false}));
      expect(await NotificationApi.markAsRead('n1'), isFalse);
    });

    test('缺省 success 视为 false', () async {
      installMockAdapter((options) async => jsonResponse({}));
      expect(await NotificationApi.markAsRead('n1'), isFalse);
    });
  });

  group('NotificationApi.sendNotification', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('POST /api/notifications/send 携带全部字段', () async {
      rec = installMockAdapter(
          (options) async => jsonResponse({'success': true}));
      final ok = await NotificationApi.sendNotification(
        title: '新通知',
        content: '请查收',
        notificationType: 'business',
        targetUser: 'zhangsan',
      );
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/notifications/send');
      expect(req.data['title'], '新通知');
      expect(req.data['content'], '请查收');
      expect(req.data['notification_type'], 'business');
      expect(req.data['target_user'], 'zhangsan');
      expect(ok, isTrue);
    });

    test('notificationType/targetUser 使用默认值', () async {
      rec = installMockAdapter(
          (options) async => jsonResponse({'success': true}));
      await NotificationApi.sendNotification(title: 't', content: 'c');
      final data = rec.last()!.data as Map;
      expect(data['notification_type'], 'system');
      expect(data['target_user'], '');
    });

    test('500 时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        NotificationApi.sendNotification(title: 't', content: 'c'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('发送通知失败'))),
      );
    });
  });
}
