# Graph Report - omnicast_client  (2026-08-28)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 759 nodes · 907 edges · 35 communities (26 shown, 9 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bbe08f9c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- room_state.dart
- signaling_client.dart
- signaling_message.dart
- core/omnicast_client.dart
- media_controller.dart
- room_manager.dart
- pk_models.dart
- media_stream_manager.dart
- pk_manager.dart
- gift_overlay_manager.dart
- seat_manager.dart
- webrtc_manager.dart
- package:flutter_test/flutter_test.dart
- room_models.dart
- interaction_manager.dart
- interaction_models.dart
- lib/omnicast_client.dart
- omnicast_video_view.dart
- seat_models.dart
- omnicast_pk_battle_view.dart
- video_parameters.dart
- omnicast_config.dart
- pk_score_progress_bar.dart
- room_event_models.dart
- omnicast_token_generator.dart
- StatelessWidget
- RoomState
- Participant
- Color
- MediaController
- ../models/room_event_models.dart
- package:crypto/crypto.dart
- RoomManager
- SignalingClient
- src/models/room_event_models.dart

## God Nodes (most connected - your core abstractions)
1. `SignalingClient` - 7 edges
2. `MediaController` - 4 edges
3. `PKState` - 3 edges
4. `Participant` - 3 edges
5. `GiftOverlayManager` - 3 edges
6. `_GiftOverlayManagerState` - 3 edges
7. `OmniCastVideoView` - 3 edges
8. `_OmniCastVideoViewState` - 3 edges
9. `ClientConnectionState` - 2 edges
10. `RoomType` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (35 total, 9 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.04
Nodes (54): _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addParticipant, addSeatRequest (+46 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.04
Nodes (52): ClientConnectionState get, _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState (+44 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (50): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+42 more)

### Community 3 - "core/omnicast_client.dart"
Cohesion: 0.05
Nodes (43): ../interaction/interaction_manager.dart, InteractionManager, InteractionManager get, _bindInternalEventListeners, config, dispose, init, _initSubManagers (+35 more)

### Community 4 - "media_controller.dart"
Cohesion: 0.05
Nodes (40): global_media_config.dart, GlobalMediaConfig, GlobalMediaConfig get, _adaptiveStreamingEnabled, _autoPauseOnBackground, _bindDynacastSignaling, _config, currentParameters (+32 more)

### Community 5 - "room_manager.dart"
Cohesion: 0.05
Nodes (37): ClientConnectionState, ../core/omnicast_config.dart, activeSeatsNotifier, activeViewersList, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, _config (+29 more)

### Community 6 - "pk_models.dart"
Cohesion: 0.05
Nodes (36): double get, Duration get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo, fromJson (+28 more)

### Community 7 - "media_stream_manager.dart"
Cohesion: 0.06
Nodes (34): autoPauseOnBackground, defaultResolution, enableAdaptiveStreaming, enableDynacast, enableSimulcast, GlobalMediaConfig, attachRemoteStream, _currentParameters (+26 more)

### Community 8 - "pk_manager.dart"
Cohesion: 0.06
Nodes (33): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+25 more)

### Community 9 - "gift_overlay_manager.dart"
Cohesion: 0.06
Nodes (32): Alignment, GiftEvent, _ActiveGiftItem, _activeGifts, bannerAlignment, build, child, combo (+24 more)

### Community 10 - "seat_manager.dart"
Cohesion: 0.06
Nodes (32): acceptCoHostInvite, acceptSeatRequest, activeCoHostsList, activeSeatsNotifier, _bindSignalingListeners, _bindStateNotifiers, demoteToViewer, dispose (+24 more)

### Community 11 - "webrtc_manager.dart"
Cohesion: 0.06
Nodes (32): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, dispose, handleRemoteAnswer, handleRemoteOfferAndCreateAnswer (+24 more)

### Community 12 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.10
Nodes (17): dart:async, dart:convert, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:flutter/widgets.dart, package:omnicast_client/omnicast_client.dart, main, main (+9 more)

### Community 13 - "room_models.dart"
Cohesion: 0.07
Nodes (27): int get, avatarUrl, ClientConnectionState, copyWith, displayName, enableAudio, enableDynacast, enableSimulcast (+19 more)

### Community 14 - "interaction_manager.dart"
Cohesion: 0.07
Nodes (26): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+18 more)

### Community 15 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): DateTime, amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent (+16 more)

### Community 16 - "lib/omnicast_client.dart"
Cohesion: 0.08
Nodes (23): src/auth/omnicast_token_generator.dart, src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/interaction/interaction_manager.dart, src/media/global_media_config.dart, src/media/media_controller.dart, src/media/media_stream_manager.dart, src/media/video_parameters.dart (+15 more)

### Community 17 - "omnicast_video_view.dart"
Cohesion: 0.09
Nodes (22): build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming, _initializeLazyRenderer (+14 more)

### Community 18 - "seat_models.dart"
Cohesion: 0.09
Nodes (21): bool get, CoHostInvite, createdAt, fromJson, hostId, inviteId, isLocked, isMuted (+13 more)

### Community 19 - "omnicast_pk_battle_view.dart"
Cohesion: 0.10
Nodes (20): Axis, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager, objectFit (+12 more)

### Community 20 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

### Community 21 - "omnicast_config.dart"
Cohesion: 0.12
Nodes (15): ../auth/omnicast_token_generator.dart, Duration, apiKey, apiSecret, apiUrl, generateToken, heartbeatInterval, hostUrl (+7 more)

### Community 22 - "pk_score_progress_bar.dart"
Cohesion: 0.13
Nodes (14): Gradient?, PKState, borderRadius, build, _formatTimer, height, hostGradient, opponentGradient (+6 more)

### Community 23 - "room_event_models.dart"
Cohesion: 0.33
Nodes (5): interaction_models.dart, pk_models.dart, room_models.dart, seat_models.dart, signaling_message.dart

### Community 24 - "omnicast_token_generator.dart"
Cohesion: 0.50
Nodes (3): generate, OmniCastTokenGenerator, package:dart_jsonwebtoken/dart_jsonwebtoken.dart

### Community 25 - "StatelessWidget"
Cohesion: 0.50
Nodes (4): _GiftBannerWidget, OmniCastPKBattleView, PKScoreProgressBar, StatelessWidget

## Knowledge Gaps
- **564 isolated node(s):** `_activePK`, `_activeRemoteUserIds`, `_activeSeats`, `addActiveRemoteUser`, `addChatMessage` (+559 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SignalingClient` connect `interaction_manager.dart` to `signaling_client.dart`, `core/omnicast_client.dart`, `media_controller.dart`, `room_manager.dart`, `pk_manager.dart`, `seat_manager.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `VideoParameters` connect `video_parameters.dart` to `media_stream_manager.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `PKState` connect `pk_score_progress_bar.dart` to `omnicast_pk_battle_view.dart`, `pk_models.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **What connects `_activePK`, `_activeRemoteUserIds`, `_activeSeats` to the rest of the system?**
  _564 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03636363636363636 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._