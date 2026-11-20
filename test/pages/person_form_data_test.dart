import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/pages/person/person_form_data.dart';

void main() {
  group('normalizeGrade', () {
    test('标准代码原样返回', () {
      expect(normalizeGrade('G3'), 'G3');
      expect(normalizeGrade('U4'), 'U4');
      expect(normalizeGrade('GRADUATED'), 'GRADUATED');
    });

    test('中文显示名转成代码', () {
      expect(normalizeGrade('小学3年级'), 'G3');
      expect(normalizeGrade('高二'), 'G11');
    });

    test('历史数字写法转成代码', () {
      expect(normalizeGrade('3'), 'G3');
      expect(normalizeGrade('12'), 'G12');
    });

    test('认不出的值原样保留，不抹掉历史数据', () {
      expect(normalizeGrade('实验班'), '实验班');
    });

    test('空值返回 null', () {
      expect(normalizeGrade(null), isNull);
      expect(normalizeGrade(''), isNull);
    });
  });

  group('calculateEnrollmentAndGraduation', () {
    test('9 月后按当前年推算入学与毕业', () {
      final result = calculateEnrollmentAndGraduation(
        grade: 'G6',
        enrollmentDate: '',
        graduationDate: '',
        now: DateTime(2026, 9, 10),
      );

      expect(result['enrollment_date'], '2021-09-01');
      // 2021 入学 + 已读 5 年 + 剩余 1 年
      expect(result['graduation_date'], '2027-06-30');
    });

    test('9 月前顺延一年', () {
      final result = calculateEnrollmentAndGraduation(
        grade: 'G1',
        enrollmentDate: '',
        graduationDate: '',
        now: DateTime(2026, 3, 1),
      );

      expect(result['enrollment_date'], '2025-09-01');
      expect(result['graduation_date'], '2031-06-30');
    });

    test('已填写的日期不被覆盖', () {
      final result = calculateEnrollmentAndGraduation(
        grade: 'G3',
        enrollmentDate: '2024-09-01',
        graduationDate: '2026-06-30',
        now: DateTime(2026, 9, 10),
      );

      expect(result['enrollment_date'], '2024-09-01');
      expect(result['graduation_date'], '2026-06-30');
    });

    test('没有年级时原样返回空值', () {
      final result = calculateEnrollmentAndGraduation(
        grade: null,
        enrollmentDate: '',
        graduationDate: '',
        now: DateTime(2026, 9, 10),
      );

      expect(result['enrollment_date'], '');
      expect(result['graduation_date'], '');
    });

    test('已毕业不推算毕业日期', () {
      final result = calculateEnrollmentAndGraduation(
        grade: 'GRADUATED',
        enrollmentDate: '',
        graduationDate: '',
        now: DateTime(2026, 9, 10),
      );

      expect(result['enrollment_date'], '2026-09-01');
      expect(result['graduation_date'], '');
    });
  });
}
