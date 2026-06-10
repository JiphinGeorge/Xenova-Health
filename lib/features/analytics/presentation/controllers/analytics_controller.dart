import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/analytics_report_model.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/services/analytics_aggregation_service.dart';

enum AnalyticsRange {
  weekly,
  monthly,
  quarterly
}

class AnalyticsState {
  final AnalyticsRange selectedRange;
  final AsyncValue<AnalyticsReportModel?> report;

  AnalyticsState({
    required this.selectedRange,
    required this.report,
  });

  AnalyticsState copyWith({
    AnalyticsRange? selectedRange,
    AsyncValue<AnalyticsReportModel?>? report,
  }) {
    return AnalyticsState(
      selectedRange: selectedRange ?? this.selectedRange,
      report: report ?? this.report,
    );
  }
}

class AnalyticsController extends StateNotifier<AnalyticsState> {
  AnalyticsController(this._ref, this._repo, this._service)
      : super(AnalyticsState(
          selectedRange: AnalyticsRange.weekly,
          report: const AsyncValue.loading(),
        )) {
    _loadReport();
  }

  final Ref _ref;
  final AnalyticsRepository _repo;
  final AnalyticsAggregationService _service;

  void setRange(AnalyticsRange range) {
    if (state.selectedRange == range) return;
    state = state.copyWith(selectedRange: range, report: const AsyncValue.loading());
    _loadReport();
  }

  Future<void> _loadReport() async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null) {
      state = state.copyWith(report: const AsyncValue.data(null));
      return;
    }

    try {
      final now = DateTime.now();
      DateTime startDate;
      String reportId;

      switch (state.selectedRange) {
        case AnalyticsRange.weekly:
          startDate = now.subtract(const Duration(days: 7));
          // Use ISO week logic simplified for MVP
          final weekNum = (now.day / 7).ceil(); 
          reportId = 'weekly_${now.year}_$weekNum';
          break;
        case AnalyticsRange.monthly:
          startDate = DateTime(now.year, now.month - 1, now.day);
          reportId = 'monthly_${now.year}_${now.month}';
          break;
        case AnalyticsRange.quarterly:
          startDate = DateTime(now.year, now.month - 3, now.day);
          final q = (now.month / 3).ceil();
          reportId = 'quarterly_${now.year}_q$q';
          break;
      }

      // Check cache first
      final cachedReport = await _repo.getReport(user.uid, reportId);
      
      // If we have a cached report and it was generated recently (e.g. today), use it
      if (cachedReport != null && 
          cachedReport.generatedAt.difference(now).inHours.abs() < 12) {
        state = state.copyWith(report: AsyncValue.data(cachedReport));
        return;
      }

      // Otherwise generate new report
      final report = await _service.generateReport(
        userId: user.uid,
        startDate: startDate,
        endDate: now,
        reportId: reportId,
      );

      // Save to repo
      await _repo.saveReport(report);

      state = state.copyWith(report: AsyncValue.data(report));
    } catch (e, st) {
      state = state.copyWith(report: AsyncValue.error(e, st));
    }
  }

  /// Forces a regeneration, for example when a new meal or weight is logged
  Future<void> forceRegenerate() async {
    state = state.copyWith(report: const AsyncValue.loading());
    await _loadReport();
  }
}

final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
  return AnalyticsController(
    ref,
    ref.watch(analyticsRepositoryProvider),
    ref.watch(analyticsAggregationServiceProvider),
  );
});
