import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';
import 'omnicast_gifting_bottom_sheet.dart';
import 'omnicast_seat_requests_bottom_sheet.dart';

/// Turnkey interactive bottom action bar widget.
///
/// Features:
/// - Inline Chat Input Field or Quick-Chat Trigger
/// - Mic Mute / Unmute Toggle
/// - Camera Switch & Video Toggle (for Host & Co-Hosts)
/// - Gift Button (opens [OmniCastGiftingBottomSheet])
/// - Co-Host Stage Request / Manage Button
/// - Heart / Like Reaction Button with multi-tap burst support
class OmniCastLiveBottomBar extends StatefulWidget {
  final OmniCastClient client;
  final VoidCallback? onLikePressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onSettingsPressed;
  final bool showChatInput;
  final bool showGifting;
  final bool showCoHost;
  final bool showReactions;

  const OmniCastLiveBottomBar({
    super.key,
    required this.client,
    this.onLikePressed,
    this.onSharePressed,
    this.onSettingsPressed,
    this.showChatInput = true,
    this.showGifting = true,
    this.showCoHost = true,
    this.showReactions = true,
  });

  @override
  State<OmniCastLiveBottomBar> createState() => _OmniCastLiveBottomBarState();
}

class _OmniCastLiveBottomBarState extends State<OmniCastLiveBottomBar> {
  final TextEditingController _chatController = TextEditingController();

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    widget.client.interaction.sendChat(text);
    _chatController.clear();
    FocusScope.of(context).unfocus();
  }

  void _showChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1B2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Say something friendly...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) {
                      _sendChatMessage();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    _sendChatMessage();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.client.state,
        widget.client.mediaStreamManager,
      ]),
      builder: (context, _) {
        final isHost = widget.client.state.isHost;
        final isCoHost = widget.client.state.isCoHost;
        final canBroadcast = isHost || isCoHost;
        final isAudioMuted = widget.client.mediaStreamManager.isAudioMuted;
        final isVideoMuted = widget.client.mediaStreamManager.isVideoMuted;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // 1. Chat Trigger Button / Field
                if (widget.showChatInput)
                  Expanded(
                    child: GestureDetector(
                      onTap: _showChatDialog,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white.withOpacity(0.6),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Comment...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // 2. Host / Co-Host Media Controls (Mic, Cam, Flip)
                if (canBroadcast) ...[
                  _buildCircleButton(
                    icon: isAudioMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    color: isAudioMuted
                        ? const Color(0xFFEF4444)
                        : Colors.black.withOpacity(0.45),
                    onTap: () {
                      widget.client.media.toggleAudio(!isAudioMuted);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCircleButton(
                    icon: isVideoMuted
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    color: isVideoMuted
                        ? const Color(0xFFEF4444)
                        : Colors.black.withOpacity(0.45),
                    onTap: () {
                      widget.client.media.toggleVideo(!isVideoMuted);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCircleButton(
                    icon: Icons.flip_camera_ios_rounded,
                    color: Colors.black.withOpacity(0.45),
                    onTap: () {
                      widget.client.media.switchCamera();
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // 3. Co-Host Stage / Seat Requests Button
                if (widget.showCoHost) ...[
                  if (isHost)
                    _buildCircleButton(
                      icon: Icons.group_add_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => OmniCastSeatRequestsBottomSheet(
                            client: widget.client,
                          ),
                        );
                      },
                    )
                  else if (!isCoHost)
                    _buildCircleButton(
                      icon: Icons.airline_seat_recline_extra_rounded,
                      color: Colors.black.withOpacity(0.45),
                      onTap: () {
                        widget.client.seats.requestSeat();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Co-Host request sent to Host!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    )
                  else
                    _buildCircleButton(
                      icon: Icons.exit_to_app_rounded,
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        widget.client.seats.leaveSeat();
                      },
                    ),
                  const SizedBox(width: 8),
                ],

                // 4. Gift Button
                if (widget.showGifting && !isHost) ...[
                  _buildCircleButton(
                    icon: Icons.card_giftcard_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF007F), Color(0xFFFF758C)],
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => OmniCastGiftingBottomSheet(
                          client: widget.client,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // 5. Like / Heart Button
                if (widget.showReactions)
                  _buildCircleButton(
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFF43F5E),
                    onTap: () {
                      widget.client.interaction.sendLike();
                      widget.onLikePressed?.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    Color? color,
    Gradient? gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
