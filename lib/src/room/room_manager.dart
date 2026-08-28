import 'dart:async';
import '../models/room_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';

/// Manages room lifecycle: creating, joining, leaving, kicking users,
/// and synchronizing state on late join (`room_info_sync`).
class RoomManager {
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  RoomManager({
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
  })  : _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState;

  /// Creates and starts a new live broadcasting room as Host.
  Future<void> createRoom({
    required String roomId,
    required String userId,
    RoomOptions options = const RoomOptions(),
  }) async {
    _roomState.setSession(
      roomId: roomId,
      userId: userId,
      role: UserRole.host,
    );

    // Open media & add tracks
    if (options.enableAudio || options.enableVideo) {
      await _webRTCManager.mediaStreamManager.openUserMedia(
        audio: options.enableAudio,
        video: options.enableVideo,
      );
      await _webRTCManager.addLocalMediaTracks();
    }

    final offer = await _webRTCManager.createAndSetLocalOffer();

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.createRoom,
      roomId: roomId,
      userId: userId,
      payload: {
        'options': options.toJson(),
        'sdp': offer.sdp,
        'type': offer.type,
      },
    ));
  }

  /// Joins an existing live room as a Viewer.
  Future<void> joinRoom({
    required String roomId,
    required String userId,
  }) async {
    _roomState.setSession(
      roomId: roomId,
      userId: userId,
      role: UserRole.viewer,
    );

    await _webRTCManager.setupViewerTransceivers();
    final offer = await _webRTCManager.createAndSetLocalOffer();

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.joinRoom,
      roomId: roomId,
      userId: userId,
      payload: {
        'sdp': offer.sdp,
        'type': offer.type,
      },
    ));
  }

  /// Leaves the current room session and resets resources.
  Future<void> leaveRoom() async {
    if (_roomState.isInRoom) {
      _signalingClient.send(SignalingMessage(
        event: SignalingEvents.leaveRoom,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
      ));
    }

    await _webRTCManager.closePeerConnection();
    await _webRTCManager.mediaStreamManager.stopLocalMedia();
    _roomState.reset();
  }

  /// Host action: Kicks a specific user out of the room.
  void kickUser(String targetUserId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.kickUser,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      targetUser: targetUserId,
    ));
  }
}
