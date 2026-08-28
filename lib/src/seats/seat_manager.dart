import 'dart:async';
import '../models/room_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';

/// Manages stage seats, co-host invitations, seamless upgrades, stage demotions,
/// and main stage pinning.
class SeatManager {
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  SeatManager({
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
  })  : _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState;

  /// Host action: Invites a viewer to take a co-host seat on stage.
  void inviteToCoHost(String targetUserId, {int? seatIndex}) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.seatInvite,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      targetUser: targetUserId,
      payload: {
        'seat_index': seatIndex,
      },
    ));
  }

  /// Viewer action: Accepts a co-host invitation and triggers seamless upgrade.
  Future<void> acceptCoHostInvite({bool video = true, bool audio = true}) async {
    if (!_roomState.isInRoom) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.seatAccept,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
    ));

    await upgradeToCoHost(video: video, audio: audio);
  }

  /// Seamlessly upgrades the active user to a Co-Host without destroying [RTCPeerConnection].
  Future<void> upgradeToCoHost({bool video = true, bool audio = true}) async {
    if (!_roomState.isInRoom) {
      throw StateError('Cannot upgrade to co-host when not in a room');
    }

    final offer = await _webRTCManager.upgradeViewerToCoHost(
      video: video,
      audio: audio,
    );

    _roomState.updateRole(UserRole.coHost);

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.publish,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      payload: {
        'sdp': offer.sdp,
        'type': offer.type,
      },
    ));
  }

  /// Host action: Demotes a co-host back to a viewer seat without kicking them from the room.
  void demoteToViewer(String targetUserId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.seatKick,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      targetUser: targetUserId,
    ));
  }

  /// Host action: Pins a specific user to the main stage layout for all viewers.
  void pinToMainStage(String? targetUserId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.pinStage,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      payload: {
        'pinned_user_id': targetUserId,
      },
    ));

    _roomState.setPinnedStageUser(targetUserId);
  }
}
