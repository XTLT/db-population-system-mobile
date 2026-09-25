import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/student.dart';

void main() {
  group('Student Model Tests', () {
    test('should create Student from JSON', () {
      final json = {
        'id_card': '110101200501011234',
        'name': '王小明',
        'school_name': '北京市第一中学',
        'grade': 'G7',
        'class_name': '1班',
        'guardian': '王大强',
        'guardian_phone': '13800138000',
        'is_left_behind': '否',
        'student_status': '在读',
        'enrollment_date': '2023-09-01',
      };

      final student = Student.fromJson(json);

      expect(student.idCard, '110101200501011234');
      expect(student.name, '王小明');
      expect(student.schoolName, '北京市第一中学');
      expect(student.grade, 'G7');
      expect(student.className, '1班');
      expect(student.guardian, '王大强');
      expect(student.guardianPhone, '13800138000');
      expect(student.isLeftBehind, '否');
      expect(student.studentStatus, '在读');
      expect(student.enrollmentDate, '2023-09-01');
    });

    test('should convert Student to JSON', () {
      final student = Student(
        idCard: '110101200501011234',
        name: '王小明',
        schoolName: '北京市第一中学',
        grade: 'G7',
      );

      final json = student.toJson();

      expect(json['id_card'], '110101200501011234');
      expect(json['name'], '王小明');
      expect(json['school_name'], '北京市第一中学');
      expect(json['grade'], 'G7');
    });

    test('should handle null values in JSON', () {
      final json = <String, dynamic>{};

      final student = Student.fromJson(json);

      expect(student.idCard, isNull);
      expect(student.name, isNull);
      expect(student.schoolName, isNull);
      expect(student.grade, isNull);
    });

    test('should return correct display name', () {
      final studentWithName = Student(name: '王小明');
      expect(studentWithName.displayName, '王小明');

      final studentWithoutName = Student();
      expect(studentWithoutName.displayName, '未知');
    });

    test('should handle all student fields', () {
      final student = Student(
        idCard: '110101200601011234',
        name: '李小红',
        schoolName: '上海市实验小学',
        grade: 'G3',
        className: '2班',
        guardian: '李大刚',
        guardianPhone: '13900139000',
        isLeftBehind: '是',
        studentStatus: '在读',
        enrollmentDate: '2022-09-01',
      );

      expect(student.idCard, '110101200601011234');
      expect(student.name, '李小红');
      expect(student.schoolName, '上海市实验小学');
      expect(student.grade, 'G3');
      expect(student.className, '2班');
      expect(student.guardian, '李大刚');
      expect(student.guardianPhone, '13900139000');
      expect(student.isLeftBehind, '是');
      expect(student.studentStatus, '在读');
      expect(student.enrollmentDate, '2022-09-01');
    });

    test('should handle different grades', () {
      final kindergarten = Student(grade: 'K2');
      expect(kindergarten.grade, 'K2');

      final primary = Student(grade: 'G5');
      expect(primary.grade, 'G5');

      final middle = Student(grade: 'G8');
      expect(middle.grade, 'G8');

      final high = Student(grade: 'G11');
      expect(high.grade, 'G11');

      final university = Student(grade: 'U3');
      expect(university.grade, 'U3');

      final graduated = Student(grade: 'GRADUATED');
      expect(graduated.grade, 'GRADUATED');
    });

    test('should handle different student statuses', () {
      final studying = Student(studentStatus: '在读');
      expect(studying.studentStatus, '在读');

      final repeat = Student(studentStatus: '留级');
      expect(repeat.studentStatus, '留级');

      final suspended = Student(studentStatus: '休学');
      expect(suspended.studentStatus, '休学');

      final transferred = Student(studentStatus: '转学');
      expect(transferred.studentStatus, '转学');

      final graduated = Student(studentStatus: '毕业');
      expect(graduated.studentStatus, '毕业');
    });
  });
}
