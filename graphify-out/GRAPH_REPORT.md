# Graph Report - omnicast_client  (2026-08-28)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 693 nodes · 824 edges · 31 communities (23 shown, 8 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `784167ec`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- signaling_client.dart
- signaling_message.dart
- room_state.dart
- core/omnicast_client.dart
- gift_overlay_manager.dart
- pk_models.dart
- room_manager.dart
- media_controller.dart
- webrtc_manager.dart
- pk_manager.dart
- seat_models.dart
- room_models.dart
- media_stream_manager.dart
- interaction_manager.dart
- interaction_models.dart
- omnicast_video_view.dart
- dart:async
- lib/omnicast_client.dart
- omnicast_pk_battle_view.dart
- video_parameters.dart
- seat_manager.dart
- pk_score_progress_bar.dart
- StatelessWidget
- RoomState
- Color
- ../models/room_event_models.dart
- OmniCastConfig
- package:crypto/crypto.dart
- RoomManager
- SignalingClient
- src/models/room_event_models.dart

## God Nodes (most connected - your core abstractions)
1. `SignalingClient` - 7 edges
2. `MediaController` - 4 edges
3. `Participant` - 3 edges
4. `PKState` - 3 edges
5. `RoomState` - 3 edges
6. `GiftOverlayManager` - 3 edges
7. `_GiftOverlayManagerState` - 3 edges
8. `OmniCastVideoView` - 3 edges
9. `_OmniCastVideoViewState` - 3 edges
10. `ClientConnectionState` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (31 total, 8 thin omitted)

### Community 0 - "signaling_client.dart"
Cohesion: 0.04
Nodes (50): ClientConnectionState get, _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState (+42 more)

### Community 1 - "signaling_message.dart"
Cohesion: 0.04
Nodes (50): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+42 more)

### Community 2 - "room_state.dart"
Cohesion: 0.04
Nodes (50): _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addParticipant, addSeatRequest (+42 more)

### Community 3 - "core/omnicast_client.dart"
Cohesion: 0.05
Nodes (41): ../interaction/interaction_manager.dart, InteractionManager, InteractionManager get, _bindInternalEventListeners, config, dispose, init, _initSubManagers (+33 more)

### Community 4 - "gift_overlay_manager.dart"
Cohesion: 0.05
Nodes (38): Alignment, Duration, GiftEvent, heartbeatInterval, hostUrl, iceServers, maxReconnectAttempts, OmniCastConfig (+30 more)

### Community 5 - "pk_models.dart"
Cohesion: 0.05
Nodes (36): double get, Duration get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo, fromJson (+28 more)

### Community 6 - "room_manager.dart"
Cohesion: 0.06
Nodes (35): ClientConnectionState, activeSeatsNotifier, activeViewersList, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, connectionStateNotifier, createRoom (+27 more)

### Community 7 - "media_controller.dart"
Cohesion: 0.06
Nodes (34): _adaptiveStreamingEnabled, _autoPauseOnBackground, _bindDynacastSignaling, currentParameters, currentSimulcastLayer, didChangeAppLifecycleState, dispose, _dynacastEnabled (+26 more)

### Community 8 - "webrtc_manager.dart"
Cohesion: 0.06
Nodes (32): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, dispose, handleRemoteAnswer, handleRemoteOfferAndCreateAnswer (+24 more)

### Community 9 - "pk_manager.dart"
Cohesion: 0.06
Nodes (31): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+23 more)

### Community 10 - "seat_models.dart"
Cohesion: 0.07
Nodes (27): bool get, DateTime, interaction_models.dart, CoHostInvite, createdAt, fromJson, hostId, inviteId (+19 more)

### Community 11 - "room_models.dart"
Cohesion: 0.07
Nodes (27): int get, avatarUrl, ClientConnectionState, copyWith, displayName, enableAudio, enableDynacast, enableSimulcast (+19 more)

### Community 12 - "media_stream_manager.dart"
Cohesion: 0.07
Nodes (27): attachRemoteStream, _currentParameters, dispose, getOrCreateRemoteRenderer, getRenderer, hasLocalStream, initLocalRenderer, _isAudioMuted (+19 more)

### Community 13 - "interaction_manager.dart"
Cohesion: 0.08
Nodes (24): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+16 more)

### Community 14 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent, giftIconUrl (+16 more)

### Community 15 - "omnicast_video_view.dart"
Cohesion: 0.09
Nodes (22): build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming, _initializeLazyRenderer (+14 more)

### Community 16 - "dart:async"
Cohesion: 0.13
Nodes (14): dart:async, dart:convert, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:flutter/widgets.dart, package:omnicast_client/omnicast_client.dart, main, main (+6 more)

### Community 17 - "lib/omnicast_client.dart"
Cohesion: 0.09
Nodes (21): src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/interaction/interaction_manager.dart, src/media/media_controller.dart, src/media/media_stream_manager.dart, src/media/video_parameters.dart, src/models/interaction_models.dart, src/models/pk_models.dart (+13 more)

### Community 18 - "omnicast_pk_battle_view.dart"
Cohesion: 0.10
Nodes (20): Axis, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager, objectFit (+12 more)

### Community 19 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

### Community 20 - "seat_manager.dart"
Cohesion: 0.12
Nodes (16): acceptCoHostInvite, demoteToViewer, inviteToCoHost, pinToMainStage, _roomState, SeatManager, _signalingClient, upgradeToCoHost (+8 more)

### Community 21 - "pk_score_progress_bar.dart"
Cohesion: 0.13
Nodes (14): Gradient?, PKState, borderRadius, build, _formatTimer, height, hostGradient, opponentGradient (+6 more)

### Community 22 - "StatelessWidget"
Cohesion: 0.50
Nodes (4): _GiftBannerWidget, OmniCastPKBattleView, PKScoreProgressBar, StatelessWidget

## Knowledge Gaps
- **515 isolated node(s):** `_answerController`, `_channel`, `_channelSubscription`, `_chatController`, `_cleanupActiveConnection` (+510 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SignalingClient` connect `seat_manager.dart` to `signaling_client.dart`, `core/omnicast_client.dart`, `room_manager.dart`, `media_controller.dart`, `pk_manager.dart`, `interaction_manager.dart`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `PKState` connect `pk_score_progress_bar.dart` to `omnicast_pk_battle_view.dart`, `pk_models.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `VideoParameters` connect `video_parameters.dart` to `media_stream_manager.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `_answerController`, `_channel`, `_channelSubscription` to the rest of the system?**
  _515 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._