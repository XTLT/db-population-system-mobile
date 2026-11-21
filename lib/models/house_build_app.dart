/// 宅基地建房申请的列表项模型（详情用动态 Map，字段与申请表/审批表一一对应）。
class HouseBuildSummary {
  final String id;
  final String appNo;
  final String ownerName;
  final String ownerIdCard;
  final String huHao;
  final String groupName;
  final String applyLandArea;
  final double applyAreaNum;
  final String status;
  final String createdAt;

  const HouseBuildSummary({
    required this.id,
    required this.appNo,
    required this.ownerName,
    required this.ownerIdCard,
    required this.huHao,
    required this.groupName,
    required this.applyLandArea,
    required this.applyAreaNum,
    required this.status,
    required this.createdAt,
  });

  factory HouseBuildSummary.fromJson(Map<String, dynamic> json) {
    return HouseBuildSummary(
      id: (json['id'] ?? '').toString(),
      appNo: (json['app_no'] ?? '').toString(),
      ownerName: (json['owner_name'] ?? '').toString(),
      ownerIdCard: (json['owner_id_card'] ?? '').toString(),
      huHao: (json['hu_hao'] ?? '').toString(),
      groupName: (json['group_name'] ?? '').toString(),
      applyLandArea: (json['apply_land_area'] ?? '').toString(),
      applyAreaNum: json['apply_area_num'] is num
          ? (json['apply_area_num'] as num).toDouble()
          : double.tryParse('${json['apply_area_num'] ?? 0}') ?? 0,
      status: (json['status'] ?? 'draft').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  String get statusText {
    switch (status) {
      case 'submitted':
        return '已提交';
      case 'approved':
        return '已审批';
      case 'draft':
        return '草稿';
      default:
        return status;
    }
  }

  String get areaText {
    if (applyAreaNum <= 0) return applyLandArea;
    final text = applyAreaNum
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'\.?0+$'), '');
    return text;
  }
}
