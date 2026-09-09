import 'dart:async';
import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';
import 'omnicast_viewers_bottom_sheet.dart';

/// Turnkey live streaming top header bar widget.
///
/// Displays:
/// - Host Profile Avatar & Display Name
/// - Dynamic Live Duration Clock
/// - Real-time Viewers Count Pill (Tapping opens [OmniCastViewersBottomSheet])
/// - Follow / Sub Button (optional)
/// - Close / Exit Stream Button with confirmation
class OmniCastLiveHeader extends StatefulWidget {
  final OmniCastClient client;
  final String? hostDisplayName;
  final String? hostAvatarUrl;
  final VoidCallback? onClosePressed;
  final VoidCallback? onFollowPressed;
  final bool isFollowing;
  final bool showFollowButton;

  const OmniCastLiveHeader({
    super.key,
    required this.client,
    this.hostDisplayName,
    this.hostAvatarUrl,
    this.onClosePressed,
    this.onFollowPressed,
    this.isFollowing = false,
    this.showFollowButton = false,
  });

  @override
  State<OmniCastLiveHeader> createState() => _OmniCastLiveHeaderState();
}

class _OmniCastLiveHeaderState extends State<OmniCastLiveHeader> {
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final hostName = widget.hostDisplayName ??
        (widget.client.state.isHost ? 'You (Host)' : 'Broadcaster');

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // 1. Host Profile Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF6366F1),
                    backgroundImage: widget.hostAvatarUrl != null
                        ? NetworkImage(widget.hostAvatarUrl!)
                        : null,
                    child: widget.hostAvatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hostName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(_secondsElapsed),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.showFollowButton && !widget.client.state.isHost) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onFollowPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isFollowing
                                ? [Colors.white24, Colors.white12]
                                : [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.isFollowing ? 'Following' : '+ Follow',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Spacer(),

            // 2. Real-time Viewers Pill
            ValueListenableBuilder<int>(
              valueListenable: widget.client.room.totalViewerCount,
              builder: (context, count, _) {
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => OmniCastViewersBottomSheet(
                        client: widget.client,
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          color: Color(0xFF60A5FA),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 8),

            // 3. Exit / Close Stream Button
            GestureDetector(
              onTap: widget.onClosePressed ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
