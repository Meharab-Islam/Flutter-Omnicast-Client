import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';
import '../models/room_models.dart';
import 'omnicast_speaking_video_tile.dart';

/// Inbuilt reactive live broadcasting canvas that automatically transitions between
/// Fullscreen Solo, Multi-guest Co-Host, and TikTok-style 50/50 Split-Screen PK Battle
/// based on [RoomMode] and WebRTC DataChannel events.
class OmniCastVideoCanvas extends StatelessWidget {
  final OmniCastClient client;
  final String hostName;
  final String? hostAvatarUrl;
  final String? opponentName;
  final String? opponentAvatarUrl;

  const OmniCastVideoCanvas({
    super.key,
    required this.client,
    this.hostName = 'Host',
    this.hostAvatarUrl,
    this.opponentName = 'Opponent',
    this.opponentAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RoomMode>(
      valueListenable: client.state.roomModeNotifier,
      builder: (context, mode, _) {
        return Stack(
          children: [
            // 1. Core Video Canvas Layer
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: switch (mode) {
                  RoomMode.pk => _buildPKSplitScreen(context),
                  RoomMode.coHost => _buildCoHostStage(context),
                  RoomMode.solo => _buildSoloScreen(context),
                },
              ),
            ),

            // 2. Built-in Real-time PK Score Engine & Progress Bar (Only visible when RoomMode == pk)
            if (mode == RoomMode.pk)
              Positioned(
                top: 48,
                left: 16,
                right: 16,
                child: _buildPKScoreHeader(context),
              ),
          ],
        );
      },
    );
  }

  /// Fullscreen Solo Broadcaster View
  Widget _buildSoloScreen(BuildContext context) {
    final localRenderer = client.streamManager.localRenderer;
    final isHost = client.state.isHost;
    final primaryTrackId = isHost ? 'local' : (client.state.hostId ?? 'host');
    final renderer = isHost ? localRenderer : client.streamManager.getRenderer(primaryTrackId);

    return OmniCastSpeakingVideoTile(
      key: const ValueKey('solo_canvas'),
      userId: primaryTrackId,
      trackId: primaryTrackId,
      userName: hostName,
      avatarUrl: hostAvatarUrl,
      renderer: renderer,
      isCameraEnabled: client.media.isCameraEnabled,
      isMicMuted: client.media.isMicrophoneMuted,
      audioDetector: client.media.audioDetector,
    );
  }

  /// TikTok-Style 50/50 Split Screen PK Battle View
  Widget _buildPKSplitScreen(BuildContext context) {
    final activePK = client.state.activePK;
    final hostId = client.state.hostId ?? client.state.userId ?? 'local';
    final opponentId = activePK?.opponentUserId ?? 'opponent';

    final hostRenderer = client.state.isHost
        ? client.streamManager.localRenderer
        : client.streamManager.getRenderer(hostId);
    final opponentRenderer = client.streamManager.getRenderer(opponentId);

    return Row(
      key: const ValueKey('pk_split_canvas'),
      children: [
        // Left 50% - Host A (Blue Team)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 96, bottom: 80, left: 6, right: 3),
            child: OmniCastSpeakingVideoTile(
              userId: hostId,
              trackId: hostId,
              userName: hostName,
              avatarUrl: hostAvatarUrl,
              renderer: hostRenderer,
              isCameraEnabled: client.media.isCameraEnabled,
              isMicMuted: client.media.isMicrophoneMuted,
              audioDetector: client.media.audioDetector,
            ),
          ),
        ),

        // Right 50% - Host B (Red Team)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 96, bottom: 80, left: 3, right: 6),
            child: OmniCastSpeakingVideoTile(
              userId: opponentId,
              trackId: opponentId,
              userName: activePK?.opponentDisplayName ?? opponentName ?? 'Opponent',
              avatarUrl: activePK?.opponentAvatarUrl ?? opponentAvatarUrl,
              renderer: opponentRenderer,
              isCameraEnabled: true,
              isMicMuted: false,
              audioDetector: client.media.audioDetector,
            ),
          ),
        ),
      ],
    );
  }

  /// Multi-Guest Co-Host Stage View
  Widget _buildCoHostStage(BuildContext context) {
    final activeSeats = client.state.activeSeats;

    return GridView.builder(
      key: const ValueKey('cohost_stage_canvas'),
      padding: const EdgeInsets.fromLTRB(12, 60, 12, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: activeSeats.length,
      itemBuilder: (context, index) {
        final seat = activeSeats[index];
        final userId = seat.userId ?? 'seat_$index';
        final isLocal = userId == client.state.userId;
        final renderer = isLocal
            ? client.streamManager.localRenderer
            : client.streamManager.getRenderer(userId);

        return OmniCastSpeakingVideoTile(
          userId: userId,
          trackId: userId,
          userName: seat.user?.displayName ?? 'Guest ${index + 1}',
          avatarUrl: seat.user?.avatarUrl,
          renderer: renderer,
          isCameraEnabled: isLocal ? client.media.isCameraEnabled : true,
          isMicMuted: isLocal ? client.media.isMicrophoneMuted : seat.isMuted,
          audioDetector: client.media.audioDetector,
        );
      },
    );
  }

  /// Built-in Real-time PK Score Header Bar (Red vs Blue Animation)
  Widget _buildPKScoreHeader(BuildContext context) {
    return ValueListenableBuilder<PkScore>(
      valueListenable: client.state.pkScoreNotifier,
      builder: (context, score, _) {
        final remainingSeconds = client.state.activePK?.remainingSeconds ?? 300;
        final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
        final secs = (remainingSeconds % 60).toString().padLeft(2, '0');

        return Column(
          children: [
            // 1. Timer & VS Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$mins:$secs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 2. Score Numerical Display (Blue vs Red)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${score.hostScore}',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${score.opponentScore}',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // 3. Animated Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    // Blue Bar (Host)
                    AnimatedFlexible(
                      flex: (score.hostRatio * 100).toInt().clamp(5, 95),
                      child: Container(color: const Color(0xFF3B82F6)),
                    ),
                    // Red Bar (Opponent)
                    AnimatedFlexible(
                      flex: (score.opponentRatio * 100).toInt().clamp(5, 95),
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AnimatedFlexible extends StatelessWidget {
  final int flex;
  final Widget child;

  const AnimatedFlexible({
    super.key,
    required this.flex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      child: child,
    );
  }
}
