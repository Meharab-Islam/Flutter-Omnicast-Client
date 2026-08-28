import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_stream_manager.dart';
import '../models/pk_models.dart';
import 'omnicast_video_view.dart';
import 'pk_score_progress_bar.dart';

/// A production-ready, split-screen video battle stage widget for live Host PKs.
///
/// Automatically embeds two [OmniCastVideoView] instances for the host and opponent,
/// along with an animated [PKScoreProgressBar] and customizable participant banners.
class OmniCastPKBattleView extends StatelessWidget {
  /// Media manager maintaining WebRTC renderers.
  final MediaStreamManager mediaStreamManager;

  /// User ID of the primary room host (left/top pane).
  final String hostUserId;

  /// User ID of the challenged opponent host (right/bottom pane).
  final String opponentUserId;

  /// Active [PKState] snapshot.
  final PKState? pkState;

  /// Display name for the primary host.
  final String hostDisplayName;

  /// Display name for the opponent host.
  final String opponentDisplayName;

  /// Split layout direction. Defaults to [Axis.horizontal] (side-by-side).
  final Axis splitAxis;

  /// Spacing divider between the two video panes.
  final double spacing;

  /// Video scaling fit.
  final RTCVideoViewObjectFit objectFit;

  /// Whether to render the animated top score progress bar.
  final bool showProgressBar;

  /// Optional custom placeholders for both video panes.
  final Widget? hostPlaceholder;
  final Widget? opponentPlaceholder;

  const OmniCastPKBattleView({
    super.key,
    required this.mediaStreamManager,
    required this.hostUserId,
    required this.opponentUserId,
    this.pkState,
    this.hostDisplayName = 'Host',
    this.opponentDisplayName = 'Opponent',
    this.splitAxis = Axis.horizontal,
    this.spacing = 2.0,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    this.showProgressBar = true,
    this.hostPlaceholder,
    this.opponentPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final activePK = pkState ?? PKState.idle;

    final hostPane = _buildVideoPane(
      userId: hostUserId,
      displayName: hostDisplayName,
      isHost: true,
      placeholder: hostPlaceholder,
      isWinning: activePK.isWinning,
    );

    final opponentPane = _buildVideoPane(
      userId: opponentUserId,
      displayName: activePK.opponentDisplayName ?? opponentDisplayName,
      isHost: false,
      placeholder: opponentPlaceholder,
      isWinning: activePK.isLosing,
    );

    return Stack(
      children: [
        // Split-Screen Video Stage
        splitAxis == Axis.horizontal
            ? Row(
                children: [
                  Expanded(child: hostPane),
                  SizedBox(width: spacing),
                  Expanded(child: opponentPane),
                ],
              )
            : Column(
                children: [
                  Expanded(child: hostPane),
                  SizedBox(height: spacing),
                  Expanded(child: opponentPane),
                ],
              ),

        // Floating PK Score Bar Overlay
        if (showProgressBar)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: PKScoreProgressBar(pkState: activePK),
          ),
      ],
    );
  }

  Widget _buildVideoPane({
    required String userId,
    required String displayName,
    required bool isHost,
    required bool isWinning,
    Widget? placeholder,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Renderer
        OmniCastVideoView(
          mediaStreamManager: mediaStreamManager,
          userId: userId,
          objectFit: objectFit,
          placeholder: placeholder,
        ),

        // Gradient Bottom Vignette
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 60,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
        ),

        // Participant Badge & Winning Indicator
        Positioned(
          left: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isWinning ? Colors.amberAccent : Colors.white24,
                width: isWinning ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isWinning) ...[
                  const Icon(Icons.emoji_events, size: 13, color: Colors.amberAccent),
                  const SizedBox(width: 4),
                ],
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
