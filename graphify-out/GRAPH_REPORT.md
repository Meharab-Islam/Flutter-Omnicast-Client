# Graph Report - omnicast_client  (2026-09-03)

## Corpus Check
- 59 files · ~35,406 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1203 nodes · 1461 edges · 42 communities (39 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `0263ab59`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- room_state.dart
- signaling_client.dart
- signaling_message.dart
- core/omnicast_client.dart
- media_controller.dart
- room_manager.dart
- webrtc_manager.dart
- pk_models.dart
- media_stream_manager.dart
- omnicast_flying_hearts_overlay.dart
- pk_manager.dart
- seat_manager.dart
- package:flutter_test/flutter_test.dart
- lib/omnicast_client.dart
- data_channel_manager.dart
- room_models.dart
- seat_models.dart
- gift_overlay_manager.dart
- interaction_models.dart
- interaction_manager.dart
- omnicast_pk_battle_view.dart
- omnicast_video_view.dart
- omnicast_media_control_bar.dart
- webrtc_stats_monitor.dart
- omnicast_speaking_video_tile.dart
- audio_level_detector.dart
- omnicast_gifting_bottom_sheet.dart
- 🚀 OmniCast Client Flutter SDK
- StatelessWidget
- ⚔️ OmniCast SDK: PK Battle Integration Guide
- omnicast_token_generator.dart
- RoomState
- CHANGELOG.md
- package:flutter/foundation.dart
- 👢 OmniCast SDK: Participant Kick & Ejection Guide
- _OmniCastFlyingHeartsOverlayState
- omnicast_native_viewport_tracker.dart
- 🎙️ OmniCast SDK: Co-Host & Stage Moderation Guide
- 👥 OmniCast SDK: Viewers & Metadata Integration Guide
- 🚀 OmniCast SDK: Complete Developer & Media Rendering Guide
- handleRawMessage
- omnicast_video_canvas.dart

## God Nodes (most connected - your core abstractions)
1. `🚀 OmniCast Client Flutter SDK` - 16 edges
2. `RoomState` - 9 edges
3. `👥 OmniCast SDK: Viewers & Metadata Integration Guide` - 9 edges
4. `WebRTCManager` - 8 edges
5. `🎙️ OmniCast SDK: Co-Host & Stage Moderation Guide` - 8 edges
6. `🚀 OmniCast SDK: Complete Developer & Media Rendering Guide` - 8 edges
7. `👢 OmniCast SDK: Participant Kick & Ejection Guide` - 8 edges
8. `⚔️ OmniCast SDK: PK Battle Integration Guide` - 8 edges
9. `SignalingClient` - 7 edges
10. `MediaController` - 6 edges

## Surprising Connections (you probably didn't know these)
- `OmniCastGiftingBottomSheet` --inherits--> `StatefulWidget`  [EXTRACTED]
  lib/src/widgets/omnicast_gifting_bottom_sheet.dart → None  _Bridges community 35 → community 26_

## Import Cycles
- None detected.

## Communities (42 total, 3 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.03
Nodes (64): _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addParticipant, addSeatRequest (+56 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.03
Nodes (64): ClientConnectionState get, _answerController, autoReconnect, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect (+56 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (56): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, gift (+48 more)

### Community 3 - "core/omnicast_client.dart"
Cohesion: 0.03
Nodes (63): ../api/omnicast_api.dart, DataChannelManager get, ../interaction/interaction_manager.dart, InteractionManager get, activeViewersList, _api, _bindInternalEventListeners, config (+55 more)

### Community 4 - "media_controller.dart"
Cohesion: 0.04
Nodes (50): audio_level_detector.dart, AudioLevelDetector get, global_media_config.dart, GlobalMediaConfig get, activeSpeakerNotifier, _adaptiveStreamingEnabled, audioDetector, _audioLevelDetector (+42 more)

### Community 5 - "room_manager.dart"
Cohesion: 0.04
Nodes (48): activeSeatsNotifier, activeViewersList, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, closeRoom, _config, connectionStateNotifier (+40 more)

### Community 6 - "webrtc_manager.dart"
Cohesion: 0.05
Nodes (43): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, createIceRestartOffer, dispose, enableOpusDtx (+35 more)

### Community 7 - "pk_models.dart"
Cohesion: 0.05
Nodes (37): double get, Duration get, int get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo (+29 more)

### Community 8 - "media_stream_manager.dart"
Cohesion: 0.06
Nodes (33): autoPauseOnBackground, defaultResolution, enableAdaptiveStreaming, enableDynacast, enableSimulcast, GlobalMediaConfig, attachRemoteStream, _currentParameters (+25 more)

### Community 9 - "omnicast_flying_hearts_overlay.dart"
Cohesion: 0.08
Nodes (23): AnimationController, dart:math, ../datachannel/data_channel_manager.dart, Key, build, controller, createState, dispose (+15 more)

### Community 10 - "pk_manager.dart"
Cohesion: 0.06
Nodes (30): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+22 more)

### Community 11 - "seat_manager.dart"
Cohesion: 0.05
Nodes (36): acceptCoHostInvite, acceptSeatRequest, activeCoHostsList, activeSeatsNotifier, _bindSignalingListeners, _bindStateNotifiers, cancelSeatRequest, demoteToViewer (+28 more)

### Community 12 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.07
Nodes (26): dart:async, dart:convert, dart:typed_data, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:flutter/widgets.dart, package:http/http.dart, package:http/testing.dart (+18 more)

### Community 13 - "lib/omnicast_client.dart"
Cohesion: 0.06
Nodes (33): src/api/omnicast_api.dart, src/auth/omnicast_token_generator.dart, src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/datachannel/data_channel_manager.dart, src/interaction/interaction_manager.dart, src/media/audio_level_detector.dart, src/media/global_media_config.dart (+25 more)

### Community 14 - "data_channel_manager.dart"
Cohesion: 0.04
Nodes (43): Gradient?, attachIncomingChannel, _bindDataChannel, _chatController, createPublisherChannel, _dataChannel, DataChannelManager, DataChannelReaction (+35 more)

### Community 15 - "room_models.dart"
Cohesion: 0.05
Nodes (42): ActiveLiveRoom, avatarUrl, ClientConnectionState, copyWith, createdAt, displayName, enableAudio, enableDynacast (+34 more)

### Community 16 - "seat_models.dart"
Cohesion: 0.04
Nodes (44): bool get, int?, interaction_models.dart, copyWith, custom, facingMode, frameRate, height (+36 more)

### Community 17 - "gift_overlay_manager.dart"
Cohesion: 0.08
Nodes (23): Alignment, _ActiveGiftItem, _activeGifts, bannerAlignment, build, child, combo, createState (+15 more)

### Community 18 - "interaction_models.dart"
Cohesion: 0.05
Nodes (38): ../auth/omnicast_token_generator.dart, DateTime, Duration, apiKey, apiSecret, apiUrl, generateToken, heartbeatInterval (+30 more)

### Community 19 - "interaction_manager.dart"
Cohesion: 0.08
Nodes (24): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+16 more)

### Community 20 - "omnicast_pk_battle_view.dart"
Cohesion: 0.10
Nodes (20): Axis, MediaStreamManager, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager (+12 more)

### Community 21 - "omnicast_video_view.dart"
Cohesion: 0.11
Nodes (18): build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming, _initializeLazyRenderer (+10 more)

### Community 22 - "omnicast_media_control_bar.dart"
Cohesion: 0.14
Nodes (13): Color, EdgeInsetsGeometry, IconData, activeColor, build, icon, inactiveColor, isActive (+5 more)

### Community 23 - "webrtc_stats_monitor.dart"
Cohesion: 0.06
Nodes (30): bitrateKbps, currentStats, dispose, initial, interval, _isDisposed, jitterMs, _lastBytesReceived (+22 more)

### Community 24 - "omnicast_speaking_video_tile.dart"
Cohesion: 0.11
Nodes (18): bool?, AudioLevelDetector, audioDetector, avatarUrl, build, _buildAvatarPlaceholder, isCameraEnabled, isMicMuted (+10 more)

### Community 25 - "audio_level_detector.dart"
Cohesion: 0.13
Nodes (14): activeSpeakerNotifier, audioLevelsNotifier, dispose, _isDisposed, pollInterval, pollStats, _pollTimer, start (+6 more)

### Community 26 - "omnicast_gifting_bottom_sheet.dart"
Cohesion: 0.11
Nodes (19): ../core/omnicast_client.dart, Function?, OmniCastClient, build, client, coinPrice, createState, emoji (+11 more)

### Community 27 - "🚀 OmniCast Client Flutter SDK"
Cohesion: 0.06
Nodes (34): 1. Add dependency to `pubspec.yaml`, 1. Challenge & Accept PK, 1. Join a Live Room as a Viewer, 1. Send Chat & Virtual Gifts, 1. Send Metadata When Joining as a Viewer, 1. Video Resolution Presets (`VideoParameters`), 2. Configure Native Permissions, 2. Gift Banner Overlay Widget (`GiftOverlayManager`) (+26 more)

### Community 28 - "StatelessWidget"
Cohesion: 0.18
Nodes (11): _GiftBannerWidget, _CircleControlButton, OmniCastMediaControlBar, OmniCastNativeViewportTracker, OmniCastPKBattleView, OmniCastSpeakingVideoTile, _SpeakingWaveformIcon, AnimatedFlexible (+3 more)

### Community 29 - "⚔️ OmniCast SDK: PK Battle Integration Guide"
Cohesion: 0.09
Nodes (21): 1. PK Battle Architecture & Flow, 2. Signaling JSON Contracts, 3. SDK API Reference (`client.pk`), 4. Data Models & States, 5. Step-by-Step Flutter UI Integration, 6. Best Practices & Troubleshooting, A. Send PK Challenge (`pk_request`), B. Accept PK Challenge (`pk_accept`) (+13 more)

### Community 30 - "omnicast_token_generator.dart"
Cohesion: 0.50
Nodes (3): generate, OmniCastTokenGenerator, package:dart_jsonwebtoken/dart_jsonwebtoken.dart

### Community 33 - "package:flutter/foundation.dart"
Cohesion: 0.20
Nodes (9): Client, ../core/omnicast_config.dart, _client, config, dispose, getLiveRooms, OmniCastApi, ../models/room_models.dart (+1 more)

### Community 34 - "👢 OmniCast SDK: Participant Kick & Ejection Guide"
Cohesion: 0.11
Nodes (18): 1. Architecture Overview, 2. Signaling JSON Protocol Contract, 3. SDK API Reference, 4. Data Models, 5. Flutter UI Integration Guide, 6. Under-The-Hood Lifecycle & Cleanup, A. Action Methods (`OmniCastClient` & `RoomManager`), A. Target User Handling (Viewer/Co-Host) (+10 more)

### Community 35 - "_OmniCastFlyingHeartsOverlayState"
Cohesion: 0.28
Nodes (9): GiftOverlayManager, _GiftOverlayManagerState, OmniCastFlyingHeartsOverlay, _OmniCastFlyingHeartsOverlayState, OmniCastVideoView, _OmniCastVideoViewState, State, StatefulWidget (+1 more)

### Community 36 - "omnicast_native_viewport_tracker.dart"
Cohesion: 0.14
Nodes (13): MediaController, build, child, crossAxisCount, _evaluateVisibility, itemHeight, mediaController, trackIds (+5 more)

### Community 37 - "🎙️ OmniCast SDK: Co-Host & Stage Moderation Guide"
Cohesion: 0.11
Nodes (18): 1. Architecture & Flow, 1. Waiting List Sheet (Host Screen), 2. Co-Host Stage Management Bottom Sheet (Moderation Controls), 2. Lifecycle: Viewer Request & Host Acceptance, 3. Lifecycle: Host Invites Viewer to Stage, 4. Host & Admin Moderation Controls, 5. Waiting List & Reactive Notifiers, 6. Ready-to-Use Flutter UI Examples (+10 more)

### Community 38 - "👥 OmniCast SDK: Viewers & Metadata Integration Guide"
Cohesion: 0.13
Nodes (14): 1. Overview & State Access Points, 2. Data Model: `OmniCastParticipant`, 3. Passing Metadata When Joining a Room, 4. Real-Time Lifecycle & State Sync, 5. The Easiest Way: 1-Line Pre-Built Viewers Bottom Sheet, 6. Building Custom UI Elements, 7. Best Practices & Performance Tuning, A. Horizontal Top-Bar Live Avatars Row (+6 more)

### Community 39 - "🚀 OmniCast SDK: Complete Developer & Media Rendering Guide"
Cohesion: 0.10
Nodes (20): 1. Core Philosophy: Zero Direct WebRTC Knowledge Required, 2. Video & Audio Rendering Widgets, 3. Media Controls, 4. Virtual Gifting System, 5. PK Battle Timer & Red vs Blue Score Engine, 6. Complete Sample Live Screen Implementation, A. All-In-One Adaptive Video Canvas (`OmniCastVideoCanvas`), A. Microphone Controls (+12 more)

### Community 41 - "omnicast_video_canvas.dart"
Cohesion: 0.11
Nodes (17): PkScore, RoomMode, build, _buildCoHostStage, _buildPKScoreHeader, _buildPKSplitScreen, _buildSoloScreen, child (+9 more)

## Knowledge Gaps
- **901 isolated node(s):** `config`, `_client`, `getLiveRooms`, `dispose`, `OmniCastTokenGenerator` (+896 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `RoomState` connect `RoomState` to `room_state.dart`, `core/omnicast_client.dart`, `media_controller.dart`, `room_manager.dart`, `pk_manager.dart`, `seat_manager.dart`, `data_channel_manager.dart`, `interaction_manager.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `MediaController` connect `omnicast_native_viewport_tracker.dart` to `core/omnicast_client.dart`, `media_controller.dart`, `omnicast_video_view.dart`, `omnicast_media_control_bar.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `MediaStreamManager` connect `omnicast_pk_battle_view.dart` to `core/omnicast_client.dart`, `media_controller.dart`, `webrtc_manager.dart`, `media_stream_manager.dart`, `omnicast_video_view.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `config`, `_client`, `getLiveRooms` to the rest of the system?**
  _901 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03076923076923077 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03076923076923077 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03508771929824561 - nodes in this community are weakly interconnected._