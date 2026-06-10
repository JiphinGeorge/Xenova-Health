import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/goal_progress_ring.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/weight_entry_model.dart';
import '../../domain/models/weight_metrics.dart';
import '../controllers/weight_controller.dart';
import '../widgets/add_weight_dialog.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  int _timeRangeIndex = 1; // 0 = 7D, 1 = 30D, 2 = 90D, 3 = 1Y, 4 = All

  void _showAddDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const AddWeightDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(weightEntriesStreamProvider);
    final metrics = ref.watch(weightMetricsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weight Tracker')),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is handled automatically by the Firestore stream,
              // but adding the indicator provides good UX.
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTimeRangeSelector(),
                        const SizedBox(height: AppDimensions.spacingLg),
                        _buildChart(entries, metrics.targetWeight),
                        if (metrics.trendInsight != null) ...[
                          const SizedBox(height: AppDimensions.spacingSm),
                          Text(
                            metrics.trendInsight!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppDimensions.spacingLg),
                        _buildGoalProgressCard(metrics),
                        const SizedBox(height: AppDimensions.spacingMd),
                        _buildStatsGrid(metrics),
                        const SizedBox(height: AppDimensions.spacingXl),
                        Text(
                          'History',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = entries[index];
                    return _buildHistoryTile(entry);
                  }, childCount: entries.length),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: XenovaLoadingIndicator()),
        error: (e, st) =>
            Center(child: XenovaErrorWidget(message: e.toString())),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Log Weight'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Text(
            'No weight logged yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Start tracking to see your progress.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = ['7D', '30D', '90D', '1Y', 'All'];
    return SegmentedButton<int>(
      segments: [
        for (var i = 0; i < ranges.length; i++)
          ButtonSegment(value: i, label: Text(ranges[i])),
      ],
      selected: {_timeRangeIndex},
      onSelectionChanged: (set) {
        setState(() {
          _timeRangeIndex = set.first;
        });
      },
    );
  }

  Widget _buildChart(List<WeightEntryModel> allEntries, double? targetWeight) {
    // Filter entries based on time range
    final now = DateTime.now();
    DateTime cutoff;
    switch (_timeRangeIndex) {
      case 0:
        cutoff = now.subtract(const Duration(days: 7));
      case 1:
        cutoff = now.subtract(const Duration(days: 30));
      case 2:
        cutoff = now.subtract(const Duration(days: 90));
      case 3:
        cutoff = now.subtract(const Duration(days: 365));
      default:
        cutoff = DateTime(2000); // All time
    }

    final filtered = allEntries.where((e) => e.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (filtered.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        alignment: Alignment.center,
        child: const Text('No data for this time range'),
      );
    }

    final spots = filtered.map((e) {
      return FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.weight);
    }).toList();

    // Compute moving average spots
    final movingAverageSpots = <FlSpot>[];
    for (final spot in spots) {
      final x = spot.x;
      final sevenDaysAgo = x - (7 * 24 * 60 * 60 * 1000);
      final entriesInWindow = allEntries.where((e) {
        final t = e.date.millisecondsSinceEpoch.toDouble();
        return t <= x && t >= sevenDaysAgo;
      }).toList();

      if (entriesInWindow.isNotEmpty) {
        final avg =
            entriesInWindow.map((e) => e.weight).reduce((a, b) => a + b) /
            entriesInWindow.length;
        movingAverageSpots.add(FlSpot(x, avg));
      }
    }

    var minX = spots.first.x;
    var maxX = spots.last.x;
    if (minX == maxX) {
      minX -= const Duration(days: 1).inMilliseconds;
      maxX += const Duration(days: 1).inMilliseconds;
    }

    var minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    var maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    if (targetWeight != null) {
      if (targetWeight < minY) minY = targetWeight;
      if (targetWeight > maxY) maxY = targetWeight;
    }

    minY -= 2;
    maxY += 2;

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 16, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.elevatedDark
            : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Only show 3 labels: Start, Middle, End
                  if (value == minX ||
                      value == maxX ||
                      value == (minX + maxX) / 2) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${date.month}/${date.day}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    spot.x.toInt(),
                  );
                  final dateStr = '${date.month}/${date.day}';
                  return LineTooltipItem(
                    '$dateStr\n${spot.y} kg',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (targetWeight != null)
                HorizontalLine(
                  y: targetWeight,
                  color: AppColors.success,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                    ),
                    labelResolver: (line) => 'Goal',
                  ),
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
            if (movingAverageSpots.length > 1)
              LineChartBarData(
                spots: movingAverageSpots,
                isCurved: true,
                color: AppColors.secondary,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                dashArray: [5, 5],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressCard(WeightMetrics metrics) {
    if (metrics.targetWeight == null ||
        metrics.startWeight == null ||
        metrics.currentWeight == null) {
      return const SizedBox.shrink();
    }

    final diff = metrics.currentWeight! - metrics.targetWeight!;
    final isDone = diff <= 0; // Assuming lose weight goal

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Row(
          children: [
            GoalProgressRing(
              progress: metrics.goalProgressPercentage ?? 0.0,
              size: 80,
              child: Text(
                '${((metrics.goalProgressPercentage ?? 0) * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDone ? 'Goal Reached!' : 'Goal Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current: ${metrics.currentWeight} kg',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Target: ${metrics.targetWeight} kg',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (!isDone)
                    Text(
                      '${diff.toStringAsFixed(1)} kg remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(WeightMetrics metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppDimensions.spacingMd,
      mainAxisSpacing: AppDimensions.spacingMd,
      childAspectRatio: 2.5,
      children: [
        _StatCard(
          title: 'Change',
          value: metrics.weightLost != null
              ? '${metrics.weightLost! > 0 ? "-" : "+"}${metrics.weightLost!.abs().toStringAsFixed(1)} kg'
              : '--',
        ),
        _StatCard(title: 'BMI', value: metrics.bmi?.toStringAsFixed(1) ?? '--'),
        _StatCard(
          title: 'TDEE',
          value: metrics.tdee != null ? '${metrics.tdee!.toInt()} kcal' : '--',
        ),
        _StatCard(
          title: 'Since Last',
          value: metrics.changeSinceLast != null
              ? '${metrics.changeSinceLast! > 0 ? "+" : ""}${metrics.changeSinceLast!.toStringAsFixed(1)} kg'
              : '--',
        ),
      ],
    );
  }

  Widget _buildHistoryTile(WeightEntryModel entry) {
    final dateStr =
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(weightControllerProvider.notifier).deleteEntry(entry);
      },
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.spacingLg),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onLongPress: () => _showEditOptions(entry),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.monitor_weight_outlined,
            color: AppColors.primaryDark,
          ),
        ),
        title: Text(
          '${entry.weight} kg',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: entry.note != null ? Text(entry.note!) : null,
        trailing: Text(
          dateStr,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _showEditOptions(WeightEntryModel entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Entry'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog<void>(
                  context: context,
                  builder: (_) => AddWeightDialog(existingEntry: entry),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                'Delete Entry',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(weightControllerProvider.notifier).deleteEntry(entry);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
