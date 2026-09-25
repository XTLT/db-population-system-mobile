
import 'api_client.dart';
import '../models/notification.dart';

class NotificationApi {
  static final _dio = ApiClient().dio;

  
  static Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    try {
      final response = await _dio.get('/api/notifications', queryParameters: {
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> notifications = data['notifications'] ?? [];
        return notifications.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception('获取通知列表失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取通知列表失败: $e');
    }
  }

  
  static Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/api/notifications/unread-count');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['count'] ?? 0;
      } else {
        throw Exception('获取未读数量失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取未读数量失败: $e');
    }
  }

  
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _dio.post('/api/notifications/$notificationId/read');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] ?? false;
      } else {
        throw Exception('标记已读失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('标记已读失败: $e');
    }
  }

  
  static Future<bool> sendNotification({
    required String title,
    required String content,
    String notificationType = 'system',
    String targetUser = '',
  }) async {
    try {
      final response = await _dio.post('/api/notifications/send', data: {
        'title': title,
        'content': content,
        'notification_type': notificationType,
        'target_user': targetUser,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] ?? false;
      } else {
        throw Exception('发送通知失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('发送通知失败: $e');
    }
  }
}
