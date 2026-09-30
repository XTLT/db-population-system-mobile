
enum OperationType {
  create,
  update,
  delete,
  addPhoto,
  deletePhoto,
}

enum SyncStatus {
  pending,
  syncing,
  synced,
  conflict,
  failed,
}

class OfflineOperation {
  final String id;
  final OperationType type;
  final String entityType; 
  final String entityId;
  final Map<String, dynamic> data;
  final SyncStatus status;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final String? conflictReason;
  final int retryCount;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.data,
    this.status = SyncStatus.pending,
    required this.createdAt,
    this.syncedAt,
    this.conflictReason,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'entity_type': entityType,
        'entity_id': entityId,
        'data': data,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
        'conflict_reason': conflictReason,
        'retry_count': retryCount,
      };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) =>
      OfflineOperation(
        id: json['id'],
        // BUG-05：枚举匹配加 orElse 兜底，避免旧/损坏缓存里缺省或未知值抛 StateError。
        // 未知 type 回落到 update（非破坏性默认：不删记录、不盲目新增）。
        type: OperationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => OperationType.update,
        ),
        entityType: json['entity_type'],
        entityId: json['entity_id'],
        data: Map<String, dynamic>.from(json['data']),
        // 缺省/未知 status 回落到 pending（与构造器默认一致）
        status: SyncStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SyncStatus.pending,
        ),
        createdAt: DateTime.parse(json['created_at']),
        syncedAt: json['synced_at'] != null
            ? DateTime.parse(json['synced_at'])
            : null,
        conflictReason: json['conflict_reason'],
        retryCount: json['retry_count'] ?? 0,
      );

  OfflineOperation copyWith({
    String? id,
    OperationType? type,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? data,
    SyncStatus? status,
    DateTime? createdAt,
    DateTime? syncedAt,
    String? conflictReason,
    int? retryCount,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      conflictReason: conflictReason ?? this.conflictReason,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
