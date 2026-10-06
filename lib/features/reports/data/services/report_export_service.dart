import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../analytics/data/repositories/analytics_repository.dart';
import '../../../analytics/domain/models/analytics_report_model.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/data/repositories/dashboard_stats_repository.dart';
import '../../../dashboard/domain/models/dashboard_stats_model.dart';
import '../../../dashboard/presentation/controllers/health_score_provider.dart';
import '../../../fasting/data/repositories/fasting_repository.dart';
import '../../../fasting/domain/models/fasting_session_model.dart';
import '../../../fasting/presentation/controllers/fasting_controller.dart';
import '../../../nutrition/domain/models/daily_nutrition_summary_model.dart';
import '../../../nutrition/domain/models/meal_log_model.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../../weight/data/repositories/weight_repository.dart';
import '../../../weight/domain/models/weight_entry_model.dart';
import '../../../weight/presentation/controllers/weight_controller.dart';
import '../../../ai_coach/data/services/openai_service.dart';
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
    this._analyticsRepo, [
    this._openAIService,
  ]);

  final Ref _ref;
  final DashboardStatsRepository _statsRepo;
  final WeightRepository _weightRepo;
  final FastingRepository _fastingRepo;
  final AnalyticsRepository _analyticsRepo;
  final OpenAIService? _openAIService;

  final CsvGenerator _csvGenerator = CsvGenerator();
  final PdfGenerator _pdfGenerator = PdfGenerator();

  /// Exports data and opens the native share sheet.
  Future<void> exportAndShare(
    String userId,
    String dataType,
    String format,
  ) async {
    String? filePath;

    if (format == 'CSV') {
      filePath = await _generateCsvFile(userId, dataType);
    } else if (format == 'PDF') {
      filePath = await _generatePdfFile(userId);
    } else {
      throw Exception('Unsupported export format: $format');
    }

    if (filePath == null) {
      throw Exception('Failed to generate $format export file for $dataType.');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Export file could not be found on device.');
    }

    // Share via share_plus
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'My Xenova Health $dataType ($format)',
      subject: 'Xenova Health - $dataType',
    );
  }

  Future<String?> _generateCsvFile(String userId, String dataType) async {
    String csvData = '';
    String filename = 'export.csv';

    if (dataType == 'Weight History') {
      List<WeightEntryModel> entries = [];
      try {
        entries = await _weightRepo.getWeightEntries(userId);
      } catch (_) {}

      // Fallback to active state
      if (entries.isEmpty) {
        entries = _ref.read(weightEntriesStreamProvider).value ?? [];
      }
      csvData = _csvGenerator.generateWeightCsv(entries);
      filename = 'weight_history_${DateTime.now().millisecondsSinceEpoch}.csv';
    } else if (dataType == 'Nutrition Logs') {
      // 1. Fetch individual logged meals from Hive meal_box
      final meals = <MealLogModel>[];
      try {
        if (Hive.isBoxOpen(AppConstants.mealBox)) {
          final box = Hive.box<dynamic>(AppConstants.mealBox);
          for (final key in box.keys) {
            final val = box.get(key);
            if (val != null) {
              final Map<String, dynamic> map = val is String
                  ? jsonDecode(val) as Map<String, dynamic>
                  : Map<String, dynamic>.from(val as Map);
              meals.add(MealLogModel.fromJson(map));
            }
          }
        }
      } catch (_) {}

      if (meals.isNotEmpty) {
        meals.sort((a, b) => b.date.compareTo(a.date));
        csvData = _csvGenerator.generateMealLogsCsv(meals);
      } else {
        // Fallback to daily summaries
        final summaries = <DailyNutritionSummaryModel>[];
        try {
          if (Hive.isBoxOpen(AppConstants.dailySummaryBox)) {
            final box = Hive.box<dynamic>(AppConstants.dailySummaryBox);
            for (final key in box.keys) {
              final val = box.get(key);
              if (val != null) {
                final Map<String, dynamic> map = val is String
                    ? jsonDecode(val) as Map<String, dynamic>
                    : Map<String, dynamic>.from(val as Map);
                summaries.add(DailyNutritionSummaryModel.fromJson(map));
              }
            }
          }
        } catch (_) {}

        final liveSummary =
            _ref.read(dailyNutritionSummaryStreamProvider).value;
        if (liveSummary != null &&
            !summaries.any((s) => s.dateString == liveSummary.dateString)) {
          summaries.add(liveSummary);
        }

        csvData = _csvGenerator.generateNutritionCsv(summaries);
      }
      filename =
          'nutrition_history_${DateTime.now().millisecondsSinceEpoch}.csv';
    } else if (dataType == 'Fasting Logs') {
      List<FastingSessionModel> sessions = [];
      try {
        sessions = await _fastingRepo.getSessionsOnce(userId);
      } catch (_) {}

      if (sessions.isEmpty) {
        sessions = _ref.read(fastingHistoryProvider).value ?? [];
      }
      csvData = _csvGenerator.generateFastingCsv(sessions);
      filename = 'fasting_history_${DateTime.now().millisecondsSinceEpoch}.csv';
    } else {
      // Full export / fallback
      final entries = _ref.read(weightEntriesStreamProvider).value ?? [];
      csvData = _csvGenerator.generateWeightCsv(entries);
      filename = 'health_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    }

    if (csvData.isEmpty) {
      throw Exception('No data records available to export for $dataType.');
    }

    // Save to cache/temp directory for universal file sharing
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvData);
    return file.path;
  }

  Future<String?> _generatePdfFile(String userId) async {
    final profile = _ref.read(authControllerProvider).value;
    DashboardStatsModel? stats;
    try {
      stats = await _statsRepo.getStats(userId);
    } catch (_) {}

    AnalyticsReportModel? latestReport;
    try {
      latestReport = await _analyticsRepo.getLatestReport(userId);
    } catch (_) {}

    final computedHealthScore = _ref.read(healthScoreProvider);

    // Provide robust fallback profile if user is guest or auth is offline
    final effectiveProfile = profile ??
        UserModel(
          uid: userId,
          email: 'user@xenova.health',
          createdAt: DateTime.now(),
          displayName: 'Xenova Health User',
          currentWeightKg: 70.0,
        );

    final effectiveStats = (stats ??
            DashboardStatsModel(
              currentWeight: effectiveProfile.currentWeightKg ?? 70.0,
              weightLost: 0.0,
              goalProgress: 0.0,
              latestBMI: 22.0,
              latestTDEE: 2000.0,
              lastUpdated: DateTime.now(),
            ))
        .copyWith(
      healthScore: stats?.healthScore ?? computedHealthScore,
    );

    // AI summary or clinical local summary
    String? aiSummary;
    if (_openAIService != null && _openAIService!.isConfigured) {
      try {
        final contextModel = AIContextModel(
          contextVersion: '1.0',
          generatedAt: DateTime.now(),
          ageRange: effectiveProfile.age,
          gender: effectiveProfile.gender?.name,
          heightCm: effectiveProfile.heightCm,
          goalType: effectiveProfile.primaryGoal?.name,
          healthScore: effectiveStats.healthScore?.overallHealthScore ??
              computedHealthScore.overallHealthScore,
          consistencyScore: latestReport?.consistencyScore ?? 80.0,
          weightTrend: latestReport?.averageWeeklyWeightChange ?? 0.0,
          nutritionMetrics: const {},
          fastingMetrics: const {},
          goalProgress: effectiveStats.goalProgress,
          proteinGoalMet: (latestReport?.averageDailyProtein ?? 120) > 100,
          waterGoalMet: (latestReport?.averageDailyWater ?? 2200) > 2000,
          calorieTargetMet: true,
        );
        aiSummary = await _openAIService!.generateWeeklySummary(contextModel);
        if (aiSummary != null && aiSummary.isNotEmpty) {
          _ref.read(achievementEngineProvider).processAiCoachEvent(true);
        }
      } catch (_) {}
    }

    if (aiSummary == null || aiSummary.isEmpty) {
      final scoreVal =
          effectiveStats.healthScore?.overallHealthScore.toInt() ?? 72;
      aiSummary = 'Health Score: $scoreVal/100. '
          'Your personalized wellness tracking reflects positive momentum across core lifestyle pillars. '
          'Continue adhering to balanced daily macronutrient intake, proper hydration, and your intermittent fasting routine.';
    }

    final pdfBytes = await _pdfGenerator.generateFullHealthReport(
      userProfile: effectiveProfile,
      dashboardStats: effectiveStats,
      recentSnapshot: latestReport,
      aiSummary: aiSummary,
    );

    // Save to temp directory for reliable cross-app sharing
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/health_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
}

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  OpenAIService? openAIService;
  try {
    openAIService = ref.watch(openAIServiceProvider);
  } catch (_) {}

  return ReportExportService(
    ref,
    ref.watch(dashboardStatsRepositoryProvider),
    ref.watch(weightRepositoryProvider),
    ref.watch(fastingRepositoryProvider),
    ref.watch(analyticsRepositoryProvider),
    openAIService,
  );
});
