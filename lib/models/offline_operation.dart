
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

  /// 离线编辑开始时的服务端基线版本（Person.updated_at）。
  /// 同步时回传给服务端，由 `PUT /api/person/<id>` 做 409 冲突判定。
  /// 为空表示没有基线（如新增人员、或列表接口未带 updated_at），服务端会跳过检测。
  final String? baseUpdatedAt;

  /// 连续失败后的下一次可重试时间，未到期时 syncAll 会跳过，
  /// 避免每次联网都把同一批失败项重新打一遍。
  final DateTime? nextRetryAt;

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
    this.baseUpdatedAt,
    this.nextRetryAt,
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
        'base_updated_at': baseUpdatedAt,
        'next_retry_at': nextRetryAt?.toIso8601String(),
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
        baseUpdatedAt: json['base_updated_at'] as String?,
        nextRetryAt: json['next_retry_at'] != null
            ? DateTime.parse(json['next_retry_at'])
            : null,
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
    String? baseUpdatedAt,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    bool clearConflictReason = false,
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
      conflictReason: clearConflictReason
          ? null
          : (conflictReason ?? this.conflictReason),
      retryCount: retryCount ?? this.retryCount,
      baseUpdatedAt: baseUpdatedAt ?? this.baseUpdatedAt,
      nextRetryAt:
          clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
    );
  }
}
