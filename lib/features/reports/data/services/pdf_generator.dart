import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../analytics/domain/models/analytics_snapshot_model.dart';
import '../../../dashboard/domain/models/dashboard_stats_model.dart';
import '../../../profile/domain/models/user_profile_model.dart';

class PdfGenerator {
  /// Generates a full health report PDF.
  Future<Uint8List> generateFullHealthReport({
    required UserProfileModel userProfile,
    required DashboardStatsModel dashboardStats,
    AnalyticsSnapshot? recentSnapshot,
    String? aiSummary,
  }) async {
    final pdf = pw.Document();

    final titleFont = pw.Font.helveticaBold();
    final bodyFont = pw.Font.helvetica();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'XENOVA HEALTH',
                  style: pw.TextStyle(font: titleFont, fontSize: 24, color: PdfColors.blue800),
                ),
                pw.Text(
                  'Health Report',
                  style: pw.TextStyle(font: bodyFont, fontSize: 16, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // User Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Generated For: ${userProfile.displayName ?? "User"}', style: pw.TextStyle(font: titleFont)),
                    pw.Text('Date: ${DateTime.now().toIso8601String().split('T').first}', style: pw.TextStyle(font: bodyFont)),
                    pw.Text('Goal: ${userProfile.goalType}', style: pw.TextStyle(font: bodyFont)),
                  ],
                ),
                if (dashboardStats.healthScore != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Health Score', style: pw.TextStyle(font: bodyFont, fontSize: 12)),
                        pw.Text(
                          '${dashboardStats.healthScore!.overallHealthScore.toInt()}/100',
                          style: pw.TextStyle(font: titleFont, fontSize: 24, color: PdfColors.blue800),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Summary Section
            pw.Text('Health Summary', style: pw.TextStyle(font: titleFont, fontSize: 18)),
            pw.SizedBox(height: 10),
            if (aiSummary != null && aiSummary.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(aiSummary, style: pw.TextStyle(font: bodyFont, fontSize: 12)),
              )
            else
              pw.Text('No AI Summary generated for this period.', style: pw.TextStyle(font: bodyFont, color: PdfColors.grey)),
            
            pw.SizedBox(height: 30),

            // Placeholder for Charts
            // Since complex charts require rendering custom canvas paths in pdf,
            // we create a structured visual representation using data tables & simple bars.
            pw.Text('Analytics Data', style: pw.TextStyle(font: titleFont, fontSize: 18)),
            pw.SizedBox(height: 10),
            
            _buildDataCard('Current Weight', '${dashboardStats.currentWeight ?? "-"} kg', titleFont, bodyFont),
            _buildDataCard('Goal Progress', '${((dashboardStats.goalProgress ?? 0) * 100).toStringAsFixed(1)}%', titleFont, bodyFont),
            
            if (recentSnapshot != null) ...[
              pw.SizedBox(height: 20),
              pw.Text('Recent Period Metrics', style: pw.TextStyle(font: titleFont, fontSize: 14)),
              pw.SizedBox(height: 10),
              _buildDataCard('Consistency Score', '${recentSnapshot.consistencyScore.toInt()}/100', titleFont, bodyFont),
              _buildDataCard('Fasting Rate', '${(recentSnapshot.fastingCompletionRate * 100).toStringAsFixed(1)}%', titleFont, bodyFont),
            ],

            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text(
                'This report is generated by Xenova Health AI. It is not medical advice.',
                style: pw.TextStyle(font: bodyFont, fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildDataCard(String label, String value, pw.Font titleFont, pw.Font bodyFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: bodyFont)),
          pw.Text(value, style: pw.TextStyle(font: titleFont)),
        ],
      ),
    );
  }
}
