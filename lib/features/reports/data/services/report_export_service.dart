import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../analytics/data/repositories/analytics_repository.dart';
import '../../../dashboard/data/repositories/dashboard_stats_repository.dart';
import '../../../fasting/data/repositories/fasting_repository.dart';
import '../../../nutrition/data/repositories/nutrition_repository.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../../weight/data/repositories/weight_repository.dart';
import '../../ai_coach/data/services/gemini_service.dart';
import '../../ai_coach/domain/models/ai_context_model.dart';
import 'csv_generator.dart';
import 'pdf_generator.dart';

class ReportExportService {
  ReportExportService(
    this._profileRepo,
    this._statsRepo,
    this._weightRepo,
    this._nutritionRepo,
    this._fastingRepo,
    this._analyticsRepo,
    this._geminiService,
  );

  final UserProfileRepository _profileRepo;
  final DashboardStatsRepository _statsRepo;
  final WeightRepository _weightRepo;
  final NutritionRepository _nutritionRepo;
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
      await Share.shareXFiles([XFile(filePath)], text: 'My Xenova Health Report');
    }
  }

  Future<String?> _generateCsvFile(String userId, String dataType) async {
    String csvData = '';
    String filename = 'export.csv';

    if (dataType == 'Weight History') {
      final entries = await _weightRepo.getEntriesOnce(userId);
      csvData = _csvGenerator.generateWeightCsv(entries);
      filename = 'weight_history.csv';
    } else if (dataType == 'Nutrition Logs') {
      // Basic fetch
      // For MVP we just use empty array if no generic getAll method exists, 
      // or we can fetch last 30 days
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
    final profile = await _profileRepo.getProfile(userId);
    final stats = await _statsRepo.getStats(userId);
    final latestReport = await _analyticsRepo.getLatestReport(userId);
    
    if (profile == null || stats == null) return null;

    final recentSnapshot = latestReport?.snapshot;

    // Build AI Summary if we have a snapshot
    String? aiSummary;
    if (recentSnapshot != null) {
      final contextModel = AIContextModel(
        contextVersion: '1.0',
        generatedAt: DateTime.now(),
        ageRange: 30, // Defaulted for privacy
        gender: profile.gender,
        heightCm: profile.heightCm,
        goalType: profile.goalType,
        healthScore: stats.healthScore?.overallHealthScore ?? 0.0,
        consistencyScore: recentSnapshot.consistencyScore,
        weightTrend: recentSnapshot.weightTrend,
        nutritionMetrics: {},
        fastingMetrics: {},
        goalProgress: stats.goalProgress ?? 0.0,
        proteinGoalMet: recentSnapshot.averageProtein > 100,
        waterGoalMet: recentSnapshot.averageWater > 2000,
        calorieTargetMet: true,
      );
      aiSummary = await _geminiService.generateWeeklySummary(contextModel);
    }

    final pdfBytes = await _pdfGenerator.generateFullHealthReport(
      userProfile: profile,
      dashboardStats: stats,
      recentSnapshot: recentSnapshot,
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
    ref.watch(userProfileRepositoryProvider),
    ref.watch(dashboardStatsRepositoryProvider),
    ref.watch(weightRepositoryProvider),
    ref.watch(nutritionRepositoryProvider),
    ref.watch(fastingRepositoryProvider),
    ref.watch(analyticsRepositoryProvider),
    ref.watch(geminiServiceProvider),
  );
});
