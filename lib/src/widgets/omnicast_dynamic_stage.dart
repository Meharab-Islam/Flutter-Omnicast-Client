import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/omnicast_client.dart';
import '../models/seat_models.dart';
import '../models/room_models.dart';
import 'omnicast_speaking_video_tile.dart';

/// Represents a rendered slot on the dynamic stage.
class DynamicStageSlot {
  final int slotIndex;
  final bool isOccupied;
  final bool isMainSeat;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int? seatIndex;
  final bool isLocal;
  final bool isHost;
  final bool isMuted;
  final bool isCameraOff;
  final RTCVideoRenderer? renderer;

  const DynamicStageSlot({
    required this.slotIndex,
    required this.isOccupied,
    required this.isMainSeat,
    this.userId = '',
    this.displayName = '',
    this.avatarUrl,
    this.seatIndex,
    this.isLocal = false,
    this.isHost = false,
    this.isMuted = false,
    this.isCameraOff = false,
    this.renderer,
  });
}

/// Dynamic live streaming stage widget that automatically switches between
/// Fullscreen (when 1 participant is on stage) and a responsive 2x2 Grid
/// (when 2 or more participants are on stage), with Slot 0 dedicated as
/// the Main Seat.
///
/// Features:
/// - 1 person on stage: Fullscreen video view.
/// - 2 persons on stage: 2x2 grid occupying the first 2 slots (Slot 0 = Main Seat, Slot 1 = Co-Host).
/// - 3-4 persons: Occupies subsequent slots in the 2x2 grid.
/// - Host controls: Promote any co-host to Main Seat (Slot 0) or restore Host to Main Seat.
/// - Synchronized across all room participants via WebRTC signaling.
class OmniCastDynamicStage extends StatelessWidget {
  final OmniCastClient client;
  final bool mirrorLocal;
  final bool mirrorRemote;
  final EdgeInsetsGeometry padding;
  final void Function(DynamicStageSlot slot)? onSlotTap;

  const OmniCastDynamicStage({
    super.key,
    required this.client,
    this.mirrorLocal = true,
    this.mirrorRemote = false,
    this.padding = const EdgeInsets.fromLTRB(10, 80, 10, 80),
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        client.state,
        client.seats.activeSeatsNotifier,
        client.streamManager,
      ]),
      builder: (context, _) {
        final slots = _computeStageSlots();
        final occupiedCount = slots.where((s) => s.isOccupied).length;
        final localUserId = client.state.userId;
        final isLocalCoHost =
            !client.state.isHost &&
            (client.state.isCoHost ||
                client.seats.occupiedSeats.any((s) => s.userId == localUserId));

        // Fullscreen solo view is ONLY for when there is strictly 1 broadcaster (the Host)
        // AND the local user is NOT a co-host on stage!
        // A co-host must NEVER see solo view - they must see the 2x2 grid with Host in Slot 0
        // and themselves in Slot 1.
        if (occupiedCount <= 1 && !isLocalCoHost) {
          // 1 Person: Fullscreen Single Broadcaster View
          final singleSlot = slots.firstWhere(
            (s) => s.isOccupied,
            orElse: () => slots.first,
          );
          return _buildFullscreenSlot(context, singleSlot);
        } else {
          // 2-4 Persons: 2x2 Grid View
          return _build2x2Grid(context, slots);
        }
      },
    );
  }

  String _getUserDisplayName(String userId, {String fallback = 'User'}) {
    final viewer = client.state.viewers.cast<Participant?>().firstWhere(
      (p) => p?.userId == userId,
      orElse: () => null,
    );
    if (viewer != null &&
        viewer.displayName != null &&
        viewer.displayName!.isNotEmpty) {
      return viewer.displayName!;
    }
    if (userId == (client.state.hostId ?? 'host')) return 'Host';
    return fallback;
  }

  String? _getUserAvatarUrl(String userId) {
    final viewer = client.state.viewers.cast<Participant?>().firstWhere(
      (p) => p?.userId == userId,
      orElse: () => null,
    );
    return viewer?.avatarUrl;
  }

  /// Organizes the 4 stage slots such that Slot 0 is ALWAYS the Main Seat.
  /// Under no circumstances will a Co-Host appear in Slot 0 (not even on their own device)
  /// unless and until the Host explicitly promotes them to the Main Seat.
  List<DynamicStageSlot> _computeStageSlots() {
    final localUserId = client.state.userId;
    final isLocalHost = client.state.isHost;
    final hostId =
        client.state.hostId ?? (isLocalHost ? localUserId ?? 'host' : 'host');
    final pinnedUserId = client.state.pinnedStageUserId;

    // Retrieve all active co-host seats
    final occupiedSeats = client.seats.occupiedSeats
        .where((s) => s.userId != null && s.userId!.isNotEmpty)
        .toList();

    final isLocalCoHost =
        !isLocalHost &&
        (client.state.isCoHost ||
            occupiedSeats.any((s) => s.userId == localUserId));

    // Map of user IDs on stage
    final stageUsers = <String>{hostId};
    for (final seat in occupiedSeats) {
      if (seat.userId != null) stageUsers.add(seat.userId!);
    }
    if (isLocalCoHost && localUserId != null && localUserId.isNotEmpty) {
      stageUsers.add(localUserId);
    }

    // A Co-Host is in Main Seat ONLY IF:
    // Host explicitly promoted them, so pinnedUserId is non-empty, NOT hostId,
    // and pinnedUserId is a participant on stage.
    final bool isCoHostPromotedToMain =
        pinnedUserId != null &&
        pinnedUserId.isNotEmpty &&
        pinnedUserId != hostId &&
        !client.state.isHostInMainSeat &&
        stageUsers.contains(pinnedUserId);

    // 1. Identify Main Seat participant (Slot 0)
    final DynamicStageSlot mainSlot;
    if (isCoHostPromotedToMain) {
      // Co-host explicitly promoted to Main Seat by Host
      final coHostSeat = occupiedSeats.cast<StageSeat?>().firstWhere(
        (s) => s?.userId == pinnedUserId,
        orElse: () => null,
      );
      mainSlot = _createSlot(
        slotIndex: 0,
        isMainSeat: true,
        userId: pinnedUserId,
        displayName:
            coHostSeat?.user?.displayName ?? _getUserDisplayName(pinnedUserId),
        avatarUrl:
            coHostSeat?.user?.avatarUrl ?? _getUserAvatarUrl(pinnedUserId),
        seatIndex: coHostSeat?.seatIndex,
        isHost: false,
      );
    } else {
      // Host is in Main Seat (Slot 0)
      final hostDisplayName = _getUserDisplayName(hostId, fallback: 'Host');
      mainSlot = _createSlot(
        slotIndex: 0,
        isMainSeat: true,
        userId: hostId,
        displayName: hostDisplayName,
        avatarUrl: _getUserAvatarUrl(hostId),
        seatIndex: 0,
        isHost: true,
      );
    }

    // 2. Identify remaining stage participants for Slots 1, 2, 3
    final remainingParticipants = <DynamicStageSlot>[];

    // If host was demoted from slot 0 (because host promoted a co-host), host takes slot 1
    if (isCoHostPromotedToMain && mainSlot.userId != hostId) {
      final hostDisplayName = _getUserDisplayName(hostId, fallback: 'Host');
      remainingParticipants.add(
        _createSlot(
          slotIndex: 1,
          isMainSeat: false,
          userId: hostId,
          displayName: hostDisplayName,
          avatarUrl: _getUserAvatarUrl(hostId),
          seatIndex: 0,
          isHost: true,
        ),
      );
    }

    // If local user is a Co-Host and NOT in the main slot, ensure local user is in stage slots!
    // This provides instantaneous responsive UI on the co-host's device even before
    // server active_seats broadcast arrives.
    if (isLocalCoHost &&
        mainSlot.userId != localUserId &&
        localUserId != null &&
        localUserId.isNotEmpty) {
      final mySeat = occupiedSeats.cast<StageSeat?>().firstWhere(
        (s) => s?.userId == localUserId,
        orElse: () => null,
      );
      remainingParticipants.add(
        _createSlot(
          slotIndex: remainingParticipants.length + 1,
          isMainSeat: false,
          userId: localUserId,
          displayName:
              mySeat?.user?.displayName ??
              _getUserDisplayName(localUserId, fallback: 'You (Co-Host)'),
          avatarUrl: mySeat?.user?.avatarUrl ?? _getUserAvatarUrl(localUserId),
          seatIndex: mySeat?.seatIndex ?? 1,
          isHost: false,
        ),
      );
    }

    // Add all other occupied co-hosts
    for (final seat in occupiedSeats) {
      final uId = seat.userId!;
      if (uId == mainSlot.userId) continue;
      if (uId == hostId) continue;
      if (uId == localUserId) continue; // Already added above if local co-host

      remainingParticipants.add(
        _createSlot(
          slotIndex: remainingParticipants.length + 1,
          isMainSeat: false,
          userId: uId,
          displayName: seat.user?.displayName ?? _getUserDisplayName(uId),
          avatarUrl: seat.user?.avatarUrl ?? _getUserAvatarUrl(uId),
          seatIndex: seat.seatIndex,
          isHost: false,
        ),
      );
    }

    // Build the 4 slots of the 2x2 grid
    final result = <DynamicStageSlot>[mainSlot];

    for (int i = 0; i < 3; i++) {
      if (i < remainingParticipants.length) {
        final item = remainingParticipants[i];
        result.add(
          DynamicStageSlot(
            slotIndex: i + 1,
            isOccupied: true,
            isMainSeat: false,
            userId: item.userId,
            displayName: item.displayName,
            avatarUrl: item.avatarUrl,
            seatIndex: item.seatIndex,
            isLocal: item.isLocal,
            isHost: item.isHost,
            isMuted: item.isMuted,
            isCameraOff: item.isCameraOff,
            renderer: item.renderer,
          ),
        );
      } else {
        // Empty Slot
        result.add(
          DynamicStageSlot(
            slotIndex: i + 1,
            isOccupied: false,
            isMainSeat: false,
            seatIndex: i + 2,
          ),
        );
      }
    }

    return result;
  }

  DynamicStageSlot _createSlot({
    required int slotIndex,
    required bool isMainSeat,
    required String userId,
    required String displayName,
    String? avatarUrl,
    int? seatIndex,
    required bool isHost,
  }) {
    // isLocal is true ONLY if this slot matches the local user ID AND
    // if isHost is true, only if the current client is indeed the Host!
    final isLocal =
        (userId == client.state.userId) &&
        (isHost ? client.state.isHost : true);
    final isMuted = isLocal
        ? client.media.isMicrophoneMuted
        : (client.seats.isUserMuted(userId) ||
              client.state.isUserAudioMuted(userId));
    final RTCVideoRenderer? renderer;
    if (isLocal) {
      renderer = client.media.localRenderer;
    } else if (isHost) {
      renderer =
          client.media.getRenderer(userId) ??
          client.media.getRenderer('host') ??
          client.media.getRenderer(client.state.roomId);
    } else {
      renderer = client.media.getRenderer(userId);
    }

    final isCameraOff = isLocal
        ? !client.media.isCameraEnabled
        : (client.seats.isUserCameraOff(userId) ||
              client.state.isUserCameraOff(userId));

    // If active video frames or enabled video tracks exist on the renderer, prioritize showing video
    final hasActiveVideo = renderer != null &&
        (renderer.renderVideo ||
            (renderer.srcObject?.getVideoTracks().any((t) => t.enabled) ??
                false));
    final effectiveCameraOff = hasActiveVideo ? false : isCameraOff;

    return DynamicStageSlot(
      slotIndex: slotIndex,
      isOccupied: true,
      isMainSeat: isMainSeat,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      seatIndex: seatIndex,
      isLocal: isLocal,
      isHost: isHost,
      isMuted: isMuted,
      isCameraOff: effectiveCameraOff,
      renderer: renderer,
    );
  }

  /// Fullscreen view when only 1 person is on stage
  Widget _buildFullscreenSlot(BuildContext context, DynamicStageSlot slot) {
    return Stack(
      children: [
        Positioned.fill(
          child: OmniCastSpeakingVideoTile(
            userId: slot.userId,
            trackId: slot.userId,
            userName: slot.displayName,
            avatarUrl: slot.avatarUrl,
            renderer: slot.renderer,
            isCameraEnabled: !slot.isCameraOff,
            isMicMuted: slot.isMuted,
            mirror: slot.isLocal ? mirrorLocal : mirrorRemote,
            audioDetector: client.media.audioDetector,
            onTap: () => _handleSlotTap(context, slot),
          ),
        ),
        // Subtle badge overlay at top-left
        Positioned(top: 90, left: 16, child: _buildMainSeatBadge(isSolo: true)),
      ],
    );
  }

  /// 2x2 Grid View when 2 or more participants are on stage
  Widget _build2x2Grid(BuildContext context, List<DynamicStageSlot> slots) {
    return Center(
      child: Padding(
        padding: padding,
        child: AspectRatio(
          aspectRatio:
              0.95, // Clean balanced proportion for 2x2 grid in portrait
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final slot = slots[index];
              if (slot.isOccupied) {
                return _buildOccupiedTile(context, slot);
              } else {
                return _buildEmptyTile(context, slot);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOccupiedTile(BuildContext context, DynamicStageSlot slot) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: OmniCastSpeakingVideoTile(
              userId: slot.userId,
              trackId: slot.userId,
              userName: slot.displayName,
              avatarUrl: slot.avatarUrl,
              renderer: slot.renderer,
              isCameraEnabled: !slot.isCameraOff,
              isMicMuted: slot.isMuted,
              mirror: slot.isLocal ? mirrorLocal : mirrorRemote,
              audioDetector: client.media.audioDetector,
              onTap: () => _handleSlotTap(context, slot),
            ),
          ),
        ),

        // Glowing border for Main Seat (Slot 0)
        if (slot.isMainSeat)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),

        // Badge at Top Left
        Positioned(
          top: 6,
          left: 6,
          child: slot.isMainSeat
              ? _buildMainSeatBadge(isSolo: false)
              : _buildCoHostSlotBadge(slot.slotIndex),
        ),

        // Media Status (Mic Muted) at Top Right
        if (slot.isMuted)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_off_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyTile(BuildContext context, DynamicStageSlot slot) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleEmptySlotTap(context, slot),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Seat ${slot.slotIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainSeatBadge({required bool isSolo}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👑', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            isSolo ? 'HOST' : 'MAIN SEAT',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoHostSlotBadge(int slotIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Text(
        'CO-HOST $slotIndex',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleSlotTap(BuildContext context, DynamicStageSlot slot) {
    if (onSlotTap != null) {
      onSlotTap!(slot);
      return;
    }

    if (!client.state.isHost) {
      return;
    }

    // Host Management Bottom Sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2132),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final isHostMain = client.state.isHostInMainSeat;
        final isTargetHost = slot.userId == client.state.hostId;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C5CE7),
                    child: Text(
                      slot.displayName.isNotEmpty
                          ? slot.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    slot.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    slot.isMainSeat
                        ? '👑 Current Main Seat'
                        : 'Co-Host on Stage',
                    style: TextStyle(
                      color: slot.isMainSeat
                          ? const Color(0xFFFFD700)
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Divider(color: Colors.white12),

                // Promotion / Swap to Main Seat
                if (!slot.isMainSeat && !isTargetHost)
                  ListTile(
                    leading: const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFFD700),
                    ),
                    title: const Text(
                      'Set as Main Seat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Promote to primary stage speaker (Slot 0)',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      client.seats.setMainSeat(slot.userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${slot.displayName} is now in the Main Seat 👑',
                          ),
                          backgroundColor: const Color(0xFF6C5CE7),
                        ),
                      );
                    },
                  ),

                // Restore Host to Main Seat (if a Co-Host currently holds Main Seat)
                if (slot.isMainSeat && !isHostMain)
                  ListTile(
                    leading: const Icon(
                      Icons.replay_rounded,
                      color: Color(0xFFFFD700),
                    ),
                    title: const Text(
                      'Restore Host to Main Seat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Reclaim Main Seat (Slot 0) for Host',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      client.seats.restoreHostMainSeat();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Host restored to Main Seat 👑'),
                          backgroundColor: Color(0xFF6C5CE7),
                        ),
                      );
                    },
                  ),

                // Remove / Kick from Stage (only for co-hosts, not host)
                if (!isTargetHost)
                  ListTile(
                    leading: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Remove from Stage',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Demote co-host back to viewer',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      client.seats.kickSeat(
                        slot.seatIndex ?? 1,
                        targetUserId: slot.userId,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${slot.displayName} removed from stage',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleEmptySlotTap(BuildContext context, DynamicStageSlot slot) {
    if (client.state.isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${slot.slotIndex + 1} is available for guests'),
          backgroundColor: const Color(0xFF2D3436),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1E2132),
          title: const Text(
            'Join Stage?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Request to take Seat ${slot.slotIndex + 1} as a co-host?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                client.seats.requestSeat(
                  seatIndex: slot.seatIndex ?? slot.slotIndex + 1,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Seat request sent to host!'),
                    backgroundColor: Color(0xFF6C5CE7),
                  ),
                );
              },
              child: const Text('Request Seat'),
            ),
          ],
        ),
      );
    }
  }
}
