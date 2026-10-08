import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/fasting_session_model.dart';
import '../controllers/fasting_controller.dart';

class FastingScreen extends ConsumerWidget {
  const FastingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionAsync = ref.watch(activeFastingSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Intermittent Fasting')),
      body: activeSessionAsync.when(
        data: (activeSession) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  child: Column(
                    children: [
                      if (activeSession != null)
                        _ActiveFastingView(session: activeSession)
                      else
                        const _StartFastingView(),
                      const SizedBox(height: AppDimensions.spacingXl),
                      const _FastingStatsGrid(),
                      const SizedBox(height: AppDimensions.spacingXl),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Fasts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                    ],
                  ),
                ),
              ),
              const _FastingHistoryList(),
            ],
          );
        },
        loading: () => const Center(child: XenovaLoadingIndicator()),
        error: (e, st) =>
            Center(child: XenovaErrorWidget(message: e.toString())),
      ),
    );
  }
}

class _ActiveFastingView extends ConsumerStatefulWidget {
  const _ActiveFastingView({required this.session});

  final FastingSessionModel session;

  @override
  ConsumerState<_ActiveFastingView> createState() => _ActiveFastingViewState();
}

class _ActiveFastingViewState extends ConsumerState<_ActiveFastingView> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateElapsed(),
    );
  }

  void _updateElapsed() {
    if (mounted) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.session.startTime);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final targetDuration = Duration(
      minutes: (widget.session.targetDurationHours * 60).toInt(),
    );
    final progress = (_elapsed.inSeconds / targetDuration.inSeconds).clamp(
      0.0,
      1.0,
    );
    final isGoalReached = _elapsed >= targetDuration;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 16,
                backgroundColor: AppColors.primarySurface,
                color: isGoalReached ? AppColors.success : AppColors.primary,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGoalReached ? 'Goal Reached!' : 'Fasting',
                  style: TextStyle(
                    color: isGoalReached
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_elapsed),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Goal: ${_formatGoal(widget.session.targetDurationHours)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () {
              ref.read(fastingControllerProvider.notifier).endFast();
            },
            style: FilledButton.styleFrom(
              backgroundColor: isGoalReached
                  ? AppColors.success
                  : AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isGoalReached ? 'Complete Fast' : 'End Early',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  String _formatGoal(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _StartFastingView extends ConsumerStatefulWidget {
  const _StartFastingView();

  @override
  ConsumerState<_StartFastingView> createState() => _StartFastingViewState();
}

class _StartFastingViewState extends ConsumerState<_StartFastingView> {
  FastingPlan _selectedPlan = FastingPlan.sixteenEight;
  double _customHours = 16.0;

  String _formatHoursDisplay(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '$h Hours';
    return '$h Hours $m Min';
  }

  String _formatCompactHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  void _showAdjustCustomTimeSheet(BuildContext context) {
    double tempHours = _customHours;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final h = tempHours.floor();
            final m = ((tempHours - h) * 60).round();
            final formattedDuration = m == 0 ? '$h hrs' : '$h hrs $m mins';
            final targetEnd = DateTime.now().add(
              Duration(minutes: (tempHours * 60).round()),
            );
            final formattedEnd =
                DateFormat('EEE, MMM d • h:mm a').format(targetEnd);

            // Fasting stage preview note
            String stageLabel;
            String stageDesc;
            IconData stageIcon;
            if (tempHours < 14) {
              stageLabel = 'Beginner / Gentle Fast';
              stageDesc = 'Digestive rest & blood sugar stabilization';
              stageIcon = Icons.spa_outlined;
            } else if (tempHours <= 18) {
              stageLabel = 'Metabolic Switch & Fat Burn';
              stageDesc = 'Glycogen depletion & elevated fat burning';
              stageIcon = Icons.local_fire_department_outlined;
            } else if (tempHours <= 24) {
              stageLabel = 'Autophagy & Cellular Renewal';
              stageDesc = 'Cellular clean-up, recycling & repair';
              stageIcon = Icons.auto_awesome_outlined;
            } else {
              stageLabel = 'Extended / Deep Fast';
              stageDesc = 'Deep systemic reboot & insulin sensitivity reset';
              stageIcon = Icons.bolt_outlined;
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    AppDimensions.spacingLg,
                top: AppDimensions.spacingMd,
                left: AppDimensions.spacingLg,
                right: AppDimensions.spacingLg,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(
                          bottom: AppDimensions.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // Title Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adjust Custom Fast',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Set your target fasting duration',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),

                      // Target Time Hero Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.spacingLg),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(
                                alpha: isDark ? 0.25 : 0.12,
                              ),
                              AppColors.primarySurface.withValues(
                                alpha: isDark ? 0.15 : 0.05,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusXl),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TARGET DURATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppColors.primary.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDuration,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.alarm_on_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Estimated End: $formattedEnd',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),

                      // Steppers Row (-1h, -30m, +30m, +1h)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildModalStepButton(
                            label: '- 1h',
                            onTap: () {
                              if (tempHours - 1.0 >= 1.0) {
                                setModalState(() => tempHours -= 1.0);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildModalStepButton(
                            label: '- 30m',
                            onTap: () {
                              if (tempHours - 0.5 >= 1.0) {
                                setModalState(() => tempHours -= 0.5);
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildModalStepButton(
                            label: '+ 30m',
                            onTap: () {
                              if (tempHours + 0.5 <= 72.0) {
                                setModalState(() => tempHours += 0.5);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildModalStepButton(
                            label: '+ 1h',
                            onTap: () {
                              if (tempHours + 1.0 <= 72.0) {
                                setModalState(() => tempHours += 1.0);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),

                      // Slider
                      Row(
                        children: [
                          const Text(
                            '1h',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                thumbColor: AppColors.primary,
                                inactiveTrackColor: AppColors.primary
                                    .withValues(alpha: 0.15),
                                trackHeight: 6,
                              ),
                              child: Slider(
                                value: tempHours.clamp(1.0, 72.0),
                                min: 1.0,
                                max: 72.0,
                                divisions: 142,
                                label: formattedDuration,
                                onChanged: (val) {
                                  setModalState(() {
                                    tempHours = (val * 2).round() / 2.0;
                                  });
                                },
                              ),
                            ),
                          ),
                          const Text(
                            '72h',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),

                      // Popular Quick Presets
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Popular Quick Presets',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          12.0,
                          14.0,
                          16.0,
                          18.0,
                          20.0,
                          24.0,
                          36.0,
                          48.0,
                        ].map((preset) {
                          final isSelected = tempHours == preset;
                          final pH = preset.toInt();
                          return ChoiceChip(
                            label: Text('${pH}h'),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: isDark
                                ? AppColors.elevatedDark
                                : const Color(0xFFF1F5F9),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.borderDark
                                      : const Color(0xFFCBD5E1)),
                              width: 1,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : const Color(0xFF1E293B)),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setModalState(() => tempHours = preset);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),

                      // Fasting Stage Preview Card
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingMd),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.elevatedDark
                              : AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(stageIcon, color: AppColors.primary, size: 28),
                            const SizedBox(width: AppDimensions.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stageLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stageDesc,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXl),

                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _customHours = tempHours;
                              _selectedPlan = FastingPlan.custom;
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Custom fast duration set to $formattedDuration!',
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Set Custom Fast ($formattedDuration)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalStepButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCustomDurationCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetEnd = DateTime.now().add(
      Duration(minutes: (_customHours * 60).round()),
    );
    final formattedEnd = DateFormat('EEE • h:mm a').format(targetEnd);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              const Text(
                'Custom Fast Goal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAdjustCustomTimeSheet(context),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text(
                  'Adjust',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatHoursDisplay(_customHours),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Target: $formattedEnd',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuickStepCircle(
                    icon: Icons.remove,
                    tooltip: 'Subtract 30m',
                    onTap: () {
                      if (_customHours - 0.5 >= 1.0) {
                        setState(() => _customHours -= 0.5);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickStepCircle(
                    icon: Icons.add,
                    tooltip: 'Add 30m',
                    onTap: () {
                      if (_customHours + 0.5 <= 72.0) {
                        setState(() => _customHours += 0.5);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStepCircle({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const Icon(Icons.timer_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'Ready to Fast?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          'Select a fasting plan to begin',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: FastingPlan.values.map((plan) {
            final isSelected = _selectedPlan == plan;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(plan.displayName),
                  if (plan == FastingPlan.custom) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.tune,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.primaryLight : AppColors.primary),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedPlan = plan);
                if (plan == FastingPlan.custom) {
                  _showAdjustCustomTimeSheet(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Fasting plan set to ${plan.displayName}!'),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor:
                  isDark ? AppColors.elevatedDark : const Color(0xFFF1F5F9),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                width: 1.2,
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF1E293B)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
        if (_selectedPlan == FastingPlan.custom) ...[
          const SizedBox(height: AppDimensions.spacingLg),
          _buildCustomDurationCard(context),
        ],
        const SizedBox(height: AppDimensions.spacingXl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: () {
              ref.read(fastingControllerProvider.notifier).startFast(
                    _selectedPlan,
                    customDuration: _selectedPlan == FastingPlan.custom
                        ? _customHours
                        : null,
                  );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              _selectedPlan == FastingPlan.custom
                  ? 'Start Custom Fast (${_formatCompactHours(_customHours)})'
                  : 'Start Fast',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FastingStatsGrid extends ConsumerWidget {
  const _FastingStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(fastingMetricsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildCard(String title, String value, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : const Color.fromRGBO(60, 48, 32, 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    final longestHours = (metrics.longestFastMinutes / 60).toStringAsFixed(1);
    final averageHours = metrics.averageFastHours.toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: buildCard(
            'Longest Fast',
            '${longestHours}h',
            Icons.emoji_events_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: buildCard(
            'Current Streak',
            '${metrics.currentStreakDays} Days',
            Icons.local_fire_department_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: buildCard(
            'Average Fast',
            '${averageHours}h',
            Icons.analytics_outlined,
          ),
        ),
      ],
    );
  }
}

class _FastingHistoryList extends ConsumerWidget {
  const _FastingHistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(fastingHistoryProvider);

    return historyAsync.when(
      data: (history) {
        final completedFasts = history.where((f) => f.endTime != null).toList();

        if (completedFasts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingXxl,
                horizontal: AppDimensions.spacingLg,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 80,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Text(
                      'No fasting sessions yet',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      'Start a fast to build your history.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final session = completedFasts[index];
            final dateStr =
                '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';
            final durationHours = (session.durationMinutes ?? 0) / 60;

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: session.completed
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.completed
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: session.completed
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              title: Text('${durationHours.toStringAsFixed(1)} Hours'),
              subtitle: Text('$dateStr • ${session.planType.displayName}'),
              trailing: Text(
                session.completed ? 'Goal Reached' : 'Ended Early',
                style: TextStyle(
                  color: session.completed
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }, childCount: completedFasts.length),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}
