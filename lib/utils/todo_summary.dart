import '../models/notification.dart';

/// 数据体检汇总：总条数、涉及人数、最突出的 2 个必填项。
class HealthTodoSummary {
  final int issueCount;
  final int issuePersons;
  final String topItems;

  const HealthTodoSummary({
    this.issueCount = 0,
    this.issuePersons = 0,
    this.topItems = '',
  });

  bool get isEmpty => issueCount == 0;
}

/// 到龄提醒汇总：下月满 60/80 周岁人数、未读提醒条数、月份文案。
class AgeTodoSummary {
  final int persons;
  final int unread;
  final String monthLabel;

  const AgeTodoSummary({
    this.persons = 0,
    this.unread = 0,
    this.monthLabel = '',
  });

  bool get isEmpty => persons == 0;
}

/// 解析 `/api/persons/data-health` 返回。
///
/// 非必填项（required=false，如学生缺监护人电话）不计入"待补录"，
/// 与页面和服务端"合计只累计必填项"的口径保持一致。
HealthTodoSummary summarizeDataHealth(Map<String, dynamic> data) {
  final checks = (data['checks'] as List?) ?? const [];

  final tops = <String>[];
  int requiredSum = 0;
  for (final raw in checks) {
    if (raw is! Map) continue;
    final item = Map<String, dynamic>.from(raw);
    // 兼容服务端把布尔值序列化成 0/1 的情况
    if (item['required'] == false || item['required'] == 0) continue;
    final count = (item['count'] as num?)?.toInt() ?? 0;
    if (count <= 0) continue;
    requiredSum += count;
    if (tops.length < 2) tops.add('${item['label'] ?? ''} $count');
  }

  // 旧版服务端没有 total_issue_count，用必填项之和兜底，避免误显示"数据完整"
  final issueCount =
      (data['total_issue_count'] as num?)?.toInt() ?? requiredSum;
  final issuePersons =
      (data['total_issue_persons'] as num?)?.toInt() ?? 0;

  return HealthTodoSummary(
    issueCount: issueCount,
    issuePersons: issuePersons,
    topItems: tops.join(' · '),
  );
}

/// 解析通知列表中的到龄提醒。
///
/// 服务端懒生成的通知 id 固定为 `notif_age60_YYYYMM` / `notif_age80_YYYYMM`，
/// 标题形如「11 月到龄提醒：满 60 周岁（12 人）」。
AgeTodoSummary summarizeAgeNotifications(List<AppNotification> list) {
  final ageItems = list.where((n) => n.id.startsWith('notif_age')).toList();
  if (ageItems.isEmpty) return const AgeTodoSummary();

  final countPattern = RegExp(r'（(\d+)\s*人）');
  int persons = 0;
  int unread = 0;
  for (final n in ageItems) {
    final match = countPattern.firstMatch(n.title);
    if (match != null) {
      persons += int.tryParse(match.group(1) ?? '') ?? 0;
    }
    if (!n.isRead) unread++;
  }

  String monthLabel = '';
  for (final n in ageItems) {
    final monthMatch = RegExp(r'^(\d+)\s*月').firstMatch(n.title);
    if (monthMatch != null) {
      monthLabel = '${monthMatch.group(1)} 月';
      break;
    }
  }

  return AgeTodoSummary(
    persons: persons,
    unread: unread,
    monthLabel: monthLabel,
  );
}
