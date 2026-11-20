/// 人员编辑页共享的年级字典与归一化规则。
///
/// 从 `person_edit_page.dart` 抽出来，纯数据 + 纯函数，便于单测；
/// 页面只负责取值与渲染。

const Map<String, String> kGradeOptions = {
  "T1": "托班",
  "K1": "幼儿园小班", "K2": "幼儿园中班", "K3": "幼儿园大班",
  "G1": "小学1年级", "G2": "小学2年级", "G3": "小学3年级",
  "G4": "小学4年级", "G5": "小学5年级", "G6": "小学6年级",
  "G7": "初中1年级", "G8": "初中2年级", "G9": "初中3年级",
  "G10": "高中1年级", "G11": "高中2年级", "G12": "高中3年级",
  "V1": "职高1年级", "V2": "职高2年级", "V3": "职高3年级",
  "J1": "技校1年级", "J2": "技校2年级", "J3": "技校3年级",
  "C1": "中专1年级", "C2": "中专2年级", "C3": "中专3年级",
  "Z1": "专科1年级", "Z2": "专科2年级", "Z3": "专科3年级",
  "U1": "大学1年级", "U2": "大学2年级", "U3": "大学3年级",
  "U4": "大学4年级", "U5": "大学5年级",
  "M1": "硕士1年级", "M2": "硕士2年级", "M3": "硕士3年级",
  "D1": "博士1年级", "D2": "博士2年级", "D3": "博士3年级", "D4": "博士4年级",
  "GRADUATED": "已毕业",
};

final Map<String, String> kGradeDisplayToCode = {
  for (final e in kGradeOptions.entries) e.value: e.key
};

const Map<String, String> kOldGradeToCode = {
  '一年级': 'G1', '二年级': 'G2', '三年级': 'G3',
  '四年级': 'G4', '五年级': 'G5', '六年级': 'G6',
  '七年级': 'G7', '八年级': 'G8', '九年级': 'G9',
  '高一': 'G10', '高二': 'G11', '高三': 'G12',
  '1': 'G1', '2': 'G2', '3': 'G3', '4': 'G4', '5': 'G5', '6': 'G6',
  '7': 'G7', '8': 'G8', '9': 'G9',
  '10': 'G10', '11': 'G11', '12': 'G12',
};

/// 把标准代码 / 中文显示名 / 历史数字写法统一成代码；
/// 认不出的原样返回，避免把库里的历史值抹掉。
String? normalizeGrade(String? grade) {
  if (grade == null || grade.isEmpty) return null;
  if (kGradeOptions.containsKey(grade)) return grade;
  if (kGradeDisplayToCode.containsKey(grade)) return kGradeDisplayToCode[grade];
  if (kOldGradeToCode.containsKey(grade)) return kOldGradeToCode[grade];
  return grade;
}

/// 按年级推算入学/毕业日期；已有值不覆盖。
///
/// 规则：9 月后入学年份 = 当前年 - 已读偏移；9 月前顺延一年。
/// 毕业年份 = 入学年份 + 已读偏移 + 该年级剩余学年数。
/// 例：六年级在读（2026-2027 学年）→ 2021 入学、2027-06-30 毕业。
Map<String, String> calculateEnrollmentAndGraduation({
  required String? grade,
  required String enrollmentDate,
  required String graduationDate,
  DateTime? now,
}) {
  final date = now ?? DateTime.now();
  final currentYear = date.year;
  final currentMonth = date.month;

  String resultEnrollment = enrollmentDate;
  String resultGraduation = graduationDate;

  final gradeToYears = <String, int>{
    'T1': 2,
    'K1': 3, 'K2': 2, 'K3': 1,
    'G1': 6, 'G2': 5, 'G3': 4, 'G4': 3, 'G5': 2, 'G6': 1,
    'G7': 3, 'G8': 2, 'G9': 1,
    'G10': 3, 'G11': 2, 'G12': 1,
    'V1': 3, 'V2': 2, 'V3': 1,
    'J1': 3, 'J2': 2, 'J3': 1,
    'C1': 3, 'C2': 2, 'C3': 1,
    'Z1': 3, 'Z2': 2, 'Z3': 1,
    'U1': 4, 'U2': 3, 'U3': 2, 'U4': 1, 'U5': 0,
    'M1': 3, 'M2': 2, 'M3': 1,
    'D1': 4, 'D2': 3, 'D3': 2, 'D4': 1,
  };

  final gradeToOffset = <String, int>{
    'T1': 0,
    'K1': 0, 'K2': 1, 'K3': 2,
    'G1': 0, 'G2': 1, 'G3': 2, 'G4': 3, 'G5': 4, 'G6': 5,
    'G7': 0, 'G8': 1, 'G9': 2,
    'G10': 0, 'G11': 1, 'G12': 2,
    'V1': 0, 'V2': 1, 'V3': 2,
    'J1': 0, 'J2': 1, 'J3': 2,
    'C1': 0, 'C2': 1, 'C3': 2,
    'Z1': 0, 'Z2': 1, 'Z3': 2,
    'U1': 0, 'U2': 1, 'U3': 2, 'U4': 3, 'U5': 4,
    'M1': 0, 'M2': 1, 'M3': 2,
    'D1': 0, 'D2': 1, 'D3': 2, 'D4': 3,
  };

  if (grade != null && grade.isNotEmpty) {
    final offset = gradeToOffset[grade] ?? 0;

    final int enrollmentYear;
    if (currentMonth >= 9) {
      enrollmentYear = currentYear - offset;
    } else {
      enrollmentYear = currentYear - offset - 1;
    }

    if (resultEnrollment.isEmpty) {
      resultEnrollment = '$enrollmentYear-09-01';
    }

    if (resultGraduation.isEmpty) {
      final totalYears = gradeToYears[grade] ?? 0;
      if (totalYears > 0) {
        final gradYear = enrollmentYear + offset + totalYears;
        resultGraduation = '$gradYear-06-30';
      }
    }
  }

  return {
    'enrollment_date': resultEnrollment,
    'graduation_date': resultGraduation,
  };
}
