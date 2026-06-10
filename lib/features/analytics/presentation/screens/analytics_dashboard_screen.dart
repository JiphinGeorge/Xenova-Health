import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../controllers/analytics_controller.dart';
import '../../domain/models/analytics_report_model.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsControllerProvider);
    final notifier = ref.read(analyticsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.forceRegenerate(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Range Selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SegmentedButton<AnalyticsRange>(
              segments: const [
                ButtonSegment(value: AnalyticsRange.weekly, label: Text('Weekly')),
                ButtonSegment(value: AnalyticsRange.monthly, label: Text('Monthly')),
                ButtonSegment(value: AnalyticsRange.quarterly, label: Text('Quarterly')),
              ],
              selected: {state.selectedRange},
              onSelectionChanged: (set) => notifier.setRange(set.first),
            ),
          ),
          
          Expanded(
            child: state.report.when(
              data: (report) {
                if (report == null) return const Center(child: Text('No data found.'));
                return _buildDashboardContent(context, report);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, AnalyticsReportModel report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Overview
          _SectionTitle('Overview'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _OverviewCard(
                title: 'Consistency Score',
                value: '${report.consistencyScore.toStringAsFixed(0)}',
                color: Colors.blue,
              ),
              _OverviewCard(
                title: 'Goal Progress',
                value: '${(report.goalProgressPercentage * 100).toStringAsFixed(0)}%',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXxl),

          // 2. Weight Analytics
          _SectionTitle('Weight Analytics'),
          _StatRow('Weight Change', '${report.weightChange > 0 ? '+' : ''}${report.weightChange.toStringAsFixed(1)} kg'),
          _StatRow('Avg. Weekly Change', '${report.averageWeeklyWeightChange > 0 ? '+' : ''}${report.averageWeeklyWeightChange.toStringAsFixed(2)} kg/wk'),
          const SizedBox(height: AppDimensions.spacingLg),
          // Weight Line Chart placeholder (would use real trend array in production)
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 80), FlSpot(1, 79), FlSpot(2, 78.5), FlSpot(3, 78)],
                    isCurved: true,
                    color: Colors.deepPurpleAccent,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxl),

          // 3. Nutrition Analytics
          _SectionTitle('Nutrition Analytics'),
          _StatRow('Avg. Daily Calories', '${report.averageDailyCalories.toStringAsFixed(0)} kcal'),
          _StatRow('Avg. Daily Protein', '${report.averageDailyProtein.toStringAsFixed(0)} g'),
          _StatRow('Avg. Daily Water', '${report.averageDailyWater} ml'),
          const SizedBox(height: AppDimensions.spacingLg),
          // Nutrition Bar Chart placeholder
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 2000, color: Colors.blue)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 1800, color: Colors.blue)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2200, color: Colors.blue)]),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxl),

          // 4. Fasting Analytics
          _SectionTitle('Fasting Analytics'),
          _StatRow('Avg. Fast Duration', '${report.averageFastDuration.toStringAsFixed(1)} hrs'),
          _StatRow('Completion Rate', '${(report.fastCompletionRate * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: AppDimensions.spacingXxl),
          
          Text('Generated: ${report.generatedAt.toString().split('.')[0]}', 
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.title, required this.value, required this.color});
  
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
