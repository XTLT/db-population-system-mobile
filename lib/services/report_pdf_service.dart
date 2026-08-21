import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/custom_report.dart';


class ReportPdfService {
  
  
  
  
  
  
  
  static Future<String> generateReportPdf(
    CustomReport report,
    Map<String, dynamic> data, {
    Uint8List? chartBytes,
  }) async {
    final pdf = pw.Document();

    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            
            pw.Header(
              level: 0,
              child: pw.Text(
                report.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            
            _buildReportInfo(report),
            pw.SizedBox(height: 24),

            
            if (data['total_count'] != null) ...[
              pw.Text(
                '统计概要',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildSummarySection(data),
              pw.SizedBox(height: 24),
            ],

            
            if (chartBytes != null) ...[
              pw.Text(
                '数据图表',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(chartBytes),
                  width: 450,
                  height: 280,
                ),
              ),
              pw.SizedBox(height: 24),
            ],

            
            if (data['dimension_data'] != null) ...[
              pw.Text(
                '数据详情',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildDataTables(data),
            ],
          ];
        },
      ),
    );

    
    final tempDir = await getTemporaryDirectory();
    final fileName = 'report_${report.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  
  static pw.Widget _buildReportInfo(CustomReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('报表类型', report.reportTypeDisplayName),
          _buildInfoRow('图表类型', report.chartTypeDisplayName),
          if (report.dimensions.isNotEmpty)
            _buildInfoRow('统计维度', report.dimensions.join('、')),
          if (report.dateRange.isNotEmpty)
            _buildInfoRow(
              '时间范围',
              '${report.dateRange['start'] ?? ''} 至 ${report.dateRange['end'] ?? ''}',
            ),
          _buildInfoRow('创建时间', _formatDateTime(report.createdAt)),
          if (report.updatedAt != null)
            _buildInfoRow('更新时间', _formatDateTime(report.updatedAt!)),
          _buildInfoRow('生成时间', _formatDateTime(DateTime.now().toIso8601String())),
        ],
      ),
    );
  }

  
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label：',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  
  static pw.Widget _buildSummarySection(Map<String, dynamic> data) {
    final totalCount = data['total_count'] ?? 0;
    final dimensionData = data['dimension_data'] as Map<String, dynamic>?;

    final summaryItems = <pw.Widget>[];

    summaryItems.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('总计记录数：', style: const pw.TextStyle(fontSize: 12)),
            pw.Text(
              totalCount.toString(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ],
        ),
      ),
    );

    if (dimensionData != null && dimensionData.isNotEmpty) {
      final firstDimension = dimensionData.entries.first;
      final dimData = firstDimension.value as Map<String, dynamic>;
      final topEntries = dimData.entries.toList()
        ..sort((a, b) => (b.value as num).compareTo(a.value as num));

      if (topEntries.isNotEmpty) {
        final topItem = topEntries.first;
        summaryItems.add(pw.SizedBox(height: 8));
        summaryItems.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('最大分类：', style: const pw.TextStyle(fontSize: 12)),
                pw.Text(
                  '${topItem.key} (${topItem.value})',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return pw.Column(children: summaryItems);
  }

  
  static pw.Widget _buildDataTables(Map<String, dynamic> data) {
    final totalCount = data['total_count'] ?? 0;
    final dimensionData = data['dimension_data'] as Map<String, dynamic>?;

    if (dimensionData == null || dimensionData.isEmpty) {
      return pw.Text('暂无数据');
    }

    final tables = <pw.Widget>[];

    for (final entry in dimensionData.entries) {
      final dimName = entry.key;
      final dimData = entry.value as Map<String, dynamic>;

      tables.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                dimName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildTableCell('分类', isHeader: true),
                      _buildTableCell('数量', isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('占比', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  ...dimData.entries.map((e) {
                    final value = (e.value as num).toDouble();
                    final percentage = totalCount > 0
                        ? (value / totalCount * 100).toStringAsFixed(1)
                        : '0.0';
                    return pw.TableRow(
                      children: [
                        _buildTableCell(e.key),
                        _buildTableCell(e.value.toString(), align: pw.TextAlign.right),
                        _buildTableCell('$percentage%', align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(children: tables);
  }

  
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
        textAlign: align,
      ),
    );
  }

  
  static String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
