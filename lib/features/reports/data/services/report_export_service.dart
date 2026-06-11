import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../analytics/data/repositories/analytics_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

import '../../../dashboard/data/repositories/dashboard_stats_repository.dart';
import '../../../fasting/data/repositories/fasting_repository.dart';
import '../../../nutrition/data/repositories/daily_nutrition_repository.dart';
import '../../../weight/data/repositories/weight_repository.dart';
import '../../../ai_coach/data/services/gemini_service.dart';
import '../../../ai_coach/domain/models/ai_context_model.dart';
import '../../../gamification/application/services/achievement_engine_service.dart';
import 'csv_generator.dart';
import 'pdf_generator.dart';

class ReportExportService {
  ReportExportService(
    this._ref,
    this._statsRepo,
    this._weightRepo,
    this._fastingRepo,
    this._analyticsRepo,
    this._geminiService,
  );

  final Ref _ref;
  final DashboardStatsRepository _statsRepo;
  final WeightRepository _weightRepo;
  final FastingRepository _fastingRepo;
  final AnalyticsRepository _analyticsRepo;
  final GeminiService _geminiService;

  final CsvGenerator _csvGenerator = CsvGenerator();
  final PdfGenerator _pdfGenerator = PdfGenerator();

  /// Exports data and opens the native share sheet.
  Future<void> exportAndShare(String userId, String dataType, String format) async {
    String? filePath;

    if (format == 'CSV') {
      filePath = await _generateCsvFile(userId, dataType);
    } else if (format == 'PDF') {
      filePath = await _generatePdfFile(userId);
    }

    if (filePath != null) {
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(filePath)], text: 'My Xenova Health Report');
    }
  }

  Future<String?> _generateCsvFile(String userId, String dataType) async {
    String csvData = '';
    String filename = 'export.csv';

    if (dataType == 'Weight History') {
      final entries = await _weightRepo.getWeightEntries(userId);
      csvData = _csvGenerator.generateWeightCsv(entries);
      filename = 'weight_history.csv';
    } else if (dataType == 'Nutrition Logs') {
      // For MVP we just use empty array, or if there's a getter, use it.
      csvData = _csvGenerator.generateNutritionCsv([]); 
      filename = 'nutrition_history.csv';
    } else if (dataType == 'Fasting Logs') {
      final sessions = await _fastingRepo.getSessionsOnce(userId);
      csvData = _csvGenerator.generateFastingCsv(sessions);
      filename = 'fasting_history.csv';
    }

    if (csvData.isEmpty) return null;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvData);
    return file.path;
  }

  Future<String?> _generatePdfFile(String userId) async {
    final profile = _ref.read(authControllerProvider).value;
    final stats = await _statsRepo.getStats(userId);
    final latestReport = await _analyticsRepo.getLatestReport(userId);
    
    if (profile == null || stats == null) return null;

    // Build AI Summary if we have a report
    String? aiSummary;
    if (latestReport != null) {
      final contextModel = AIContextModel(
        contextVersion: '1.0',
        generatedAt: DateTime.now(),
        ageRange: profile.age,
        gender: profile.gender?.name,
        heightCm: profile.heightCm,
        goalType: profile.primaryGoal?.name,
        healthScore: stats.healthScore?.overallHealthScore ?? 0.0,
        consistencyScore: latestReport.consistencyScore,
        weightTrend: latestReport.averageWeeklyWeightChange,
        nutritionMetrics: const {},
        fastingMetrics: const {},
        goalProgress: stats.goalProgress,
        proteinGoalMet: latestReport.averageDailyProtein > 100,
        waterGoalMet: latestReport.averageDailyWater > 2000,
        calorieTargetMet: true,
      );
      aiSummary = await _geminiService.generateWeeklySummary(contextModel);
      if (aiSummary != null && aiSummary.isNotEmpty) {
        // Gamification Hook
        _ref.read(achievementEngineProvider).processAiCoachEvent(true);
      }
    }

    final pdfBytes = await _pdfGenerator.generateFullHealthReport(
      userProfile: profile,
      dashboardStats: stats,
      recentSnapshot: latestReport,
      aiSummary: aiSummary,
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/health_report.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
}

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return ReportExportService(
    ref,
    ref.watch(dashboardStatsRepositoryProvider),
    ref.watch(weightRepositoryProvider),
    ref.watch(fastingRepositoryProvider),
    ref.watch(analyticsRepositoryProvider),
    ref.watch(geminiServiceProvider),
  );
});
