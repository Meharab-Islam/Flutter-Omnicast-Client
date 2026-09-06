import 'package:flutter/material.dart';

class MediaControlBar extends StatefulWidget {
  final bool isHost;
  final bool isCoHost;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isPKActive;
  final ValueChanged<String> onSendChat;
  final VoidCallback onOpenGifts;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onSeatAction;
  final VoidCallback onPKAction;
  final ValueChanged<String> onSelectLayer;
  final VoidCallback onICERestart;

  const MediaControlBar({
    super.key,
    required this.isHost,
    required this.isCoHost,
    required this.isMicMuted,
    required this.isCameraOff,
    required this.isPKActive,
    required this.onSendChat,
    required this.onOpenGifts,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onSeatAction,
    required this.onPKAction,
    required this.onSelectLayer,
    required this.onICERestart,
  });

  @override
  State<MediaControlBar> createState() => _MediaControlBarState();
}

class _MediaControlBarState extends State<MediaControlBar> {
  final TextEditingController _chatController = TextEditingController();

  void _submitChat() {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendChat(text);
      _chatController.clear();
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = widget.isHost || widget.isCoHost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Chat Input & Primary Actions (Send, Gift, Co-Host, PK)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2132),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitChat(),
                      decoration: InputDecoration(
                        hintText: 'Say something in live room...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF00CEC9),
                            size: 18,
                          ),
                          onPressed: _submitChat,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Gift Button
                _buildCircleButton(
                  icon: Icons.card_giftcard_rounded,
                  color: const Color(0xFFFF7675),
                  tooltip: 'Send Gift',
                  onTap: widget.onOpenGifts,
                ),

                const SizedBox(width: 6),

                // Seat / Co-Host Button
                _buildCircleButton(
                  icon: widget.isCoHost
                      ? Icons.airline_seat_recline_normal_rounded
                      : Icons.person_add_alt_1_rounded,
                  color: widget.isCoHost
                      ? Colors.amberAccent
                      : const Color(0xFF6C5CE7),
                  tooltip: widget.isHost
                      ? 'Manage Seats'
                      : (widget.isCoHost ? 'Leave Seat' : 'Request Seat'),
                  onTap: widget.onSeatAction,
                ),

                // PK Battle Button (Host only)
                if (widget.isHost) ...[
                  const SizedBox(width: 6),
                  _buildCircleButton(
                    icon: Icons.local_fire_department_rounded,
                    color: widget.isPKActive
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                    tooltip: widget.isPKActive
                        ? 'End PK Battle'
                        : 'Start PK Battle',
                    onTap: widget.onPKAction,
                  ),
                ],
              ],
            ),

            // Row 2: Media & Stream Controls
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // If publisher: Mic, Camera, Flip controls
                if (canPublish) ...[
                  Row(
                    children: [
                      _buildPillButton(
                        icon: widget.isMicMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: widget.isMicMuted ? 'Muted' : 'Mic',
                        color: widget.isMicMuted
                            ? Colors.redAccent
                            : Colors.white70,
                        onTap: widget.onToggleMic,
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        icon: widget.isCameraOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        label: widget.isCameraOff ? 'Cam Off' : 'Camera',
                        color: widget.isCameraOff
                            ? Colors.redAccent
                            : Colors.white70,
                        onTap: widget.onToggleCamera,
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        icon: Icons.flip_camera_ios_rounded,
                        label: 'Flip',
                        color: Colors.white70,
                        onTap: widget.onSwitchCamera,
                      ),
                    ],
                  ),
                ] else ...[
                  // If viewer: Simulcast Layer selector
                  PopupMenuButton<String>(
                    tooltip: 'Select Video Quality',
                    onSelected: widget.onSelectLayer,
                    color: const Color(0xFF1E2132),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'auto',
                        child: Text(
                          'Auto (Dynacast/ABR)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'f',
                        child: Text(
                          'High (720p HD)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'h',
                        child: Text(
                          'Medium (360p)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'q',
                        child: Text(
                          'Low (180p)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    child: _buildPillButton(
                      icon: Icons.hd_rounded,
                      label: 'Quality',
                      color: Colors.white70,
                      onTap: null, // handled by PopupMenuButton
                    ),
                  ),
                ],

                // ICE Restart Button (Simulate network handover)
                _buildPillButton(
                  icon: Icons.refresh_rounded,
                  label: 'ICE Restart',
                  color: Colors.white60,
                  onTap: widget.onICERestart,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2132),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
