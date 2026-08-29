# Graph Report - omnicast_client  (2026-08-29)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 818 nodes · 988 edges · 32 communities (25 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `05ca791b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- room_state.dart
- signaling_client.dart
- signaling_message.dart
- gift_overlay_manager.dart
- media_controller.dart
- core/omnicast_client.dart
- omnicast_speaking_video_tile.dart
- room_manager.dart
- pk_models.dart
- media_stream_manager.dart
- webrtc_manager.dart
- pk_manager.dart
- seat_manager.dart
- package:flutter_test/flutter_test.dart
- room_models.dart
- seat_models.dart
- lib/omnicast_client.dart
- interaction_manager.dart
- interaction_models.dart
- omnicast_video_view.dart
- omnicast_pk_battle_view.dart
- video_parameters.dart
- audio_level_detector.dart
- pk_score_progress_bar.dart
- omnicast_token_generator.dart
- RoomState
- MediaController
- ../models/room_event_models.dart
- package:crypto/crypto.dart
- RoomManager
- src/models/room_event_models.dart
- VideoParameters

## God Nodes (most connected - your core abstractions)
1. `SignalingClient` - 6 edges
2. `MediaController` - 5 edges
3. `Participant` - 3 edges
4. `WebRTCManager` - 3 edges
5. `PKState` - 3 edges
6. `GiftOverlayManager` - 3 edges
7. `_GiftOverlayManagerState` - 3 edges
8. `OmniCastVideoView` - 3 edges
9. `_OmniCastVideoViewState` - 3 edges
10. `AudioLevelDetector` - 3 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (32 total, 7 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.04
Nodes (54): _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addParticipant, addSeatRequest (+46 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.04
Nodes (52): ClientConnectionState get, _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState (+44 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (50): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+42 more)

### Community 3 - "gift_overlay_manager.dart"
Cohesion: 0.04
Nodes (46): Alignment, ../auth/omnicast_token_generator.dart, Duration, GiftEvent, apiKey, apiSecret, apiUrl, generateToken (+38 more)

### Community 4 - "media_controller.dart"
Cohesion: 0.04
Nodes (45): audio_level_detector.dart, AudioLevelDetector get, global_media_config.dart, GlobalMediaConfig get, activeSpeakerNotifier, _adaptiveStreamingEnabled, audioDetector, _audioLevelDetector (+37 more)

### Community 5 - "core/omnicast_client.dart"
Cohesion: 0.04
Nodes (45): GlobalMediaConfig, ../interaction/interaction_manager.dart, InteractionManager, InteractionManager get, _bindInternalEventListeners, config, dispose, init (+37 more)

### Community 6 - "omnicast_speaking_video_tile.dart"
Cohesion: 0.05
Nodes (40): Color, EdgeInsetsGeometry, IconData, AudioLevelDetector, MediaController, _GiftBannerWidget, activeColor, build (+32 more)

### Community 7 - "room_manager.dart"
Cohesion: 0.05
Nodes (37): ClientConnectionState, ../core/omnicast_config.dart, activeSeatsNotifier, activeViewersList, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, _config (+29 more)

### Community 8 - "pk_models.dart"
Cohesion: 0.05
Nodes (36): double get, Duration get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo, fromJson (+28 more)

### Community 9 - "media_stream_manager.dart"
Cohesion: 0.06
Nodes (34): autoPauseOnBackground, defaultResolution, enableAdaptiveStreaming, enableDynacast, enableSimulcast, GlobalMediaConfig, attachRemoteStream, _currentParameters (+26 more)

### Community 10 - "webrtc_manager.dart"
Cohesion: 0.06
Nodes (33): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, dispose, enableOpusDtx, handleRemoteAnswer (+25 more)

### Community 11 - "pk_manager.dart"
Cohesion: 0.06
Nodes (32): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+24 more)

### Community 12 - "seat_manager.dart"
Cohesion: 0.06
Nodes (32): acceptCoHostInvite, acceptSeatRequest, activeCoHostsList, activeSeatsNotifier, _bindSignalingListeners, _bindStateNotifiers, demoteToViewer, dispose (+24 more)

### Community 13 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.10
Nodes (18): dart:async, dart:convert, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:flutter/widgets.dart, package:omnicast_client/omnicast_client.dart, main, main (+10 more)

### Community 14 - "room_models.dart"
Cohesion: 0.07
Nodes (28): int get, avatarUrl, ClientConnectionState, copyWith, displayName, enableAudio, enableDynacast, enableSimulcast (+20 more)

### Community 15 - "seat_models.dart"
Cohesion: 0.07
Nodes (26): bool get, interaction_models.dart, CoHostInvite, createdAt, fromJson, hostId, inviteId, isLocked (+18 more)

### Community 16 - "lib/omnicast_client.dart"
Cohesion: 0.07
Nodes (26): src/auth/omnicast_token_generator.dart, src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/interaction/interaction_manager.dart, src/media/audio_level_detector.dart, src/media/global_media_config.dart, src/media/media_controller.dart, src/media/media_stream_manager.dart (+18 more)

### Community 17 - "interaction_manager.dart"
Cohesion: 0.08
Nodes (25): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+17 more)

### Community 18 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): DateTime, amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent (+16 more)

### Community 19 - "omnicast_video_view.dart"
Cohesion: 0.10
Nodes (20): build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming, _initializeLazyRenderer (+12 more)

### Community 20 - "omnicast_pk_battle_view.dart"
Cohesion: 0.10
Nodes (19): Axis, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager, objectFit (+11 more)

### Community 21 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

### Community 22 - "audio_level_detector.dart"
Cohesion: 0.12
Nodes (15): activeSpeakerNotifier, audioLevelsNotifier, dispose, _isDisposed, pollInterval, pollStats, _pollTimer, start (+7 more)

### Community 23 - "pk_score_progress_bar.dart"
Cohesion: 0.13
Nodes (14): Gradient?, PKState, borderRadius, build, _formatTimer, height, hostGradient, opponentGradient (+6 more)

### Community 24 - "omnicast_token_generator.dart"
Cohesion: 0.50
Nodes (3): generate, OmniCastTokenGenerator, package:dart_jsonwebtoken/dart_jsonwebtoken.dart

## Knowledge Gaps
- **605 isolated node(s):** `_activePK`, `_activeRemoteUserIds`, `_activeSeats`, `addActiveRemoteUser`, `addChatMessage` (+600 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MediaController` connect `omnicast_speaking_video_tile.dart` to `omnicast_video_view.dart`, `media_controller.dart`, `core/omnicast_client.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `VideoParameters` connect `media_stream_manager.dart` to `video_parameters.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `SignalingClient` connect `interaction_manager.dart` to `signaling_client.dart`, `core/omnicast_client.dart`, `room_manager.dart`, `pk_manager.dart`, `seat_manager.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `_activePK`, `_activeRemoteUserIds`, `_activeSeats` to the rest of the system?**
  _605 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03636363636363636 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._