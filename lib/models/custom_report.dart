
class CustomReport {
  final String id;
  final String title;
  final String? userId;
  final String reportType;
  final List<String> dimensions;
  final Map<String, String> dateRange;
  final String chartType;
  final Map<String, dynamic> filters;
  final String createdAt;
  final String? updatedAt;
  
  CustomReport({
    required this.id,
    required this.title,
    this.userId,
    required this.reportType,
    this.dimensions = const [],
    this.dateRange = const {},
    this.chartType = 'bar',
    this.filters = const {},
    required this.createdAt,
    this.updatedAt,
  });
  
  factory CustomReport.fromJson(Map<String, dynamic> json) {
    return CustomReport(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      userId: json['user_id'],
      reportType: json['report_type'] ?? '',
      dimensions: json['dimensions'] != null 
        ? List<String>.from(json['dimensions']) 
        : [],
      dateRange: json['date_range'] != null 
        ? Map<String, String>.from(json['date_range']) 
        : {},
      chartType: json['chart_type'] ?? 'bar',
      filters: json['filters'] ?? {},
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'user_id': userId,
      'report_type': reportType,
      'dimensions': dimensions,
      'date_range': dateRange,
      'chart_type': chartType,
      'filters': filters,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  
  String get reportTypeDisplayName {
    switch (reportType) {
      case 'person':
        return '人口统计';
      case 'student':
        return '学生统计';
      case 'subsidy':
        return '补贴统计';
      default:
        return '未知类型';
    }
  }
  
  
  String get chartTypeDisplayName {
    switch (chartType) {
      case 'bar':
        return '柱状图';
      case 'line':
        return '折线图';
      case 'pie':
        return '饼图';
      case 'radar':
        return '雷达图';
      default:
        return '未知类型';
    }
  }
}
