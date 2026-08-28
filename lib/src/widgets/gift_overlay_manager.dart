import 'dart:async';
import 'package:flutter/material.dart';
import '../models/interaction_models.dart';

/// An animated overlay widget that wraps live video feeds and renders temporary,
/// sliding virtual gift banners with combo multipliers and auto-dismissal.
class GiftOverlayManager extends StatefulWidget {
  /// The underlying child widget (e.g., [OmniCastVideoView] or live stage).
  final Widget child;

  /// Stream of incoming [GiftEvent] instances (typically `client.interaction.onGiftReceived`).
  final Stream<GiftEvent> giftStream;

  /// Duration before a gift banner auto-dismisses. Defaults to 3 seconds.
  final Duration displayDuration;

  /// Maximum simultaneous gift banners displayed on screen. Defaults to 3.
  final int maxSimultaneousBanners;

  /// Optional alignment for the gift banner stack. Defaults to [Alignment.bottomLeft].
  final Alignment bannerAlignment;

  const GiftOverlayManager({
    super.key,
    required this.child,
    required this.giftStream,
    this.displayDuration = const Duration(seconds: 3),
    this.maxSimultaneousBanners = 3,
    this.bannerAlignment = Alignment.bottomLeft,
  });

  @override
  State<GiftOverlayManager> createState() => _GiftOverlayManagerState();
}

class _ActiveGiftItem {
  final String id;
  final GiftEvent event;
  int combo;
  Timer? timer;

  _ActiveGiftItem({
    required this.id,
    required this.event,
    this.combo = 1,
  });
}

class _GiftOverlayManagerState extends State<GiftOverlayManager> {
  StreamSubscription<GiftEvent>? _streamSubscription;
  final List<_ActiveGiftItem> _activeGifts = [];

  @override
  void initState() {
    super.initState();
    _streamSubscription = widget.giftStream.listen(_handleIncomingGift);
  }

  @override
  void didUpdateWidget(covariant GiftOverlayManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.giftStream != widget.giftStream) {
      _streamSubscription?.cancel();
      _streamSubscription = widget.giftStream.listen(_handleIncomingGift);
    }
  }

  void _handleIncomingGift(GiftEvent event) {
    final giftKey = '${event.senderId}_${event.giftId}';
    final existingIdx = _activeGifts.indexWhere((g) => g.id == giftKey);

    setState(() {
      if (existingIdx >= 0) {
        // Combo Increment
        final item = _activeGifts[existingIdx];
        item.combo += event.amount;
        item.timer?.cancel();
        item.timer = Timer(widget.displayDuration, () => _dismissGift(item.id));
      } else {
        // New Gift Banner
        if (_activeGifts.length >= widget.maxSimultaneousBanners) {
          final removed = _activeGifts.removeAt(0);
          removed.timer?.cancel();
        }

        final newItem = _ActiveGiftItem(
          id: giftKey,
          event: event,
          combo: event.amount,
        );

        newItem.timer = Timer(widget.displayDuration, () => _dismissGift(newItem.id));
        _activeGifts.add(newItem);
      }
    });
  }

  void _dismissGift(String id) {
    if (!mounted) return;
    setState(() {
      _activeGifts.removeWhere((g) => g.id == id);
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    for (final item in _activeGifts) {
      item.timer?.cancel();
    }
    _activeGifts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Content
        widget.child,

        // Gift Banner Overlay Stack
        Positioned.fill(
          child: Align(
            alignment: widget.bannerAlignment,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 120),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _activeGifts.map((item) {
                  return _GiftBannerWidget(
                    key: ValueKey('${item.id}_${item.combo}'),
                    item: item,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GiftBannerWidget extends StatelessWidget {
  final _ActiveGiftItem item;

  const _GiftBannerWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(-50 * (1.0 - val), 0),
          child: Opacity(
            opacity: val.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF673AB7)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender Avatar / Icon
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white24,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),

            // Sender & Gift info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.event.senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sent ${item.event.giftName}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Gift Icon Badge
            const Icon(Icons.card_giftcard, size: 20, color: Colors.amberAccent),
            const SizedBox(width: 6),

            // Animated Combo Badge
            TweenAnimationBuilder<double>(
              key: ValueKey(item.combo),
              tween: Tween<double>(begin: 1.6, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.elasticOut,
              builder: (context, scale, _) {
                return Transform.scale(
                  scale: scale,
                  child: Text(
                    'x${item.combo}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
