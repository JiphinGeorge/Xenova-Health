import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';

/// A styled card widget for displaying fl_chart charts.
///
/// Provides consistent padding, title, subtitle, and action button
/// for all chart visualizations in the app.
class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.chart,
    super.key,
    this.subtitle,
    this.trailing,
    this.height = AppDimensions.chartHeight,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget chart;
  final double height;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: isDark ? Border.all(color: AppColors.dividerDark) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppDimensions.spacingXxs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            SizedBox(height: height, child: chart),
          ],
        ),
      ),
    );
  }
}

/// Helper to create consistent line chart data for weight trends.
LineChartData buildWeightTrendChart({
  required List<FlSpot> spots,
  required BuildContext context,
  double? minY,
  double? maxY,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return LineChartData(
    gridData: FlGridData(
      drawVerticalLine: false,
      horizontalInterval: 1,
      getDrawingHorizontalLine: (value) => FlLine(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        strokeWidth: 0.5,
      ),
    ),
    titlesData: const FlTitlesData(
      rightTitles: AxisTitles(),
      topTitles: AxisTitles(),
    ),
    borderData: FlBorderData(show: false),
    lineBarsData: [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        gradient: AppColors.primaryGradient,
        barWidth: 3,
        dotData: FlDotData(
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: AppColors.primary,
              strokeWidth: 2,
              strokeColor: AppColors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.3),
              AppColors.primary.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    ],
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) =>
            isDark ? AppColors.elevatedDark : AppColors.textPrimaryLight,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            return LineTooltipItem(
              '${spot.y.toStringAsFixed(1)} kg',
              const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            );
          }).toList();
        },
      ),
    ),
    minY: minY,
    maxY: maxY,
  );
}
