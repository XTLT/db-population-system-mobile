/// 到龄提醒待办名单（`/api/notifications/age-notice` 返回）。
///
/// 名单是累积的：某期提醒出现过、还没办的人会一直留着；
/// 已办理的人当月仍留在名单里（`handled=true`），下个自然月才消失。
class AgeNoticeData {
  final String monthLabel;
  final String monthKey;
  final String currentMonth;
  final List<AgeNoticeGroup> groups;

  const AgeNoticeData({
    this.monthLabel = '',
    this.monthKey = '',
    this.currentMonth = '',
    this.groups = const [],
  });

  /// 名单总人数（含本月已办理的）
  int get total => groups.fold(0, (sum, g) => sum + g.persons.length);

  /// 还没办理的人数
  int get pendingCount =>
      groups.fold(0, (sum, g) => sum + g.pendingCount);

  /// 本月已办理的人数
  int get handledCount => total - pendingCount;

  bool get isEmpty => total == 0;

  factory AgeNoticeData.fromJson(Map<String, dynamic> json) {
    return AgeNoticeData(
      monthLabel: (json['month_label'] ?? '').toString(),
      monthKey: (json['month_key'] ?? '').toString(),
      currentMonth: (json['current_month'] ?? '').toString(),
      groups: ((json['groups'] as List?) ?? const [])
          .whereType<Map>()
          .map((raw) => AgeNoticeGroup.fromJson(Map<String, dynamic>.from(raw)))
          .toList(),
    );
  }

  /// 本地把一个人标成已办理：行还留着，只是按钮变成"已办理"。
  AgeNoticeData markHandled(String personId, int ageGroup) {
    return AgeNoticeData(
      monthLabel: monthLabel,
      monthKey: monthKey,
      currentMonth: currentMonth,
      groups: groups
          .map((g) => g.age == ageGroup ? g.markHandled(personId) : g)
          .toList(),
    );
  }
}

class AgeNoticeGroup {
  final int age;
  final List<AgeNoticePerson> persons;

  const AgeNoticeGroup({required this.age, this.persons = const []});

  int get pendingCount => persons.where((p) => !p.handled).length;

  int get handledCount => persons.where((p) => p.handled).length;

  factory AgeNoticeGroup.fromJson(Map<String, dynamic> json) {
    return AgeNoticeGroup(
      age: (json['age'] as num?)?.toInt() ?? 0,
      persons: ((json['persons'] as List?) ?? const [])
          .whereType<Map>()
          .map((raw) =>
              AgeNoticePerson.fromJson(Map<String, dynamic>.from(raw)))
          .toList(),
    );
  }

  AgeNoticeGroup markHandled(String personId) {
    return AgeNoticeGroup(
      age: age,
      persons: persons
          .map((p) => p.personId == personId ? p.asHandled() : p)
          .toList(),
    );
  }
}

class AgeNoticePerson {
  final String personId;
  final String name;
  final String idCard;
  final String birthday;
  final String address;
  final String groupName;
  final String phone;
  final String targetMonth;
  final String targetLabel;
  final bool handled;

  const AgeNoticePerson({
    required this.personId,
    this.name = '',
    this.idCard = '',
    this.birthday = '',
    this.address = '',
    this.groupName = '',
    this.phone = '',
    this.targetMonth = '',
    this.targetLabel = '',
    this.handled = false,
  });

  factory AgeNoticePerson.fromJson(Map<String, dynamic> json) {
    return AgeNoticePerson(
      personId: (json['person_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      idCard: (json['id_card'] ?? '').toString(),
      birthday: (json['birthday'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      groupName: (json['group_name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      targetMonth: (json['target_month'] ?? '').toString(),
      targetLabel: (json['target_label'] ?? '').toString(),
      handled: json['handled'] == true,
    );
  }

  AgeNoticePerson asHandled() {
    return AgeNoticePerson(
      personId: personId,
      name: name,
      idCard: idCard,
      birthday: birthday,
      address: address,
      groupName: groupName,
      phone: phone,
      targetMonth: targetMonth,
      targetLabel: targetLabel,
      handled: true,
    );
  }

  /// 「12 月到龄 · 身份证 · 小组 地址 · 生日 · 电话」，空字段不占位。
  String get detailLine {
    final where = [groupName, address].where((x) => x.isNotEmpty).join(' ');
    final parts = <String>[
      if (targetLabel.isNotEmpty) '$targetLabel到龄',
      if (idCard.isNotEmpty) idCard,
      if (where.isNotEmpty) where,
      if (birthday.isNotEmpty) '生日 $birthday',
      if (phone.isNotEmpty) phone,
    ];
    return parts.join('  ·  ');
  }
}
