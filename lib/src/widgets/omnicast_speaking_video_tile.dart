import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/audio_level_detector.dart';

/// Interactive video tile with active speaking pulsating aura, decibel equalizer animation,
/// and camera-off avatar placeholder.
class OmniCastSpeakingVideoTile extends StatelessWidget {
  final String userId;
  final String trackId;
  final String userName;
  final String? avatarUrl;
  final RTCVideoRenderer? renderer;
  final bool isCameraEnabled;
  final bool isMicMuted;
  final AudioLevelDetector audioDetector;
  final VoidCallback? onTap;

  /// Whether to mirror the video rendering.
  /// If null (default), only mirrors local camera (`userId == 'local'`), never remote streams.
  final bool? mirror;

  const OmniCastSpeakingVideoTile({
    super.key,
    required this.userId,
    required this.trackId,
    required this.userName,
    this.avatarUrl,
    required this.renderer,
    this.isCameraEnabled = true,
    this.isMicMuted = false,
    this.mirror,
    required this.audioDetector,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMirror = mirror ?? (userId == 'local' || trackId == 'local');

    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder<Map<String, double>>(
        valueListenable: audioDetector.audioLevelsNotifier,
        builder: (context, levels, child) {
          final level = isMicMuted ? 0.0 : (levels[trackId] ?? levels[userId] ?? 0.0);
          final isSpeaking = level > 0.04;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSpeaking ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.08),
                width: isSpeaking ? 2.5 : 1.0,
              ),
              boxShadow: isSpeaking
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: (level * 2.5).clamp(0.3, 0.8)),
                        blurRadius: 10 + (level * 14),
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 1. Live Video View or Avatar Placeholder
                if (isCameraEnabled && renderer != null && renderer!.textureId != null)
                  SizedBox.expand(
                    child: RTCVideoView(
                      renderer!,
                      mirror: effectiveMirror,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  )
                else
                  _buildAvatarPlaceholder(),

                // 2. User Info & Active Speaking Waveform Badge (Bottom Left)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSpeaking) ...[
                          _SpeakingWaveformIcon(level: level),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Mic Muted Badge (Top Right)
                if (isMicMuted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_off,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            'Camera Off',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SpeakingWaveformIcon extends StatelessWidget {
  final double level;
  const _SpeakingWaveformIcon({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final barHeight = (6 + (i * 2) + (level * 14)).clamp(4.0, 16.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 2.5,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
