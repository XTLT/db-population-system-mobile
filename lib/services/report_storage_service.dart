import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_report.dart';


class ReportStorageService {
  static const String _reportsKey = 'saved_reports';
  static const String _reportsDir = 'reports';

  
  
  
  
  
  
  static Future<String> saveReport(CustomReport report, String pdfPath) async {
    
    final appDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${appDir.path}/$_reportsDir');

    
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final reportId = 'saved_${report.id}_$timestamp';
    final savedPdfPath = '${reportsDir.path}/$reportId.pdf';

    
    final pdfFile = File(pdfPath);
    if (await pdfFile.exists()) {
      await pdfFile.copy(savedPdfPath);
    }

    
    final metadata = {
      'id': reportId,
      'report_id': report.id,
      'title': report.title,
      'report_type': report.reportType,
      'chart_type': report.chartType,
      'pdf_path': savedPdfPath,
      'saved_at': DateTime.now().toIso8601String(),
    };

    await _saveReportMetadata(metadata);

    return reportId;
  }

  
  
  
  static Future<List<Map<String, dynamic>>> getSavedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString(_reportsKey);

    if (reportsJson == null) {
      return [];
    }

    try {
      final reports = json.decode(reportsJson) as List;
      final validReports = <Map<String, dynamic>>[];

      for (final report in reports) {
        final metadata = report as Map<String, dynamic>;
        final pdfPath = metadata['pdf_path'] as String?;

        
        if (pdfPath != null && await File(pdfPath).exists()) {
          validReports.add(metadata);
        }
      }

      
      if (validReports.length != reports.length) {
        await _updateSavedReports(validReports);
      }

      return validReports;
    } catch (e) {
      return [];
    }
  }

  
  
  
  
  
  static Future<String?> getReportPdf(String reportId) async {
    final reports = await getSavedReports();

    for (final report in reports) {
      if (report['id'] == reportId) {
        final pdfPath = report['pdf_path'] as String?;
        if (pdfPath != null && await File(pdfPath).exists()) {
          return pdfPath;
        }
      }
    }

    return null;
  }

  
  
  
  static Future<bool> deleteReport(String reportId) async {
    final reports = await getSavedReports();
    final reportIndex = reports.indexWhere((r) => r['id'] == reportId);

    if (reportIndex == -1) {
      return false;
    }

    final report = reports[reportIndex];
    final pdfPath = report['pdf_path'] as String?;

    
    if (pdfPath != null) {
      final file = File(pdfPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    
    reports.removeAt(reportIndex);
    await _updateSavedReports(reports);

    return true;
  }

  
  static Future<void> clearAllReports() async {
    final reports = await getSavedReports();

    
    for (final report in reports) {
      final pdfPath = report['pdf_path'] as String?;
      if (pdfPath != null) {
        final file = File(pdfPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportsKey);
  }

  
  static Future<Map<String, dynamic>> getStorageStats() async {
    final reports = await getSavedReports();
    int totalSize = 0;

    for (final report in reports) {
      final pdfPath = report['pdf_path'] as String?;
      if (pdfPath != null) {
        final file = File(pdfPath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }
    }

    return {
      'count': reports.length,
      'total_size': totalSize,
      'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  
  static Future<void> _saveReportMetadata(Map<String, dynamic> metadata) async {
    final reports = await getSavedReports();
    reports.insert(0, metadata); 
    await _updateSavedReports(reports);
  }

  
  static Future<void> _updateSavedReports(List<Map<String, dynamic>> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reportsKey, json.encode(reports));
  }
}
