import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/custom_report.dart';

void main() {
  group('CustomReport Model Tests', () {
    test('fromJson 应字段级解析（含嵌套 dimensions/dateRange/filters）', () {
      final json = {
        'id': 'rpt-1',
        'title': '9月人口统计',
        'user_id': 'u-1',
        'report_type': 'person',
        'dimensions': ['village', 'age_group'],
        'date_range': {'start': '2026-09-01', 'end': '2026-09-30'},
        'chart_type': 'pie',
        'filters': {'dibao': '是'},
        'created_at': '2026-09-30T10:00:00',
        'updated_at': '2026-09-30T11:00:00',
      };

      final r = CustomReport.fromJson(json);

      expect(r.id, 'rpt-1');
      expect(r.title, '9月人口统计');
      expect(r.userId, 'u-1');
      expect(r.reportType, 'person');
      expect(r.dimensions, ['village', 'age_group']);
      expect(r.dateRange['start'], '2026-09-01');
      expect(r.dateRange['end'], '2026-09-30');
      expect(r.chartType, 'pie');
      expect(r.filters['dibao'], '是');
      expect(r.createdAt, '2026-09-30T10:00:00');
      expect(r.updatedAt, '2026-09-30T11:00:00');
    });

    test('fromJson 缺省值应正确（dimensions=[], dateRange={}, chartType=bar, filters={}）', () {
      final r = CustomReport.fromJson(<String, dynamic>{});
      expect(r.id, '');
      expect(r.title, '');
      expect(r.userId, isNull);
      expect(r.reportType, '');
      expect(r.dimensions, isEmpty);
      expect(r.dateRange, isEmpty);
      expect(r.chartType, 'bar');
      expect(r.filters, isEmpty);
      expect(r.createdAt, '');
      expect(r.updatedAt, isNull);
    });

    test('toJson 应输出全部字段并与 fromJson 往返一致', () {
      final r = CustomReport(
        id: 'rpt-2',
        title: '学生统计',
        userId: 'u-2',
        reportType: 'student',
        dimensions: ['school'],
        dateRange: {'start': '2026-01-01'},
        chartType: 'line',
        filters: {'grade': 'G7'},
        createdAt: '2026-01-01T00:00:00',
      );

      final json = r.toJson();
      expect(json['id'], 'rpt-2');
      expect(json['title'], '学生统计');
      expect(json['user_id'], 'u-2');
      expect(json['report_type'], 'student');
      expect(json['dimensions'], ['school']);
      expect(json['date_range'], {'start': '2026-01-01'});
      expect(json['chart_type'], 'line');
      expect(json['filters'], {'grade': 'G7'});
      expect(json['created_at'], '2026-01-01T00:00:00');
      expect(json['updated_at'], isNull);

      final back = CustomReport.fromJson(json);
      expect(back.id, r.id);
      expect(back.title, r.title);
      expect(back.reportType, r.reportType);
      expect(back.dimensions, r.dimensions);
      expect(back.chartType, r.chartType);
    });

    test('reportTypeDisplayName 应正确映射', () {
      expect(CustomReport(id: '', title: '', reportType: 'person', createdAt: '').reportTypeDisplayName, '人口统计');
      expect(CustomReport(id: '', title: '', reportType: 'student', createdAt: '').reportTypeDisplayName, '学生统计');
      expect(CustomReport(id: '', title: '', reportType: 'subsidy', createdAt: '').reportTypeDisplayName, '补贴统计');
      expect(CustomReport(id: '', title: '', reportType: 'unknown', createdAt: '').reportTypeDisplayName, '未知类型');
    });

    test('chartTypeDisplayName 应正确映射', () {
      expect(CustomReport(id: '', title: '', reportType: '', chartType: 'bar', createdAt: '').chartTypeDisplayName, '柱状图');
      expect(CustomReport(id: '', title: '', reportType: '', chartType: 'line', createdAt: '').chartTypeDisplayName, '折线图');
      expect(CustomReport(id: '', title: '', reportType: '', chartType: 'pie', createdAt: '').chartTypeDisplayName, '饼图');
      expect(CustomReport(id: '', title: '', reportType: '', chartType: 'radar', createdAt: '').chartTypeDisplayName, '雷达图');
      expect(CustomReport(id: '', title: '', reportType: '', chartType: 'other', createdAt: '').chartTypeDisplayName, '未知类型');
    });
  });
}
