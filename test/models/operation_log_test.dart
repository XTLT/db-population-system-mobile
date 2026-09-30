import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/operation_log.dart';

void main() {
  group('OperationLog Model Tests', () {
    test('fromJson 应字段级解析全部 8 个字段', () {
      final json = {
        'id': 'log-1',
        'username': 'admin',
        'operation_type': '删除人员',
        'operation_target': '张三',
        'ip_address': '192.168.1.10',
        'client_type': 'android',
        'created_at': '2026-09-30T10:00:00',
        'is_high_risk': '是',
      };

      final log = OperationLog.fromJson(json);

      expect(log.id, 'log-1');
      expect(log.username, 'admin');
      expect(log.operationType, '删除人员');
      expect(log.operationTarget, '张三');
      expect(log.ipAddress, '192.168.1.10');
      expect(log.clientType, 'android');
      expect(log.createdAt, '2026-09-30T10:00:00');
      expect(log.isHighRisk, '是');
    });

    test('fromJson 缺省值应正确（is_high_risk 默认 否）', () {
      final log = OperationLog.fromJson(<String, dynamic>{});
      expect(log.id, '');
      expect(log.username, '');
      expect(log.operationType, '');
      expect(log.operationTarget, '');
      expect(log.ipAddress, '');
      expect(log.clientType, '');
      expect(log.createdAt, '');
      expect(log.isHighRisk, '否');
    });

    test('toJson 应输出全部字段并往返一致', () {
      final log = OperationLog(
        id: 'log-2',
        username: 'editor',
        operationType: '新增人员',
        operationTarget: '李四',
        ipAddress: '10.0.0.5',
        clientType: 'ios',
        createdAt: '2026-09-30T11:00:00',
        isHighRisk: '否',
      );

      final json = log.toJson();
      expect(json['id'], 'log-2');
      expect(json['username'], 'editor');
      expect(json['operation_type'], '新增人员');
      expect(json['operation_target'], '李四');
      expect(json['ip_address'], '10.0.0.5');
      expect(json['client_type'], 'ios');
      expect(json['created_at'], '2026-09-30T11:00:00');
      expect(json['is_high_risk'], '否');

      final back = OperationLog.fromJson(json);
      expect(back.id, log.id);
      expect(back.username, log.username);
      expect(back.operationType, log.operationType);
      expect(back.operationTarget, log.operationTarget);
      expect(back.ipAddress, log.ipAddress);
      expect(back.clientType, log.clientType);
      expect(back.createdAt, log.createdAt);
      expect(back.isHighRisk, log.isHighRisk);
    });

    test('isHighRiskOperation getter 应在 isHighRisk=="是" 时为 true', () {
      expect(
          OperationLog(id: '', username: '', operationType: '', operationTarget: '', ipAddress: '', clientType: '', createdAt: '', isHighRisk: '是')
              .isHighRiskOperation,
          true);
      expect(
          OperationLog(id: '', username: '', operationType: '', operationTarget: '', ipAddress: '', clientType: '', createdAt: '', isHighRisk: '否')
              .isHighRiskOperation,
          false);
    });

    test('displayText 应拼接 operationType 与 operationTarget', () {
      final withTarget = OperationLog(
          id: '', username: '', operationType: '编辑', operationTarget: '王五', ipAddress: '', clientType: '', createdAt: '', isHighRisk: '否');
      expect(withTarget.displayText, '编辑 - 王五');

      final emptyTarget = OperationLog(
          id: '', username: '', operationType: '登录', operationTarget: '', ipAddress: '', clientType: '', createdAt: '', isHighRisk: '否');
      expect(emptyTarget.displayText, '登录');
    });
  });
}
