import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/api/student_api.dart';
import 'package:population_mobile/models/student.dart';

import '../test_helpers.dart';

Map<String, dynamic> bodyOf(RequestOptions options) {
  final data = options.data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String && data.isNotEmpty) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  return {};
}

Map<String, dynamic> studentJson({
  String idCard = '110101201001011234',
  String name = '学生甲',
}) {
  return {
    'id_card': idCard,
    'name': name,
    'school_name': '一小',
    'grade': '三年级',
    'class_name': '1班',
  };
}

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  group('StudentApi.searchStudents', () {
    test('GET /api/students/search?name=，解析 data.results 为 Student 列表', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'results': [studentJson(), studentJson(name: '学生乙')],
          }));
      final list = await StudentApi.searchStudents('学生');
      final req = rec.last()!;
      expect(req.path, '/api/students/search');
      expect(req.method, 'GET');
      expect(req.queryParameters['name'], '学生');
      expect(list.length, 2);
      expect(list[0], isA<Student>());
      expect(list[0].name, '学生甲');
      expect(list[0].schoolName, '一小');
      expect(list[1].name, '学生乙');
    });

    test('results 缺省返回空列表', () async {
      installMockAdapter((o) => jsonResponse({}));
      expect(await StudentApi.searchStudents('空'), isEmpty);
    });

    test('HTTP 500：抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StudentApi.searchStudents('x'), throwsA(isA<Exception>()));
    });
  });

  group('StudentApi.getAllStudents', () {
    test('无参数：GET /api/students，query 不含 limit/offset，解析 data.students', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'students': [studentJson()],
          }));
      final list = await StudentApi.getAllStudents();
      final req = rec.last()!;
      expect(req.path, '/api/students');
      expect(req.queryParameters.containsKey('limit'), false);
      expect(req.queryParameters.containsKey('offset'), false);
      expect(list.length, 1);
      expect(list[0].name, '学生甲');
    });

    test('传 limit/offset：仅非空参数入 query', () async {
      final rec = installMockAdapter((o) => jsonResponse({'students': []}));
      await StudentApi.getAllStudents(limit: 20, offset: 40);
      final q = rec.last()!.queryParameters;
      expect(q['limit'], 20);
      expect(q['offset'], 40);
    });

    test('只传 limit：不带 offset', () async {
      final rec = installMockAdapter((o) => jsonResponse({'students': []}));
      await StudentApi.getAllStudents(limit: 10);
      final q = rec.last()!.queryParameters;
      expect(q['limit'], 10);
      expect(q.containsKey('offset'), false);
    });

    test('students 缺省返回空列表', () async {
      installMockAdapter((o) => jsonResponse({}));
      expect(await StudentApi.getAllStudents(), isEmpty);
    });

    test('非 200（HTTP 500）抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StudentApi.getAllStudents(), throwsA(isA<Exception>()));
    });
  });

  group('StudentApi.getStudent', () {
    test('GET /api/student/<id>，原样透传 data.student', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'student': {'id_card': '110', 'name': '单人'},
          }));
      final m = await StudentApi.getStudent('110');
      expect(rec.last()!.path, '/api/student/110');
      expect(m['name'], '单人');
    });

    test('非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 404));
      expect(() => StudentApi.getStudent('nope'), throwsA(isA<Exception>()));
    });
  });

  group('StudentApi.add / update / delete', () {
    test('addStudent: POST /api/student，body 透传，success=true 返回 true', () async {
      final rec = installMockAdapter((o) => jsonResponse({'success': true}));
      final ok = await StudentApi.addStudent({'name': '新学生', 'id_card': 'N1'});
      final req = rec.last()!;
      expect(req.path, '/api/student');
      expect(req.method, 'POST');
      expect(bodyOf(req)['name'], '新学生');
      expect(ok, true);
    });

    test('addStudent: success=false 返回 false', () async {
      installMockAdapter((o) => jsonResponse({'success': false}));
      expect(await StudentApi.addStudent({'name': 'x'}), false);
    });

    test('updateStudent: PUT /api/student/<id>，body 透传', () async {
      final rec = installMockAdapter((o) => jsonResponse({'success': true}));
      final ok = await StudentApi.updateStudent('110', {'grade': '四年级'});
      final req = rec.last()!;
      expect(req.path, '/api/student/110');
      expect(req.method, 'PUT');
      expect(bodyOf(req)['grade'], '四年级');
      expect(ok, true);
    });

    test('deleteStudent: DELETE /api/student/<id>，成功返回 true', () async {
      final rec = installMockAdapter((o) => jsonResponse({'success': true}));
      expect(await StudentApi.deleteStudent('110'), true);
      expect(rec.last()!.path, '/api/student/110');
      expect(rec.last()!.method, 'DELETE');
    });

    test('增删改网络错误：抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StudentApi.addStudent({'name': 'x'}), throwsA(isA<Exception>()));
      expect(() => StudentApi.updateStudent('id', {'a': 1}), throwsA(isA<Exception>()));
      expect(() => StudentApi.deleteStudent('id'), throwsA(isA<Exception>()));
    });
  });

  group('StudentApi.getStudentStatistics', () {
    test('GET /api/students/statistics，透传 data', () async {
      final rec = installMockAdapter((o) => jsonResponse({'total': 33}));
      final m = await StudentApi.getStudentStatistics();
      expect(rec.last()!.path, '/api/students/statistics');
      expect(m['total'], 33);
    });

    test('非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StudentApi.getStudentStatistics(), throwsA(isA<Exception>()));
    });
  });
}
