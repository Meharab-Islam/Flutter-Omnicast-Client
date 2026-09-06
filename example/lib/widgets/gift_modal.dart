import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class GiftModal extends StatefulWidget {
  final bool isPKActive;
  final String hostId;
  final String? opponentId;
  final Function(DemoGift gift, String targetHostId) onSendGift;

  const GiftModal({
    super.key,
    required this.isPKActive,
    required this.hostId,
    this.opponentId,
    required this.onSendGift,
  });

  @override
  State<GiftModal> createState() => _GiftModalState();
}

class _GiftModalState extends State<GiftModal> {
  DemoGift _selectedGift = AppConstants.availableGifts.first;
  late String _targetHostId;

  @override
  void initState() {
    super.initState();
    _targetHostId = widget.hostId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2132),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Send Live Gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white60,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // If in PK Mode, choose which host to send gift to
            if (widget.isPKActive && widget.opponentId != null) ...[
              const Text(
                'Send Gift To:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(width: 4),
                          Text('Host A', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      selected: _targetHostId == widget.hostId,
                      onSelected: (val) {
                        if (val) setState(() => _targetHostId = widget.hostId);
                      },
                      selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                      backgroundColor: const Color(0xFF141724),
                      labelStyle: TextStyle(
                        color: _targetHostId == widget.hostId
                            ? Colors.blueAccent
                            : Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Colors.pinkAccent,
                          ),
                          SizedBox(width: 4),
                          Text('Opponent B', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      selected: _targetHostId == widget.opponentId,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _targetHostId = widget.opponentId!);
                        }
                      },
                      selectedColor: Colors.pinkAccent.withValues(alpha: 0.3),
                      backgroundColor: const Color(0xFF141724),
                      labelStyle: TextStyle(
                        color: _targetHostId == widget.opponentId
                            ? Colors.pinkAccent
                            : Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Gift Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: AppConstants.availableGifts.length,
              itemBuilder: (context, index) {
                final gift = AppConstants.availableGifts[index];
                final isSelected = _selectedGift.id == gift.id;

                return GestureDetector(
                  onTap: () => setState(() => _selectedGift = gift),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C5CE7).withValues(alpha: 0.25)
                          : const Color(0xFF141724),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C5CE7)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(gift.icon, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(
                          gift.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '🪙 ${gift.coins}',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Send Button
            ElevatedButton.icon(
              onPressed: () {
                widget.onSendGift(_selectedGift, _targetHostId);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                'Send ${_selectedGift.name} (🪙 ${_selectedGift.coins})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
