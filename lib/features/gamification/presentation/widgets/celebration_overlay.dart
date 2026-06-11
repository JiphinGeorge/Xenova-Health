import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../domain/models/achievement_model.dart';

class GamificationEvent {
  final String title;
  final String message;
  final bool isLevelUp;
  final BadgeRarity? rarity;

  GamificationEvent({
    required this.title,
    required this.message,
    this.isLevelUp = false,
    this.rarity,
  });
}

class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  final Stream<GamificationEvent> eventStream;

  const CelebrationOverlay({
    super.key,
    required this.child,
    required this.eventStream,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late ConfettiController _confettiController;
  GamificationEvent? _currentEvent;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    widget.eventStream.listen((event) {
      if (mounted) {
        setState(() {
          _currentEvent = event;
          _isVisible = true;
        });
        
        // Trigger confetti for Level Up or Rare/Epic/Legendary badges
        if (event.isLevelUp || (event.rarity != null && event.rarity != BadgeRarity.common)) {
          _confettiController.play();
        }

        // Hide overlay after delay
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Confetti layer
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            gravity: 0.2,
            emissionFrequency: 0.05,
          ),
        ),

        // Achievement Toast UI
        if (_isVisible && _currentEvent != null)
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: _currentEvent!.isLevelUp 
                        ? Colors.amber 
                        : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _currentEvent!.isLevelUp ? Icons.military_tech : Icons.emoji_events,
                        color: _currentEvent!.isLevelUp ? Colors.amber : Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentEvent!.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _currentEvent!.isLevelUp ? Colors.amber.shade700 : null,
                              ),
                            ),
                            Text(
                              _currentEvent!.message,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
