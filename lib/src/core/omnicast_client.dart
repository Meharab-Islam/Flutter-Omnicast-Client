import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/omnicast_api.dart';
import '../datachannel/data_channel_manager.dart';
import '../interaction/interaction_manager.dart';
import '../media/media_controller.dart';
import '../media/media_stream_manager.dart';
import '../media/global_media_config.dart';
import '../models/interaction_models.dart';
import '../models/pk_models.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';
import '../models/signaling_message.dart';
import '../pk/pk_manager.dart';
import '../room/room_manager.dart';
import '../seats/seat_manager.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../utils/omnicast_logger.dart';
import 'omnicast_config.dart';

/// The central production SDK Facade for OmniCast Live & WebRTC SFU engine.
///
/// Exposes modular sub-managers:
/// - [api]: [OmniCastApi] (getLiveRooms, REST endpoints)
/// - [room]: [RoomManager] (createRoom, joinRoom, leaveRoom, kickUser)
/// - [media]: [MediaController] (mute/camera toggles, simulcast layer, dynacast)
/// - [seats]: [SeatManager] (co-host invite/accept/upgrade, stage pinning, demotion)
/// - [interaction]: [InteractionManager] (chats, gifts, balance streams)
/// - [pk]: [PKManager] (host PK battles, timer ticks, score updates)
/// - [dataChannel]: [DataChannelManager] (zero-latency in-room events)
/// - [state]: [RoomState] (reactive global state container)
class OmniCastClient {
  /// Global singleton accessor for the initialized [OmniCastClient] instance.
  static OmniCastClient? instance;

  final OmniCastConfig config;
  final GlobalMediaConfig mediaConfig;
  final SignalingClient _signalingClient;
  final MediaStreamManager _mediaStreamManager;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  // Sub-module managers
  late final OmniCastApi _api;
  late final RoomManager _roomManager;
  late final MediaController _mediaController;
  late final SeatManager _seatManager;
  late final InteractionManager _interactionManager;
  late final PKManager _pkManager;
  late final DataChannelManager _dataChannelManager;

  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;
  final ValueNotifier<List<RoomModel>> _liveRoomsNotifier =
      ValueNotifier<List<RoomModel>>([]);
  Timer? _roomsWatchTimer;

  /// Real-time live rooms notifier for UI builders and reactive listeners.
  ValueNotifier<List<RoomModel>> get liveRoomsNotifier => _liveRoomsNotifier;

  factory OmniCastClient.custom({
    required OmniCastConfig config,
    GlobalMediaConfig mediaConfig = const GlobalMediaConfig(),
    SignalingClient? signalingClient,
    MediaStreamManager? mediaStreamManager,
    WebRTCManager? webRTCManager,
    RoomState? roomState,
  }) {
    final streamManager = mediaStreamManager ?? MediaStreamManager();
    final signaling =
        signalingClient ??
        SignalingClient(heartbeatInterval: config.heartbeatInterval);
    final state = roomState ?? RoomState();
    final rtcManager =
        webRTCManager ??
        WebRTCManager(
          mediaStreamManager: streamManager,
          configuration: {
            'iceServers': config.iceServers,
            'sdpSemantics': 'unified-plan',
          },
        );

    return OmniCastClient._raw(
      config: config,
      mediaConfig: mediaConfig,
      signalingClient: signaling,
      mediaStreamManager: streamManager,
      webRTCManager: rtcManager,
      roomState: state,
    );
  }

  OmniCastClient._raw({
    required this.config,
    this.mediaConfig = const GlobalMediaConfig(),
    required SignalingClient signalingClient,
    required MediaStreamManager mediaStreamManager,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
  })  : _mediaStreamManager = mediaStreamManager,
        _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState {
    instance = this;
    _initSubManagers();
    _bindInternalEventListeners();
  }

  factory OmniCastClient._({
    required OmniCastConfig config,
    GlobalMediaConfig mediaConfig = const GlobalMediaConfig(),
    SignalingClient? signalingClient,
    MediaStreamManager? mediaStreamManager,
    WebRTCManager? webRTCManager,
    RoomState? roomState,
  }) => OmniCastClient.custom(
        config: config,
        mediaConfig: mediaConfig,
        signalingClient: signalingClient,
        mediaStreamManager: mediaStreamManager,
        webRTCManager: webRTCManager,
        roomState: roomState,
      );

  /// Master toggle for console logs across the SDK (WebRTC, signaling, media).
  static bool get enableLogging => OmniCastLogger.enableLogging;
  static set enableLogging(bool value) => OmniCastLogger.enableLogging = value;

  /// Initializes the [OmniCastClient] SDK using server credentials, SFU host URL, and media configuration.
  ///
  /// Developers can simply provide their server domain (e.g. `testlive.lolipoplive.top`) and credentials:
  /// ```dart
  /// await OmniCastClient.init(
  ///   serverUrl: 'testlive.lolipoplive.top',
  ///   apiKey: 'dev_api_key_123',
  ///   apiSecret: 'my_secret_key_456',
  ///   enableLogging: false, // Turn on/off console logs
  /// );
  /// ```
  static Future<OmniCastClient> init({
    String? serverUrl,
    String? hostUrl,
    String? apiUrl,
    String? apiKey,
    String? apiSecret,
    String? jwtSecret,
    GlobalMediaConfig? mediaConfig,
    String? token,
    bool autoConnect = true,
    bool enableLogging = false,
    bool autoWatchRooms = false,
    Duration watchRoomsInterval = const Duration(seconds: 5),
    List<Map<String, dynamic>>? iceServers,
    Duration heartbeatInterval = const Duration(seconds: 15),
    Duration reconnectDelay = const Duration(seconds: 3),
    int maxReconnectAttempts = 5,
    bool? isSecure,
    String wsPath = '/ws',
    String apiPath = '/api',
  }) async {
    OmniCastLogger.enableLogging = enableLogging;

    final config = OmniCastConfig.fromServer(
      serverUrl: serverUrl,
      hostUrl: hostUrl,
      apiUrl: apiUrl,
      apiKey: apiKey,
      apiSecret: apiSecret,
      jwtSecret: jwtSecret,
      enableLogging: enableLogging,
      iceServers:
          iceServers ??
          const [
            {'urls': 'stun:stun.l.google.com:19302'},
            {'urls': 'stun:stun1.l.google.com:19302'},
          ],
      heartbeatInterval: heartbeatInterval,
      reconnectDelay: reconnectDelay,
      maxReconnectAttempts: maxReconnectAttempts,
      isSecure: isSecure,
      wsPath: wsPath,
      apiPath: apiPath,
    );

    final client = OmniCastClient._(
      config: config,
      mediaConfig: mediaConfig ?? const GlobalMediaConfig(),
    );
    instance = client;

    if (autoWatchRooms) {
      client.startWatchingRooms(interval: watchRoomsInterval);
    }

    if (autoConnect) {
      try {
        await client._signalingClient.connect(
          wsUrl: config.hostUrl,
          token: token,
        );
      } catch (e) {
        OmniCastLogger.error(
          '[OmniCastClient] Initial connection deferred or offline: $e',
        );
      }
    }
    return client;
  }

  /// Starts polling the live rooms endpoint at the specified interval and updating [liveRoomsNotifier].
  void startWatchingRooms({Duration interval = const Duration(seconds: 5)}) {
    stopWatchingRooms();
    updateLiveRooms();
    _roomsWatchTimer = Timer.periodic(interval, (_) => updateLiveRooms());
  }

  /// Stops periodic room list watching.
  void stopWatchingRooms() {
    _roomsWatchTimer?.cancel();
    _roomsWatchTimer = null;
  }

  /// Fetches the latest live rooms and updates [liveRoomsNotifier].
  Future<List<RoomModel>> updateLiveRooms() async {
    if (_isDisposed) return [];
    try {
      final rooms = await _api.getLiveRooms();
      if (!_isDisposed) {
        _liveRoomsNotifier.value = rooms;
      }
      return rooms;
    } catch (e) {
      OmniCastLogger.error('[OmniCastClient] Error updating live rooms: $e');
      return _liveRoomsNotifier.value;
    }
  }

  /// Creates and starts a new live broadcasting room as Host.
  /// Automatically generates JWT auth token from credentials configured at SDK initialization.
  Future<void> createRoom({
    required String roomId,
    required String userId,
    String? token,
    RoomOptions options = const RoomOptions(),
    Map<String, dynamic>? metadata,
  }) => _roomManager.createRoom(
    roomId: roomId,
    userId: userId,
    token: token,
    options: options,
    metadata: metadata,
  );

  /// Joins an existing broadcasting room as a Viewer.
  /// Automatically generates JWT auth token from credentials configured at SDK initialization.
  Future<void> joinRoom({
    required String roomId,
    required String userId,
    String? token,
    Map<String, dynamic>? metadata,
  }) => _roomManager.joinRoom(
    roomId: roomId,
    userId: userId,
    token: token,
    metadata: metadata,
  );

  /// Leaves the current room session, tears down peer connections, and stops local media tracks.
  Future<void> leaveRoom() => _roomManager.leaveRoom();

  /// Host action: Explicitly ends and terminates the live broadcast room, notifying all viewers.
  Future<void> closeRoom() => _roomManager.closeRoom();

  void _initSubManagers() {
    _api = OmniCastApi(config: config);

    _roomManager = RoomManager(
      signalingClient: _signalingClient,
      webRTCManager: _webRTCManager,
      roomState: _roomState,
      config: config,
    );

    _mediaController = MediaController(
      mediaStreamManager: _mediaStreamManager,
      signalingClient: _signalingClient,
      webRTCManager: _webRTCManager,
      roomState: _roomState,
      globalConfig: mediaConfig,
      config: config,
    );

    _seatManager = SeatManager(
      signalingClient: _signalingClient,
      webRTCManager: _webRTCManager,
      roomState: _roomState,
    );

    _interactionManager = InteractionManager(
      signalingClient: _signalingClient,
      roomState: _roomState,
    );

    _pkManager = PKManager(
      signalingClient: _signalingClient,
      webRTCManager: _webRTCManager,
      roomState: _roomState,
    );

    _dataChannelManager = DataChannelManager(
      webRTCManager: _webRTCManager,
      roomState: _roomState,
    );
  }

  // Sub-module Getters
  OmniCastApi get api => _api;
  RoomManager get room => _roomManager;
  MediaController get media => _mediaController;
  SeatManager get seats => _seatManager;
  InteractionManager get interaction => _interactionManager;
  PKManager get pk => _pkManager;
  DataChannelManager get dataChannel => _dataChannelManager;
  RoomState get state => _roomState;
  MediaStreamManager get streamManager => _mediaStreamManager;
  MediaStreamManager get mediaStreamManager => _mediaStreamManager;
  String? get userId => _roomState.userId;
  String? get roomId => _roomState.roomId;
  String? get hostId => _roomState.hostId;
  SignalingClient get signaling => _signalingClient;
  SignalingClient get signalingClient => _signalingClient;
  WebRTCManager get webrtc => _webRTCManager;
  RTCVideoRenderer? get localRenderer => _mediaController.localRenderer;
  RTCVideoRenderer? getRenderer(String? userId) =>
      _mediaController.getRenderer(userId);

  // Real-time Global Room & Media Event Streams
  Stream<RoomModel> get onRoomCreated => _signalingClient.onRoomCreated;
  Stream<String> get onRoomClosed => _signalingClient.onRoomClosed;
  Stream<String> get onRoomClosedByHost => _roomManager.onRoomClosedByHost;
  Stream<KickedEvent> get onKickedFromRoom => _roomManager.onKickedFromRoom;
  Stream<String> get onUserKicked => _roomManager.onUserKicked;
  Stream<OmniCastParticipant> get onParticipantJoined =>
      _roomManager.onParticipantJoined;
  Stream<String> get onParticipantLeft => _roomManager.onParticipantLeft;
  Stream<OmniCastParticipant> get onUserJoined => _roomManager.onUserJoined;
  Stream<String> get onUserLeft => _roomManager.onUserLeft;
  Stream<SignalingMessage> get onMediaStateChanged =>
      _signalingClient.onMediaStateChanged;

  // Real-time Reactive ValueListenable Notifiers for UI Composition
  ValueNotifier<List<OmniCastParticipant>> get viewersNotifier =>
      _roomManager.activeViewersList;
  ValueNotifier<List<OmniCastParticipant>> get activeViewersList =>
      _roomManager.activeViewersList;
  ValueNotifier<int> get viewerCountNotifier => _roomManager.totalViewerCount;
  ValueNotifier<int> get totalViewerCount => _roomManager.totalViewerCount;
  ValueNotifier<bool> get showJoinMessagesNotifier =>
      _roomState.showJoinMessagesNotifier;
  bool get showJoinMessages => _roomState.showJoinMessages;
  set showJoinMessages(bool value) => _roomState.showJoinMessages = value;

  /// Host action: Kicks/ejects a participant out of the live room.
  void kickUser(String targetUserId, {String? reason}) =>
      _roomManager.kickUser(targetUserId, reason: reason);

  /// Host action alias: Kicks/ejects a participant out of the live room.
  void kickParticipant(String targetUserId, {String? reason}) =>
      _roomManager.kickUser(targetUserId, reason: reason);

  // Co-Host & Stage Seat Action Facades
  /// Viewer action: Requests to join the broadcast stage as a Co-Host.
  void requestCoHost({int? seatIndex}) =>
      _seatManager.requestSeat(seatIndex: seatIndex);

  /// Viewer action: Cancels their own pending co-host seat request.
  void cancelCoHostRequest() => _seatManager.cancelSeatRequest();

  /// Host action: Accepts a viewer's co-host request and brings them onto the live stage.
  void acceptCoHostRequest(String userId, {int? seatIndex}) =>
      _seatManager.acceptSeatRequest(userId, seatIndex: seatIndex);

  /// Host action: Rejects a viewer's co-host request.
  void rejectCoHostRequest(String userId) =>
      _seatManager.rejectSeatRequest(userId);

  /// Host action: Invites a specific viewer to take a co-host seat on stage.
  void inviteToCoHost(String targetUserId, {int? seatIndex}) =>
      _seatManager.inviteToCoHost(targetUserId, seatIndex: seatIndex);

  /// Viewer action: Accepts a co-host invitation from the host.
  Future<void> acceptCoHostInvite({
    String? inviteId,
    bool video = true,
    bool audio = true,
  }) => _seatManager.acceptCoHostInvite(
    inviteId: inviteId,
    video: video,
    audio: audio,
  );

  /// Viewer action: Rejects a co-host invitation from the host.
  void rejectCoHostInvite({String? inviteId}) =>
      _seatManager.rejectCoHostInvite(inviteId: inviteId);

  /// Co-Host action: Leaves the stage seat and returns to viewer mode.
  Future<void> leaveCoHostSeat() => _seatManager.leaveSeat();

  /// Host action: Demotes a co-host back to a viewer seat without kicking them.
  void demoteCoHost(String userId) => _seatManager.demoteToViewer(userId);

  // Co-Host Streams
  /// Stream emitting when a viewer requests to become a co-host (Host listens to this).
  Stream<SeatRequest> get onCoHostRequested =>
      _seatManager.onSeatRequestReceived;

  /// Stream emitting when the host invites the viewer to co-host (Viewer listens to this).
  Stream<CoHostInvite> get onCoHostInviteReceived =>
      _seatManager.onSeatInviteReceived;

  /// Stream emitting when the viewer's co-host request is accepted.
  Stream<SignalingMessage> get onCoHostAccepted => _seatManager.onSeatAccepted;

  /// Stream emitting when the viewer's co-host request is rejected.
  Stream<SignalingMessage> get onCoHostRejected => _seatManager.onSeatRejected;

  /// Stream emitting when any stage seat is updated.
  Stream<StageSeat> get onSeatUpdated => _seatManager.onSeatUpdated;

  /// Stream emitting when a participant is kicked/demoted from a seat.
  Stream<SignalingMessage> get onSeatKicked => _signalingClient.onSeatKick;

  /// Host action: Kicks/demotes a seat occupant back to a viewer.
  void kickSeat(dynamic seat, {String? targetUserId}) =>
      _seatManager.kickSeat(seat, targetUserId: targetUserId);

  // Interaction Facades
  /// Stream emitting incoming chat messages.
  Stream<ChatMessage> get onChat => _interactionManager.chatStream;

  /// Stream emitting incoming gift events.
  Stream<GiftEvent> get onGift => _interactionManager.giftStream;

  /// Sends a real-time chat message.
  void sendChat(String text) => _interactionManager.sendChat(text);

  /// Sends a gift to the host or co-host, with optional [giftSoundUrl] and [giftIconUrl].
  void sendGift({
    required String giftId,
    required int amount,
    String? targetUserId,
    String giftName = 'Gift',
    String? giftIconUrl,
    String? giftSoundUrl,
    int coinValue = 0,
  }) => _interactionManager.sendGift(
    giftId: giftId,
    amount: amount,
    targetUserId: targetUserId,
    giftName: giftName,
    giftIconUrl: giftIconUrl,
    giftSoundUrl: giftSoundUrl,
    coinValue: coinValue,
  );

  // PK Battle Facades
  Stream<PKBattleInfo> get onPKStarted => _pkManager.onPKStarted;
  Stream<PKScoreUpdate> get onPKScoreUpdated => _pkManager.onPKScoreUpdated;
  Stream<PKTimerTick> get onPKTimerTick => _pkManager.onPKTimerTick;
  Stream<String> get onPKEnded => _pkManager.onPKEnded;

  /// Sends a PK challenge request to another host.
  void sendPKRequest({
    String? targetUserId,
    String? targetHostId,
    String? targetRoomId,
    int duration = 180,
    int durationSeconds = 180,
  }) => _pkManager.sendPKRequest(
    targetHostId: targetHostId ?? targetUserId,
    targetRoomId: targetRoomId ?? targetHostId ?? targetUserId,
    durationSeconds: durationSeconds != 180 ? durationSeconds : duration,
  );

  /// Ends the active PK battle.
  void endPK([String? battleId]) => _pkManager.endPK(battleId ?? '');

  // Media Control Facades
  /// Mutes or unmutes the local microphone.
  void setMicrophoneMuted(bool muted) =>
      _mediaController.setMicrophoneMuted(muted);

  /// Enables or disables the local camera feed.
  void setCameraEnabled(bool enabled) =>
      _mediaController.setCameraEnabled(enabled);

  /// Toggles front and back cameras.
  Future<void> switchCamera() => _mediaController.switchCamera();

  /// Switches active simulcast layer ('f', 'h', 'q').
  void setSimulcastLayer(String layer) =>
      _mediaController.setSimulcastLayer(layer);

  /// Manually triggers an ICE restart on the active room session.
  Future<void> requestICERestart() => _roomManager.requestICERestart();

  /// Convenience alias for updating live rooms.
  Future<List<RoomModel>> refreshLiveRooms() => updateLiveRooms();

  /// Built-in hardware permission requester for Camera and Microphone.
  ///
  /// Prompts Android and iOS to grant microphone/camera permissions without external plugins.
  Future<bool> requestPermissions({
    bool camera = true,
    bool microphone = true,
  }) => _mediaController.requestPermissions(
    camera: camera,
    microphone: microphone,
  );

  /// REST API: Fetches all active live broadcasting rooms from the backend (`GET /rooms`).
  Future<List<RoomModel>> getLiveRooms({
    Duration timeout = const Duration(seconds: 10),
  }) => _api.getLiveRooms(timeout: timeout);

  /// REST API: Fetches details and active viewers for a single live room (`GET /rooms/{roomId}`).
  Future<Map<String, dynamic>?> getRoom(
    String roomId, {
    Duration timeout = const Duration(seconds: 5),
  }) => _api.getRoom(roomId, timeout: timeout);

  /// Binds internal signaling and WebRTC event subscriptions.
  void _bindInternalEventListeners() {
    // 1. WebRTC Local ICE Candidates -> Signaling Server
    _webRTCManager.onLocalIceCandidate = (candidate) {
      final rId = _roomState.roomId ?? _roomManager.roomId;
      final uId = _roomState.userId ?? _roomManager.userId;
      if (rId != null && uId != null) {
        _signalingClient.send(
          SignalingMessage(
            event: SignalingEvents.ice,
            roomId: rId,
            userId: uId,
            payload: {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          ),
        );
      }
    };

    // 1.1 WebRTC ICE Disconnection Auto-Recovery & Seamless Network Handoff (1-2s trigger)
    _webRTCManager.onIceRestartNeeded = () async {
      if (_roomState.isInRoom) {
        if (_signalingClient.isConnected) {
          OmniCastLogger.log(
            '[OmniCastClient] Requesting seamless ICE Restart from SFU...',
          );
          try {
            final restartOffer = await _webRTCManager.createIceRestartOffer();
            final eventName = _roomState.isHost
                ? SignalingEvents.createRoom
                : SignalingEvents.joinRoom;
            _signalingClient.send(
              SignalingMessage(
                event: eventName,
                roomId: _roomState.roomId!,
                userId: _roomState.userId!,
                payload: {
                  'token': _signalingClient.token,
                  'sdp': restartOffer.sdp,
                  'type': restartOffer.type,
                  'ice_restart': true,
                  'reconnect': true,
                },
              ),
            );
          } catch (e) {
            OmniCastLogger.error(
              '[OmniCastClient] Fallback to ice_restart_request: $e',
            );
            _signalingClient.send(
              SignalingMessage(
                event: 'ice_restart_request',
                roomId: _roomState.roomId!,
                userId: _roomState.userId!,
              ),
            );
          }
        } else {
          OmniCastLogger.log(
            '[OmniCastClient] ICE Restart needed but signaling is disconnected; auto-reconnect will recover session upon reconnection.',
          );
        }
      }
    };

    // 1.2 Network Restoration & Signaling Auto-Reconnect Session Recovery
    _subscriptions.add(
      _signalingClient.onReconnected.listen((_) async {
        if (_roomState.isInRoom) {
          OmniCastLogger.log(
            '[OmniCastClient] Network restored & Signaling reconnected! Restoring session & triggering ICE restart for room: ${_roomState.roomId}',
          );
          try {
            final restartOffer = await _webRTCManager.createIceRestartOffer();
            final eventName = _roomState.isHost
                ? SignalingEvents.createRoom
                : SignalingEvents.joinRoom;
            _signalingClient.send(
              SignalingMessage(
                event: eventName,
                roomId: _roomState.roomId!,
                userId: _roomState.userId!,
                payload: {
                  'token': _signalingClient.token,
                  'sdp': restartOffer.sdp,
                  'type': restartOffer.type,
                  'reconnect': true,
                  'ice_restart': true,
                },
              ),
            );
          } catch (e) {
            OmniCastLogger.error(
              '[OmniCastClient] Auto-reconnect session recovery error: $e',
            );
          }
        }
      }),
    );

    // 2. WebRTC Remote Track -> MediaStreamManager & RoomState
    _webRTCManager.onRemoteTrack = (track, stream) async {
      final streamId = stream.id;
      final trackId = track.id ?? '';
      final hostId = _roomState.hostId;

      OmniCastLogger.log(
        '[OmniCastClient] onRemoteTrack: trackId=$trackId, streamId=$streamId, hostId=$hostId',
      );

      await _mediaStreamManager.attachRemoteStream(streamId, stream);
      _roomState.addActiveRemoteUser(streamId);

      // Extract numeric ID from streamId/trackId if available (e.g., 3319 from 3319_Softin Global)
      final streamNumMatch = RegExp(r'\d+').firstMatch(streamId)?.group(0);
      if (streamNumMatch != null && streamNumMatch.isNotEmpty) {
        _mediaStreamManager.registerAlias('user_$streamNumMatch', streamId);
        _mediaStreamManager.registerAlias(streamNumMatch, streamId);
        await _mediaStreamManager.attachRemoteStream('user_$streamNumMatch', stream);
        await _mediaStreamManager.attachRemoteStream(streamNumMatch, stream);
      }

      // 1. Identify if this track belongs to a co-host or specific seated user
      String? matchedUserId;
      bool isCoHostTrack = false;

      if (trackId.startsWith('cohost_') || streamId.startsWith('cohost_')) {
        isCoHostTrack = true;
        final raw = trackId.startsWith('cohost_') ? trackId : streamId;

        var extracted = raw;
        if (extracted.startsWith('cohost_video_')) {
          extracted = extracted.substring('cohost_video_'.length);
        } else if (extracted.startsWith('cohost_audio_')) {
          extracted = extracted.substring('cohost_audio_'.length);
        } else if (extracted.startsWith('cohost_')) {
          extracted = extracted.substring('cohost_'.length);
        }

        if (extracted.endsWith('_video')) {
          extracted = extracted.substring(0, extracted.length - '_video'.length);
        } else if (extracted.endsWith('_audio')) {
          extracted = extracted.substring(0, extracted.length - '_audio'.length);
        }

        matchedUserId = extracted;
      } else if (trackId.startsWith('pk-') || streamId.startsWith('pk-')) {
        isCoHostTrack = true;
        var raw = trackId.startsWith('pk-') ? trackId : streamId;
        if (raw.endsWith('-audio')) {
          raw = raw.substring(0, raw.length - '-audio'.length);
        }
        matchedUserId = raw;
      } else {
        // If it does NOT start with cohost_ or pk-, check if it explicitly matches an active seated co-host
        for (final seat in _roomState.activeSeats) {
          final sUser = seat.userId;
          if (sUser != null && sUser.isNotEmpty && sUser != hostId && sUser != 'host') {
            if (streamId == sUser || trackId == sUser || streamId.contains(sUser) || sUser.contains(streamId)) {
              matchedUserId = sUser;
              isCoHostTrack = true;
              break;
            }
          }
        }
      }

      if (!isCoHostTrack) {
        // 🚀 Main Host Track: Always attach to 'host' and targetHost alias
        final targetHost =
            (hostId != null && hostId.isNotEmpty && hostId != 'local')
                ? hostId
                : 'host';
        final currentRoomId = _roomState.roomId;
        if (currentRoomId != null && currentRoomId.isNotEmpty) {
          _mediaStreamManager.registerAlias(currentRoomId, 'host');
          _mediaStreamManager.registerAlias(currentRoomId, targetHost);
          _mediaStreamManager.registerAlias('host', currentRoomId);
          _mediaStreamManager.registerAlias(targetHost, currentRoomId);
          await _mediaStreamManager.attachRemoteStream(currentRoomId, stream);
        }
        _mediaStreamManager.registerAlias('host', targetHost);
        _mediaStreamManager.registerAlias(targetHost, 'host');
        _mediaStreamManager.registerAlias(streamId, targetHost);
        _mediaStreamManager.registerAlias(streamId, 'host');
        await _mediaStreamManager.attachRemoteStream('host', stream);
        await _mediaStreamManager.attachRemoteStream(targetHost, stream);
        _roomState.addActiveRemoteUser('host');
        _roomState.addActiveRemoteUser(targetHost);

        if (track.kind == 'video') {
          _roomState.updateUserMediaState(targetHost, isCameraOff: false);
          _roomState.updateUserMediaState('host', isCameraOff: false);
        } else if (track.kind == 'audio') {
          _roomState.updateUserMediaState(targetHost, isMuted: false);
          _roomState.updateUserMediaState('host', isMuted: false);
        }

        final hostNum = RegExp(r'\d+').firstMatch(targetHost)?.group(0);
        if (hostNum != null && hostNum.isNotEmpty) {
          _mediaStreamManager.registerAlias('user_$hostNum', targetHost);
          _mediaStreamManager.registerAlias(hostNum, targetHost);
          _mediaStreamManager.registerAlias('user_$hostNum', 'host');
          _mediaStreamManager.registerAlias(hostNum, 'host');
          await _mediaStreamManager.attachRemoteStream('user_$hostNum', stream);
          await _mediaStreamManager.attachRemoteStream(hostNum, stream);
        }
      } else {
        // 🚀 Co-Host Track: Route to dedicated co-host user ID
        final coHostUser = matchedUserId ?? streamId;
        _mediaStreamManager.registerAlias(coHostUser, streamId);
        _mediaStreamManager.registerAlias(streamId, coHostUser);
        await _mediaStreamManager.attachRemoteStream(coHostUser, stream);
        _roomState.addActiveRemoteUser(coHostUser);

        if (track.kind == 'video') {
          _roomState.updateUserMediaState(coHostUser, isCameraOff: false);
        } else if (track.kind == 'audio') {
          _roomState.updateUserMediaState(coHostUser, isMuted: false);
        }

        // Match against active seated users to create cross-aliases
        for (final seat in _roomState.activeSeats) {
          final sUser = seat.userId;
          if (sUser != null && sUser.isNotEmpty) {
            final sNum = RegExp(r'\d+').firstMatch(sUser)?.group(0);
            final cNum = RegExp(r'\d+').firstMatch(coHostUser)?.group(0);
            if (sUser == coHostUser || (sNum != null && sNum == cNum)) {
              _mediaStreamManager.registerAlias(sUser, coHostUser);
              _mediaStreamManager.registerAlias(coHostUser, sUser);
              await _mediaStreamManager.attachRemoteStream(sUser, stream);
              _roomState.addActiveRemoteUser(sUser);
              if (track.kind == 'video') {
                _roomState.updateUserMediaState(sUser, isCameraOff: false);
              } else if (track.kind == 'audio') {
                _roomState.updateUserMediaState(sUser, isMuted: false);
              }
            }
          }
        }

        final userNum = RegExp(r'\d+').firstMatch(coHostUser)?.group(0);
        if (userNum != null && userNum.isNotEmpty) {
          _mediaStreamManager.registerAlias('user_$userNum', coHostUser);
          _mediaStreamManager.registerAlias(userNum, coHostUser);
          await _mediaStreamManager.attachRemoteStream('user_$userNum', stream);
          await _mediaStreamManager.attachRemoteStream(userNum, stream);
        }
      }
    };

    // 3. Signaling State -> RoomState
    _subscriptions.add(
      _signalingClient.onConnectionStateChanged.listen((connState) {
        _roomState.updateConnectionState(connState);
      }),
    );

    // 4. Signaling Answer -> WebRTC Manager
    _subscriptions.add(
      _signalingClient.onAnswer.listen((msg) async {
        try {
          if (_roomState.isInRoom && msg.payload != null) {
            await _webRTCManager.handleRemoteAnswer(msg.payload);
          }
        } catch (e, stack) {
          OmniCastLogger.error('[OmniCastClient] Error handling remote answer: $e\n$stack');
        }
      }),
    );

    // 5. Server-Initiated SDP Offer -> WebRTC Answer -> Reply via Signaling
    _subscriptions.add(
      _signalingClient.onOffer.listen((msg) async {
        try {
          if (_roomState.isInRoom && msg.payload != null) {
            final answer = await _webRTCManager.handleRemoteOfferAndCreateAnswer(
              msg.payload,
            );
            _signalingClient.send(
              SignalingMessage(
                event: SignalingEvents.sdpAnswer,
                roomId: _roomState.roomId!,
                userId: _roomState.userId!,
                payload: {'sdp': answer.sdp, 'type': answer.type},
              ),
            );
          }
        } catch (e, stack) {
          OmniCastLogger.error('[OmniCastClient] Error handling remote offer: $e\n$stack');
        }
      }),
    );

    // 6. Incoming ICE Candidates -> WebRTC Manager
    _subscriptions.add(
      _signalingClient.onIceCandidate.listen((msg) async {
        try {
          if (msg.payload != null) {
            await _webRTCManager.addRemoteCandidate(msg.payload);
          }
        } catch (e) {
          OmniCastLogger.error('[OmniCastClient] Error adding remote candidate: $e');
        }
      }),
    );

    // 7. Room Info Sync (Late-join hydration)
    _subscriptions.add(
      _signalingClient.onRoomInfoSync.listen((msg) {
        if (msg.payload is Map<String, dynamic>) {
          _roomState.syncRoomInfo(msg.payload as Map<String, dynamic>);
        }
      }),
    );

    // 8. Viewer Updates
    _subscriptions.add(
      _signalingClient.onViewerUpdate.listen((msg) {
        if (msg.payload is Map<String, dynamic>) {
          final payload = msg.payload as Map<String, dynamic>;
          final count =
              (payload['viewers_count'] as num?)?.toInt() ??
              (payload['viewer_count'] as num?)?.toInt() ??
              0;
          List<Participant>? viewersList;
          if (payload['viewers'] is List) {
            viewersList = (payload['viewers'] as List)
                .map((e) => Participant.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          _roomState.updateViewers(count: count, viewersList: viewersList);
        }
      }),
    );

    // 9. Real-Time Chat
    _subscriptions.add(
      _signalingClient.onChat.listen((chatMsg) {
        _roomState.addChatMessage(chatMsg);
      }),
    );

    // 10. Seat Invites & Requests
    _subscriptions.add(
      _signalingClient.onMessage.listen((msg) {
        if (msg.event == SignalingEvents.seatInvite &&
            msg.payload is Map<String, dynamic>) {
          _roomState.addInvite(
            CoHostInvite.fromJson(msg.payload as Map<String, dynamic>),
          );
        } else if (msg.event == SignalingEvents.pinStage &&
            msg.payload is Map<String, dynamic>) {
          _roomState.setPinnedStageUser(
            msg.payload['pinned_user_id'] as String?,
          );
        }
      }),
    );
  }

  /// Permanently disposes the client, closing sub-managers, streams, peer connections, and WebSockets.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final sub in _subscriptions) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    _subscriptions.clear();

    stopWatchingRooms();
    _liveRoomsNotifier.dispose();

    _roomManager.dispose();
    _mediaController.dispose();
    _seatManager.dispose();
    await _pkManager.dispose();
    await _dataChannelManager.dispose();
    await _interactionManager.dispose();

    await _webRTCManager.dispose();
    await _mediaStreamManager.dispose();
    await _signalingClient.dispose();
    _api.dispose();
    _roomState.dispose();
    if (instance == this) {
      instance = null;
    }
  }
}
