import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';
import '../models/room_models.dart';

/// Preset virtual gift option.
class VirtualGiftItem {
  final String id;
  final String name;
  final String emoji;
  final int coinPrice;

  const VirtualGiftItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.coinPrice,
  });
}

/// Interactive gifting bottom sheet with built-in Cross-Room PK targeted host selector
/// allowing viewers to send gifts to Host A (Blue) or Host B (Red).
class OmniCastGiftingBottomSheet extends StatefulWidget {
  final OmniCastClient client;
  final List<VirtualGiftItem> gifts;
  final VoidCallback? onGiftSent;
  final Function? onSendGift;

  const OmniCastGiftingBottomSheet({
    super.key,
    required this.client,
    this.gifts = const [
      VirtualGiftItem(id: 'rose', name: 'Rose', emoji: '🌹', coinPrice: 1),
      VirtualGiftItem(id: 'heart', name: 'Heart', emoji: '💖', coinPrice: 5),
      VirtualGiftItem(id: 'diamond', name: 'Diamond', emoji: '💎', coinPrice: 20),
      VirtualGiftItem(id: 'rocket', name: 'Rocket', emoji: '🚀', coinPrice: 100),
      VirtualGiftItem(id: 'dragon', name: 'Dragon', emoji: '🐉', coinPrice: 500),
    ],
    this.onGiftSent,
    this.onSendGift,
  });

  /// Static helper to open the modal bottom sheet smoothly.
  static Future<void> show(BuildContext context, {required OmniCastClient client}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => OmniCastGiftingBottomSheet(client: client),
    );
  }

  @override
  State<OmniCastGiftingBottomSheet> createState() => _OmniCastGiftingBottomSheetState();
}

class _OmniCastGiftingBottomSheetState extends State<OmniCastGiftingBottomSheet> {
  int _selectedGiftIndex = 0;
  String _selectedTarget = 'host_a'; // 'host_a' or 'host_b'

  @override
  Widget build(BuildContext context) {
    final isPK = widget.client.state.roomMode == RoomMode.pk;
    final activePK = widget.client.state.activePK;
    final hostAId = widget.client.state.hostId ?? 'host_a';
    final hostBId = activePK?.opponentUserId ?? 'host_b';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header with User Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Send Virtual Gift',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: ValueNotifier(widget.client.state.userCoinBalance),
                builder: (context, balance, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$balance Coins',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cross-Room PK Targeted Host Selector (Visible only during PK)
          if (isPK) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTarget = 'host_a'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTarget == 'host_a'
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Support Host A (Blue)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTarget = 'host_b'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTarget == 'host_b'
                              ? const Color(0xFFEF4444)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Support ${activePK?.opponentDisplayName ?? 'Rival Host (Red)'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Gift Grid
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.gifts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final gift = widget.gifts[index];
                final isSelected = _selectedGiftIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedGiftIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 85,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.white10,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(gift.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          gift.name,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                        Text(
                          '${gift.coinPrice} 🪙',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Send Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPK
                    ? (_selectedTarget == 'host_a'
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFEF4444))
                    : const Color(0xFFEC4899),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: () {
                final gift = widget.gifts[_selectedGiftIndex];
                final targetHostId = _selectedTarget == 'host_a' ? hostAId : hostBId;

                widget.client.interaction.sendGift(
                  giftId: gift.id,
                  targetUserId: targetHostId,
                  amount: 1,
                );

                if (widget.onSendGift != null) {
                  try {
                    (widget.onSendGift as dynamic)(
                      gift.id,
                      gift.name,
                      gift.coinPrice,
                      1,
                    );
                  } catch (_) {
                    try {
                      (widget.onSendGift as dynamic)(
                        gift.id,
                        gift.name,
                        gift.coinPrice,
                        1,
                        targetUserId: targetHostId,
                      );
                    } catch (_) {}
                  }
                }

                Navigator.of(context).pop();
                widget.onGiftSent?.call();
              },
              child: Text(
                isPK
                    ? 'Send to ${_selectedTarget == 'host_a' ? 'Host A' : (activePK?.opponentDisplayName ?? 'Rival Host')}'
                    : 'Send Gift (${widget.gifts[_selectedGiftIndex].coinPrice} Coins)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
