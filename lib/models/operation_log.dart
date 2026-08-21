
class OperationLog {
  final String id;
  final String username;
  final String operationType;
  final String operationTarget;
  final String ipAddress;
  final String clientType;
  final String createdAt;
  final String isHighRisk;

  OperationLog({
    required this.id,
    required this.username,
    required this.operationType,
    required this.operationTarget,
    required this.ipAddress,
    required this.clientType,
    required this.createdAt,
    required this.isHighRisk,
  });

  factory OperationLog.fromJson(Map<String, dynamic> json) {
    return OperationLog(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      operationType: json['operation_type'] ?? '',
      operationTarget: json['operation_target'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      clientType: json['client_type'] ?? '',
      createdAt: json['created_at'] ?? '',
      isHighRisk: json['is_high_risk'] ?? '否',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'operation_type': operationType,
      'operation_target': operationTarget,
      'ip_address': ipAddress,
      'client_type': clientType,
      'created_at': createdAt,
      'is_high_risk': isHighRisk,
    };
  }

  
  bool get isHighRiskOperation => isHighRisk == '是';

  
  String get displayText {
    if (operationTarget.isNotEmpty) {
      return '$operationType - $operationTarget';
    }
    return operationType;
  }
}
