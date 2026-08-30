import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pk_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';

/// Manages Host vs Host PK Battles: requesting challenges, cross-room track subscriptions,
/// live score updates, battle countdown timer streams, and punishment phase transitions.
/// Exposes both pure [Stream]s and atomic [ValueNotifier]s for headless UI integration.
class PKManager {
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  // Granular atomic ValueNotifiers for headless UI composition
  final ValueNotifier<PKState> pkStateNotifier = ValueNotifier<PKState>(PKState.idle);
  final ValueNotifier<int> timerNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isPKActiveNotifier = ValueNotifier<bool>(false);

  // Pure Streams
  final _pkStartedController = StreamController<PKBattleInfo>.broadcast();
  final _pkTimerController = StreamController<PKTimerTick>.broadcast();
  final _pkScoreController = StreamController<PKScoreUpdate>.broadcast();
  final _pkEndedController = StreamController<String>.broadcast();
  final _pkRequestedController = StreamController<SignalingMessage>.broadcast();

  PKManager({
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
  })  : _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState {
    _bindStreams();
    _bindStateNotifiers();
  }

  WebRTCManager get webRTCManager => _webRTCManager;
  PKState get currentState => pkStateNotifier.value;
  bool get isPKActive => isPKActiveNotifier.value;

  // Streams
  Stream<PKBattleInfo> get onPKStarted => _pkStartedController.stream;
  Stream<PKTimerTick> get onPKTimerTick => _pkTimerController.stream;
  Stream<PKScoreUpdate> get onPKScoreUpdated => _pkScoreController.stream;
  Stream<String> get onPKEnded => _pkEndedController.stream;
  Stream<SignalingMessage> get onPKRequested => _pkRequestedController.stream;

  void _bindStateNotifiers() {
    _roomState.addListener(_syncPKNotifiers);
  }

  void _syncPKNotifiers() {
    final newState = _roomState.pkState;
    pkStateNotifier.value = newState;
    isPKActiveNotifier.value = newState.isPKActive;
    timerNotifier.value = newState.remainingSeconds;
  }

  void _bindStreams() {
    _signalingClient.onMessage.listen((msg) {
      switch (msg.event) {
        case SignalingEvents.pkRequest:
          _pkRequestedController.add(msg);
          break;

        case 'pk_started':
        case SignalingEvents.pkStart:
          if (msg.payload is Map<String, dynamic>) {
            final battle = PKBattleInfo.fromJson(msg.payload as Map<String, dynamic>);
            _roomState.updatePKBattle(battle);
            _pkStartedController.add(battle);

            // Subscribe to opponent host's tracks from foreign room
            _subscribeToOpponentTracks(battle.opponentRoomId, battle.opponentUserId);
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

        case 'room_mode_changed':
          if (msg.payload is Map<String, dynamic>) {
            final payload = msg.payload as Map<String, dynamic>;
            final mode = payload['mode'] as String? ?? 'solo';
            if (mode == 'pk') {
              final opponentId = payload['linked_host_id'] as String? ?? payload['opponent_user_id'] as String? ?? '';
              final opponentRoomId = payload['linked_room_id'] as String? ?? payload['opponent_room_id'] as String? ?? '';
              final battleId = payload['battle_id'] as String? ?? 'pk_${DateTime.now().millisecondsSinceEpoch}';

              final battle = PKBattleInfo(
                battleId: battleId,
                hostRoomId: _roomState.roomId ?? '',
                hostUserId: _roomState.userId ?? '',
                opponentRoomId: opponentRoomId,
                opponentUserId: opponentId,
                status: PKStatus.inProgress,
                hostScore: (payload['host_score'] as num?)?.toInt() ?? 0,
                opponentScore: (payload['opponent_score'] as num?)?.toInt() ?? 0,
                durationSeconds: (payload['duration_seconds'] as num?)?.toInt() ?? 300,
                remainingSeconds: (payload['remaining_seconds'] as num?)?.toInt() ?? 300,
                startedAt: DateTime.now(),
              );
              _roomState.updatePKBattle(battle);
              _pkStartedController.add(battle);
              if (opponentRoomId.isNotEmpty && opponentId.isNotEmpty) {
                _subscribeToOpponentTracks(opponentRoomId, opponentId);
              }
            } else {
              _roomState.endPKBattle();
              _pkEndedController.add('room_mode_solo');
            }
          }
          break;

        case 'pk_ended':
        case SignalingEvents.pkEnd:
          final battleId = msg.payload is Map
              ? (msg.payload['battle_id'] as String? ?? '')
              : msg.payload.toString();
          _roomState.endPKBattle();
          _pkEndedController.add(battleId);
          break;
      }
    });
  }

  /// Sends a cross-room PK battle challenge to an opponent host.
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

  /// Accepts an incoming PK battle challenge and notifies the SFU engine.
  void acceptPKRequest(
    String battleId, {
    String? opponentRoomId,
    String? opponentHostId,
  }) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.pkAccept,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      payload: {
        'battle_id': battleId,
        'opponent_room_id': ?opponentRoomId,
        'opponent_host_id': ?opponentHostId,
      },
    ));

    if (opponentRoomId != null && opponentHostId != null) {
      _subscribeToOpponentTracks(opponentRoomId, opponentHostId);
    }
  }

  /// Rejects an incoming PK challenge.
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

  /// Terminates an ongoing PK battle.
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

  /// Signals the SFU engine to bridge and forward the opponent's cross-room WebRTC tracks.
  void _subscribeToOpponentTracks(String opponentRoomId, String opponentUserId) {
    debugPrint(
        '[PKManager] Subscribing to opponent tracks for room: $opponentRoomId, host: $opponentUserId');

    if (_roomState.isInRoom && _roomState.roomId != null && _roomState.userId != null) {
      _signalingClient.send(SignalingMessage(
        event: 'subscribe_cross_room',
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: opponentUserId,
        payload: {
          'source_room_id': opponentRoomId,
          'source_user_id': opponentUserId,
        },
      ));
    }

    // Register active remote user so renderers get initialized immediately
    _roomState.addActiveRemoteUser(opponentUserId);
  }

  /// Disposes internal controllers and notifiers.
  Future<void> dispose() async {
    _roomState.removeListener(_syncPKNotifiers);
    pkStateNotifier.dispose();
    timerNotifier.dispose();
    isPKActiveNotifier.dispose();

    await _pkStartedController.close();
    await _pkTimerController.close();
    await _pkScoreController.close();
    await _pkEndedController.close();
    await _pkRequestedController.close();
  }
}
