import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';
import 'omnicast_dynamic_stage.dart';
import 'omnicast_live_header.dart';
import 'omnicast_live_chat.dart';
import 'omnicast_live_bottom_bar.dart';
import 'omnicast_flying_hearts_overlay.dart';
import 'gift_overlay_manager.dart';

/// Complete, Turnkey, Plug-and-Play Interactive Live Streaming Room Widget.
///
/// Simply provide the initialized [OmniCastClient] and this widget will render
/// the full live streaming experience including:
/// - Responsive Video Stage (Fullscreen Solo, 2x2 Multi-Guest Grid, Stage Grid)
/// - Top Status Header with Host Profile, Duration Timer, Viewers Count Pill & Exit Button
/// - Real-Time Chat & Join/Leave/Gift Overlay
/// - Bottom Interactive Action Bar (Mic, Cam, Flip, Gifts, Co-Host Stage Requests, Hearts)
/// - Dynamic Floating Hearts & Full-Screen Gift Overlay Animations
///
/// Example:
/// ```dart
/// OmniCastLiveRoom(
///   client: omnicastClient,
///   hostDisplayName: 'Alex Rivera',
///   onClosePressed: () => Navigator.pop(context),
/// )
/// ```
class OmniCastLiveRoom extends StatelessWidget {
  final OmniCastClient client;
  final String? hostDisplayName;
  final String? hostAvatarUrl;
  final VoidCallback? onClosePressed;
  final VoidCallback? onFollowPressed;
  final bool isFollowing;
  final bool showFollowButton;
  final bool showChat;
  final bool showHeader;
  final bool showBottomBar;
  final bool showFloatingHearts;
  final bool showGiftAnimations;
  final Widget? customStage;

  const OmniCastLiveRoom({
    super.key,
    required this.client,
    this.hostDisplayName,
    this.hostAvatarUrl,
    this.onClosePressed,
    this.onFollowPressed,
    this.isFollowing = false,
    this.showFollowButton = false,
    this.showChat = true,
    this.showHeader = true,
    this.showBottomBar = true,
    this.showFloatingHearts = true,
    this.showGiftAnimations = true,
    this.customStage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. WebRTC Video Stage (Fullscreen / Grid)
          widgetStage(context),

          // 2. Flying Hearts Reaction Overlay
          if (showFloatingHearts)
            Positioned(
              right: 16,
              bottom: 80,
              width: 80,
              height: 260,
              child: OmniCastFlyingHeartsOverlay(
                reactionStream: client.dataChannel.onReactionReceived,
              ),
            ),

          // 3. Fullscreen Gift Animation Overlay
          if (showGiftAnimations)
            GiftOverlayManager(
              giftStream: client.interaction.giftStream,
              child: const SizedBox.expand(),
            ),

          // 4. Live Header Bar (Top)
          if (showHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OmniCastLiveHeader(
                client: client,
                hostDisplayName: hostDisplayName,
                hostAvatarUrl: hostAvatarUrl,
                onClosePressed: onClosePressed,
                onFollowPressed: onFollowPressed,
                isFollowing: isFollowing,
                showFollowButton: showFollowButton,
              ),
            ),

          // 5. Live Interactive Chat (Bottom Left)
          if (showChat)
            Positioned(
              left: 0,
              bottom: showBottomBar ? 60 : 16,
              child: OmniCastLiveChat(
                client: client,
              ),
            ),

          // 6. Live Interactive Action Bar (Bottom)
          if (showBottomBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: OmniCastLiveBottomBar(
                client: client,
              ),
            ),
        ],
      ),
    );
  }

  Widget widgetStage(BuildContext context) {
    if (customStage != null) return customStage!;
    return OmniCastDynamicStage(
      client: client,
      padding: EdgeInsets.only(
        top: showHeader ? 80 : 0,
        bottom: showBottomBar ? 70 : 0,
      ),
    );
  }
}
