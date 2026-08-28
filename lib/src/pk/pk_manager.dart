import 'dart:async';
import '../models/pk_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';

/// Manages Host PK Battles: requesting battles across rooms, accepting/rejecting,
/// subscribing to cross-room remote host WebRTC tracks, and streaming timer/score ticks.
class PKManager {
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  final _pkTimerController = StreamController<PKTimerTick>.broadcast();
  final _pkScoreController = StreamController<PKScoreUpdate>.broadcast();

  PKManager({
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
  })  : _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState {
    _bindStreams();
  }

  WebRTCManager get webRTCManager => _webRTCManager;
  Stream<PKTimerTick> get onPKTimerTick => _pkTimerController.stream;
  Stream<PKScoreUpdate> get onPKScoreUpdated => _pkScoreController.stream;

  void _bindStreams() {
    _signalingClient.onMessage.listen((msg) {
      switch (msg.event) {
        case SignalingEvents.pkStart:
          if (msg.payload is Map<String, dynamic>) {
            final battle = PKBattleInfo.fromJson(msg.payload as Map<String, dynamic>);
            _roomState.updatePKBattle(battle);
          }
          break;

        case SignalingEvents.pkScoreUpdate:
          if (msg.payload is Map<String, dynamic>) {
            final scoreUpdate = PKScoreUpdate.fromJson(msg.payload as Map<String, dynamic>);
            _pkScoreController.add(scoreUpdate);
            _roomState.updatePKScore(scoreUpdate);
          }
          break;

        case SignalingEvents.pkTimerTick:
          if (msg.payload is Map<String, dynamic>) {
            final timerTick = PKTimerTick.fromJson(msg.payload as Map<String, dynamic>);
            _pkTimerController.add(timerTick);
            _roomState.updatePKTimer(timerTick);
          }
          break;

        case SignalingEvents.pkEnd:
          _roomState.endPKBattle();
          break;
      }
    });
  }

  /// Sends a PK battle challenge to an opponent host in [targetRoomId].
  void sendPKRequest({
    required String targetRoomId,
    required String targetHostId,
    int durationSeconds = 300,
  }) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.pkRequest,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      targetUser: targetHostId,
      payload: {
        'target_room_id': targetRoomId,
        'target_host_id': targetHostId,
        'duration_seconds': durationSeconds,
      },
    ));
  }

  /// Accepts an incoming PK battle request.
  void acceptPKRequest(String battleId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.pkAccept,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      payload: {
        'battle_id': battleId,
      },
    ));
  }

  /// Rejects an incoming PK battle request.
  void rejectPKRequest(String battleId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.pkReject,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      payload: {
        'battle_id': battleId,
      },
    ));
  }

  /// Terminates the ongoing PK battle.
  void endPK(String battleId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.pkEnd,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      payload: {
        'battle_id': battleId,
      },
    ));

    _roomState.endPKBattle();
  }

  /// Disposes internal controllers.
  Future<void> dispose() async {
    await _pkTimerController.close();
    await _pkScoreController.close();
  }
}
