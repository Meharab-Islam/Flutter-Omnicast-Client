import 'package:flutter/material.dart';
import '../models/pk_models.dart';

/// A highly visual, animated split-score progress bar widget for live PK Battles.
///
/// Dynamically calculates winning/losing proportions with smooth animation,
/// customizable gradients, score counters, and a central timer badge.
class PKScoreProgressBar extends StatelessWidget {
  /// The active [PKState] snapshot.
  final PKState pkState;

  /// Height of the progress bar track. Defaults to 28.0.
  final double height;

  /// Border radius of the outer container. Defaults to 14.0.
  final double borderRadius;

  /// Custom gradient for the Host (left) side.
  final Gradient? hostGradient;

  /// Custom gradient for the Opponent (right) side.
  final Gradient? opponentGradient;

  /// TextStyle for host & opponent score counts.
  final TextStyle? scoreTextStyle;

  /// TextStyle for the countdown timer.
  final TextStyle? timerTextStyle;

  /// Whether to show the central countdown timer badge. Defaults to true.
  final bool showTimer;

  const PKScoreProgressBar({
    super.key,
    required this.pkState,
    this.height = 28.0,
    this.borderRadius = 14.0,
    this.hostGradient,
    this.opponentGradient,
    this.scoreTextStyle,
    this.timerTextStyle,
    this.showTimer = true,
  });

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHostGradient = hostGradient ??
        const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
        );

    final effectiveOpponentGradient = opponentGradient ??
        const LinearGradient(
          colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
        );

    final defaultScoreStyle = scoreTextStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        );

    final targetRatio = pkState.hostScoreRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional status / timer badge
        if (showTimer) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: pkState.isPunishmentPhase
                  ? const Color(0xFFE53935)
                  : Colors.black87,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  pkState.isPunishmentPhase
                      ? Icons.warning_amber_rounded
                      : Icons.timer_outlined,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  pkState.isPunishmentPhase
                      ? 'PUNISHMENT: ${_formatTimer(pkState.remainingSeconds)}'
                      : _formatTimer(pkState.remainingSeconds),
                  style: timerTextStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ),
        ],

        // Animated Dual-Bar Track
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated Background Split
              SizedBox(
                height: height,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.5, end: targetRatio),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, ratio, _) {
                    return Row(
                      children: [
                        // Host Side
                        Expanded(
                          flex: (ratio * 1000).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: effectiveHostGradient,
                            ),
                          ),
                        ),
                        // Opponent Side
                        Expanded(
                          flex: ((1.0 - ratio) * 1000).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: effectiveOpponentGradient,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Left Host Score Counter
              Positioned(
                left: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 13, color: Colors.amberAccent),
                    const SizedBox(width: 3),
                    Text(
                      pkState.myScore.toString(),
                      style: defaultScoreStyle,
                    ),
                  ],
                ),
              ),

              // Central "VS" Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Right Opponent Score Counter
              Positioned(
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pkState.opponentScore.toString(),
                      style: defaultScoreStyle,
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.star, size: 13, color: Colors.amberAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
