class AppNotification {
  final String id;
  final String title;
  final String content;
  final String notificationType;
  final String targetUser;
  final String senderName;
  final bool isRead;
  final String createdAt;
  final String readAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.notificationType,
    this.targetUser = '',
    this.senderName = '',
    this.isRead = false,
    required this.createdAt,
    this.readAt = '',
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      notificationType: json['notification_type'] ?? 'system',
      targetUser: json['target_user'] ?? '',
      senderName: json['sender_name'] ?? '',
      isRead: json['is_read'] == '是',
      createdAt: json['created_at'] ?? '',
      readAt: json['read_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'notification_type': notificationType,
      'target_user': targetUser,
      'sender_name': senderName,
      'is_read': isRead ? '是' : '否',
      'created_at': createdAt,
      'read_at': readAt,
    };
  }

  String getNotificationTypeText() {
    switch (notificationType) {
      case 'system':
        return '系统通知';
      case 'business':
        return '业务通知';
      default:
        return '通知';
    }
  }
}
