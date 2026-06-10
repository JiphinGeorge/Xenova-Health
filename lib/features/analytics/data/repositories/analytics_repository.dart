import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/analytics_report_model.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Saves a generated analytics report.
  Future<void> saveReport(AnalyticsReportModel report) async {
    await _firestore
        .doc('users/${report.userId}/analytics/${report.id}')
        .set(report.toJson(), SetOptions(merge: true));
  }

  /// Gets an analytics report by ID.
  Future<AnalyticsReportModel?> getReport(String userId, String reportId) async {
    final doc = await _firestore.doc('users/$userId/analytics/$reportId').get();
    if (doc.exists && doc.data() != null) {
      return AnalyticsReportModel.fromJson(doc.data()!);
    }
    return null;
  }

  /// Gets the latest analytics report.
  Future<AnalyticsReportModel?> getLatestReport(String userId) async {
    final query = await _firestore
        .collection('users/$userId/analytics')
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return AnalyticsReportModel.fromJson(query.docs.first.data());
    }
    return null;
  }

  /// Exports an analytics report to a specific format.
  /// Currently a placeholder abstraction for future implementation (Phase 9+).
  /// Supported formats could include 'pdf', 'csv', 'excel'.
  Future<String> exportAnalyticsReport(String userId, String reportId, String format) async {
    // TODO: Implement export logic (generate file locally or via Cloud Function)
    return 'file:///path/to/exported/report.$format';
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(FirebaseFirestore.instance);
});
