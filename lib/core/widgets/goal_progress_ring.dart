import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// A circular progress ring used to display goal progress.
class GoalProgressRing extends StatelessWidget {
  const GoalProgressRing({
    required this.progress,
    super.key,
    this.size = 100,
    this.strokeWidth = 8,
    this.child,
  });

  /// The progress from 0.0 to 1.0.
  final double progress;

  /// The diameter of the ring.
  final double size;

  /// The thickness of the ring.
  final double strokeWidth;

  /// Optional child widget placed in the center of the ring.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.primarySurface.withValues(alpha: 0.1)
                : AppColors.primarySurface,
          ),
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            color: AppColors.primary,
            strokeCap: StrokeCap.round,
          ),
          if (child != null) Center(child: child),
        ],
      ),
    );
  }
}
