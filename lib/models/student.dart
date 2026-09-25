
class Student {
  final String? idCard;
  final String? name;
  final String? schoolName;
  final String? grade;
  final String? className;
  final String? guardian;
  final String? guardianPhone;
  final String? isLeftBehind;
  final String? studentStatus;
  final String? enrollmentDate;
  final String? graduationDate;

  Student({
    this.idCard,
    this.name,
    this.schoolName,
    this.grade,
    this.className,
    this.guardian,
    this.guardianPhone,
    this.isLeftBehind,
    this.studentStatus,
    this.enrollmentDate,
    this.graduationDate,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      idCard: json['id_card'],
      name: json['name'],
      schoolName: json['school_name'],
      grade: json['grade'],
      className: json['class_name'],
      guardian: json['guardian'],
      guardianPhone: json['guardian_phone'],
      isLeftBehind: json['is_left_behind'],
      studentStatus: json['student_status'],
      enrollmentDate: json['enrollment_date'],
      graduationDate: json['graduation_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_card': idCard,
      'name': name,
      'school_name': schoolName,
      'grade': grade,
      'class_name': className,
      'guardian': guardian,
      'guardian_phone': guardianPhone,
      'is_left_behind': isLeftBehind,
      'student_status': studentStatus,
      'enrollment_date': enrollmentDate,
      'graduation_date': graduationDate,
    };
  }

  String get displayName => name ?? '未知';
}
