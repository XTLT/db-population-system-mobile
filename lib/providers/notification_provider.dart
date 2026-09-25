import 'package:flutter/foundation.dart';
import '../api/notification_api.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';


class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  
  Future<void> loadNotifications({int limit = 50}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await NotificationApi.getNotifications(limit: limit);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await NotificationApi.getUnreadCount();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  
  Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await NotificationApi.markAsRead(notificationId);
      if (success) {
        
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          _notifications[index] = AppNotification(
            id: notification.id,
            title: notification.title,
            content: notification.content,
            notificationType: notification.notificationType,
            targetUser: notification.targetUser,
            senderName: notification.senderName,
            isRead: true,
            createdAt: notification.createdAt,
            readAt: DateTime.now().toIso8601String(),
          );
        }
        
        
        if (_unreadCount > 0) {
          _unreadCount--;
        }
        
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  
  Future<bool> sendNotification({
    required String title,
    required String content,
    String notificationType = 'system',
    String targetUser = '',
  }) async {
    try {
      final success = await NotificationApi.sendNotification(
        title: title,
        content: content,
        notificationType: notificationType,
        targetUser: targetUser,
      );
      
      if (success) {
        
        await loadNotifications();
      }
      
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  
  Future<void> showLocalNotification(AppNotification notification) async {
    await NotificationService.showNotification(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.content,
      payload: notification.id,
    );
  }

  
  Future<void> refresh() async {
    await Future.wait([
      loadNotifications(),
      loadUnreadCount(),
    ]);
  }

  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
