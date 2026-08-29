import 'dart:math';
import 'package:flutter/material.dart';
import '../datachannel/data_channel_manager.dart';

/// High-performance floating heart & emoji particle overlay powered natively
/// by [AnimationController], [AnimatedBuilder], and [Transform.translate].
class OmniCastFlyingHeartsOverlay extends StatefulWidget {
  final ValueNotifier<DataChannelReaction?>? reactionNotifier;
  final Stream<DataChannelReaction>? reactionStream;

  const OmniCastFlyingHeartsOverlay({
    super.key,
    this.reactionNotifier,
    this.reactionStream,
  }) : assert(reactionNotifier != null || reactionStream != null,
            'Must provide either reactionNotifier or reactionStream');

  @override
  State<OmniCastFlyingHeartsOverlay> createState() => _OmniCastFlyingHeartsOverlayState();
}

class _OmniCastFlyingHeartsOverlayState extends State<OmniCastFlyingHeartsOverlay>
    with TickerProviderStateMixin {
  final List<_FloatingHeartItem> _hearts = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    widget.reactionNotifier?.addListener(_onReactionNotifierFired);
    widget.reactionStream?.listen(_spawnHeart);
  }

  void _onReactionNotifierFired() {
    final reaction = widget.reactionNotifier?.value;
    if (reaction != null) {
      _spawnHeart(reaction);
    }
  }

  void _spawnHeart(DataChannelReaction reaction) {
    if (!mounted) return;

    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + _random.nextInt(800)),
    );

    final item = _FloatingHeartItem(
      key: UniqueKey(),
      emoji: reaction.emoji,
      startX: reaction.xOffset,
      controller: controller,
      drift: (_random.nextDouble() - 0.5) * 70,
      scale: 0.85 + (_random.nextDouble() * 0.45),
    );

    setState(() => _hearts.add(item));

    controller.forward().then((_) {
      if (mounted) {
        setState(() => _hearts.remove(item));
      }
      controller.dispose();
    });
  }

  @override
  void dispose() {
    widget.reactionNotifier?.removeListener(_onReactionNotifierFired);
    for (final h in _hearts) {
      h.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _hearts.map((heart) {
          return AnimatedBuilder(
            animation: heart.controller,
            builder: (context, _) {
              final progress = heart.controller.value;
              final size = MediaQuery.of(context).size;

              final offsetY = -progress * (size.height * 0.65);
              final offsetX = (size.width * heart.startX) + (sin(progress * pi * 2) * heart.drift);
              final opacity = (1.0 - progress).clamp(0.0, 1.0);

              return Positioned(
                bottom: 80,
                left: 0,
                child: Transform.translate(
                  offset: Offset(offsetX, offsetY),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: heart.scale * (0.8 + (progress * 0.4)),
                      child: Text(
                        heart.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _FloatingHeartItem {
  final Key key;
  final String emoji;
  final double startX;
  final double drift;
  final double scale;
  final AnimationController controller;

  _FloatingHeartItem({
    required this.key,
    required this.emoji,
    required this.startX,
    required this.drift,
    required this.scale,
    required this.controller,
  });
}
