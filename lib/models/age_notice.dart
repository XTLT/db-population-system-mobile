/// 到龄提醒名单（`/api/notifications/age-notice` 返回）。
class AgeNoticeData {
  final String monthLabel;
  final String monthKey;
  final List<AgeNoticeGroup> groups;

  const AgeNoticeData({
    this.monthLabel = '',
    this.monthKey = '',
    this.groups = const [],
  });

  int get total => groups.fold(0, (sum, g) => sum + g.persons.length);

  bool get isEmpty => total == 0;

  factory AgeNoticeData.fromJson(Map<String, dynamic> json) {
    return AgeNoticeData(
      monthLabel: (json['month_label'] ?? '').toString(),
      monthKey: (json['month_key'] ?? '').toString(),
      groups: ((json['groups'] as List?) ?? const [])
          .whereType<Map>()
          .map((raw) => AgeNoticeGroup.fromJson(Map<String, dynamic>.from(raw)))
          .toList(),
    );
  }

  /// 办完一个人后本地先移除，界面立即跟着变，不用整页重新拉。
  AgeNoticeData without(String personId, int ageGroup) {
    return AgeNoticeData(
      monthLabel: monthLabel,
      monthKey: monthKey,
      groups: groups
          .map((g) => g.age == ageGroup ? g.without(personId) : g)
          .toList(),
    );
  }
}

class AgeNoticeGroup {
  final int age;
  final List<AgeNoticePerson> persons;

  const AgeNoticeGroup({required this.age, required this.persons});

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

  AgeNoticeGroup without(String personId) {
    return AgeNoticeGroup(
      age: age,
      persons: persons.where((p) => p.personId != personId).toList(),
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

  const AgeNoticePerson({
    required this.personId,
    this.name = '',
    this.idCard = '',
    this.birthday = '',
    this.address = '',
    this.groupName = '',
    this.phone = '',
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
    );
  }

  /// 「身份证 · 小组 地址 · 生日 · 电话」，空字段不占位。
  String get detailLine {
    final where = [groupName, address].where((x) => x.isNotEmpty).join(' ');
    final parts = <String>[
      if (idCard.isNotEmpty) idCard,
      if (where.isNotEmpty) where,
      if (birthday.isNotEmpty) '生日 $birthday',
      if (phone.isNotEmpty) phone,
    ];
    return parts.join('  ·  ');
  }
}
