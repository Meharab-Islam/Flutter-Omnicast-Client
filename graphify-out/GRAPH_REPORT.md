# Graph Report - omnicast_client  (2026-08-28)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 540 nodes · 628 edges · 23 communities (19 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a7805053`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- room_state.dart
- signaling_client.dart
- signaling_message.dart
- core/omnicast_client.dart
- webrtc_manager.dart
- omnicast_video_view.dart
- media_controller.dart
- seat_models.dart
- media_stream_manager.dart
- omnicast_config.dart
- interaction_models.dart
- pk_models.dart
- room_models.dart
- lib/omnicast_client.dart
- video_parameters.dart
- pk_manager.dart
- interaction_manager.dart
- room_manager.dart
- seat_manager.dart
- RoomState
- MediaStreamManager
- ../models/room_event_models.dart
- src/models/room_event_models.dart

## God Nodes (most connected - your core abstractions)
1. `RoomState` - 6 edges
2. `SignalingClient` - 5 edges
3. `MediaStreamManager` - 5 edges
4. `ClientConnectionState` - 3 edges
5. `MediaController` - 3 edges
6. `OmniCastVideoView` - 3 edges
7. `_OmniCastVideoViewState` - 3 edges
8. `WebRTCManager` - 3 edges
9. `PKBattleInfo` - 2 edges
10. `Participant` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (23 total, 4 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.04
Nodes (49): ClientConnectionState get, int get, _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite (+41 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.04
Nodes (49): _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState, disconnect (+41 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (48): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+40 more)

### Community 3 - "core/omnicast_client.dart"
Cohesion: 0.04
Nodes (45): ../interaction/interaction_manager.dart, InteractionManager, InteractionManager get, _bindInternalEventListeners, config, dispose, init, _initSubManagers (+37 more)

### Community 4 - "webrtc_manager.dart"
Cohesion: 0.06
Nodes (32): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, dispose, handleRemoteAnswer, handleRemoteOfferAndCreateAnswer (+24 more)

### Community 5 - "omnicast_video_view.dart"
Cohesion: 0.07
Nodes (29): Color, MediaController, MediaStreamManager, _bindRenderer, build, _checkAdaptiveStreaming, createState, _currentRequestedLayer (+21 more)

### Community 6 - "media_controller.dart"
Cohesion: 0.07
Nodes (28): _adaptiveStreamingEnabled, _bindDynacastSignaling, currentParameters, _currentSimulcastLayer, dispose, _dynacastEnabled, _dynacastSubscription, enableAdaptiveStreaming (+20 more)

### Community 7 - "seat_models.dart"
Cohesion: 0.07
Nodes (26): bool get, interaction_models.dart, CoHostInvite, createdAt, fromJson, hostId, inviteId, isLocked (+18 more)

### Community 8 - "media_stream_manager.dart"
Cohesion: 0.07
Nodes (27): attachRemoteStream, _currentParameters, dispose, getOrCreateRemoteRenderer, getRenderer, hasLocalStream, initLocalRenderer, _isAudioMuted (+19 more)

### Community 9 - "omnicast_config.dart"
Cohesion: 0.09
Nodes (21): dart:convert, Duration, apiKey, apiSecret, generateAuthToken, heartbeatInterval, hostUrl, iceServers (+13 more)

### Community 10 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent, giftIconUrl (+16 more)

### Community 11 - "pk_models.dart"
Cohesion: 0.08
Nodes (23): DateTime, battleId, deltaPoints, durationSeconds, fromJson, hostRoomId, hostScore, hostUserId (+15 more)

### Community 12 - "room_models.dart"
Cohesion: 0.09
Nodes (21): avatarUrl, ClientConnectionState, displayName, enableAudio, enableDynacast, enableSimulcast, enableVideo, fromJson (+13 more)

### Community 13 - "lib/omnicast_client.dart"
Cohesion: 0.11
Nodes (18): src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/interaction/interaction_manager.dart, src/media/media_controller.dart, src/media/media_stream_manager.dart, src/media/video_parameters.dart, src/models/interaction_models.dart, src/models/pk_models.dart (+10 more)

### Community 14 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

### Community 15 - "pk_manager.dart"
Cohesion: 0.12
Nodes (16): acceptPKRequest, _bindStreams, dispose, endPK, onPKScoreUpdated, onPKTimerTick, PKManager, _pkScoreController (+8 more)

### Community 16 - "interaction_manager.dart"
Cohesion: 0.13
Nodes (14): _balanceUpdatedController, _bindStreams, dispose, _giftReceivedController, InteractionManager, onBalanceUpdated, onGiftReceived, _roomState (+6 more)

### Community 17 - "room_manager.dart"
Cohesion: 0.15
Nodes (12): dart:async, createRoom, joinRoom, kickUser, leaveRoom, RoomManager, _roomState, _signalingClient (+4 more)

### Community 18 - "seat_manager.dart"
Cohesion: 0.15
Nodes (12): acceptCoHostInvite, demoteToViewer, inviteToCoHost, pinToMainStage, _roomState, SeatManager, _signalingClient, upgradeToCoHost (+4 more)

## Knowledge Gaps
- **398 isolated node(s):** `_activePK`, `_activeRemoteUserIds`, `_activeSeats`, `addActiveRemoteUser`, `addChatMessage` (+393 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MediaStreamManager` connect `omnicast_video_view.dart` to `media_stream_manager.dart`, `core/omnicast_client.dart`, `webrtc_manager.dart`, `media_controller.dart`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **Why does `VideoParameters` connect `video_parameters.dart` to `media_stream_manager.dart`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **Why does `RoomState` connect `RoomState` to `room_state.dart`, `pk_manager.dart`, `interaction_manager.dart`, `room_manager.dart`, `seat_manager.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **What connects `_activePK`, `_activeRemoteUserIds`, `_activeSeats` to the rest of the system?**
  _398 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._