# Graph Report - omnicast_client  (2026-09-07)

## Corpus Check
- 115 files · ~74,523 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1909 nodes · 2321 edges · 85 communities (72 shown, 13 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a73aa7da`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- room_state.dart
- signaling_client.dart
- signaling_message.dart
- _
- media_controller.dart
- room_manager.dart
- webrtc_manager.dart
- pk_models.dart
- media_stream_manager.dart
- omnicast_flying_hearts_overlay.dart
- pk_manager.dart
- seat_manager.dart
- package:omnicast_client/omnicast_client.dart
- omnicast_client.dart
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
- omnicast_video_canvas.dart
- 🚀 OmniCast Client Flutter SDK
- room_event_models.dart
- ⚔️ OmniCast SDK: PK Battle Integration Guide
- omnicast_token_generator.dart
- package:flutter/foundation.dart
- CHANGELOG.md
- omnicast_api.dart
- 👢 OmniCast SDK: Participant Kick & Ejection Guide
- State
- omnicast_native_viewport_tracker.dart
- 🎙️ OmniCast SDK: Co-Host & Stage Moderation Guide
- 👥 OmniCast SDK: Viewers & Metadata Integration Guide
- 🚀 OmniCast SDK: Complete Developer & Media Rendering Guide
- handleRawMessage
- 🚀 OmniCast SDK Developer Quickstart Guide
- 🚪 OmniCast SDK: Room Management & Participant Ejection Guide
- 🔄 OmniCast SDK: Late-Join State Synchronization Guide
- 🎪 OmniCast SDK: Room Closure, Viewers List & Toggleable Entrance Banners Guide
- global_media_config.dart
- Win32Window
- AppDelegate
- 🍎 iOS Setup & Permissions Configuration Guide for OmniCast SDK
- live_room_screen.dart
- omnicast_dynamic_stage.dart
- my_application.cc
- media_control_bar.dart
- lobby_screen.dart
- omnicast_gifting_bottom_sheet.dart
- pk_score_progress_bar.dart
- omnicast_stage_grid.dart
- gift_modal.dart
- app_constants.dart
- StatelessWidget
- wWinMain
- omnicast_viewers_bottom_sheet.dart
- live_chat_view.dart
- manifest.json
- package:flutter/material.dart
- OmniCastClient
- pk_score_bar.dart
- dart:convert
- main.dart
- MainActivity.kt
- omnicast_example
- widget_test.dart
- LaunchImage.imageset/README.md
- bool?
- String?
- video_parameters.dart
- MediaStreamManager
- enterprise_optimization_test.dart
- headless_and_performance_test.dart
- RoomState
- late_join_and_customizable_stage_test.dart

## God Nodes (most connected - your core abstractions)
1. `_` - 175 edges
2. `Win32Window` - 24 edges
3. `🚀 OmniCast Client Flutter SDK` - 16 edges
4. `MessageHandler` - 12 edges
5. `🚀 OmniCast SDK Developer Quickstart Guide` - 12 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `OmniCastClient` - 10 edges
10. `RoomState` - 10 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  example/windows/runner/main.cpp → example/windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  example/windows/runner/win32_window.cpp → example/windows/runner/win32_window.h
- `_` --references--> `DataChannelManager`  [EXTRACTED]
  lib/src/core/omnicast_client.dart → lib/src/datachannel/data_channel_manager.dart
- `_` --references--> `InteractionManager`  [EXTRACTED]
  lib/src/core/omnicast_client.dart → lib/src/interaction/interaction_manager.dart
- `_` --references--> `PKManager`  [EXTRACTED]
  lib/src/core/omnicast_client.dart → lib/src/pk/pk_manager.dart

## Import Cycles
- None detected.

## Communities (85 total, 13 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.02
Nodes (84): ClientConnectionState get, _activePK, _activeRemoteUserIds, _activeSeats, activeSeatsNotifier, addActiveRemoteUser, addChatMessage, addInvite (+76 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.02
Nodes (95): _answerController, autoReconnect, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState (+87 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.02
Nodes (88): answer, balanceUpdate, candidate, chat, chatMessage, cohostLeft, createRoom, endRoom (+80 more)

### Community 3 - "_"
Cohesion: 0.01
Nodes (135): DataChannelManager get, ../interaction/interaction_manager.dart, InteractionManager get, _, acceptCoHostInvite, acceptCoHostRequest, acceptPKRequest, activeSeats (+127 more)

### Community 4 - "media_controller.dart"
Cohesion: 0.03
Nodes (63): audio_level_detector.dart, AudioLevelDetector get, global_media_config.dart, GlobalMediaConfig get, activeSpeakerNotifier, _adaptiveStreamingEnabled, audioDetector, _audioLevelDetector (+55 more)

### Community 5 - "room_manager.dart"
Cohesion: 0.04
Nodes (55): ../api/omnicast_api.dart, activeSeatsNotifier, activeViewersList, _api, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, closeRoom (+47 more)

### Community 6 - "webrtc_manager.dart"
Cohesion: 0.04
Nodes (46): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, createIceRestartOffer, dispose, downgradeCoHostToViewer (+38 more)

### Community 7 - "pk_models.dart"
Cohesion: 0.04
Nodes (46): bool get, double get, Duration get, DemoSession, isHost, isViewer, role, roomId (+38 more)

### Community 8 - "media_stream_manager.dart"
Cohesion: 0.06
Nodes (33): addListener, _aliases, attachRemoteStream, _changeNotifier, _currentParameters, dispose, getOrCreateRemoteRenderer, getRenderer (+25 more)

### Community 9 - "omnicast_flying_hearts_overlay.dart"
Cohesion: 0.09
Nodes (22): AnimationController, ../datachannel/data_channel_manager.dart, Key, build, controller, createState, dispose, drift (+14 more)

### Community 10 - "pk_manager.dart"
Cohesion: 0.06
Nodes (30): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+22 more)

### Community 11 - "seat_manager.dart"
Cohesion: 0.04
Nodes (50): acceptCoHostInvite, acceptSeatRequest, activeCoHostsList, activeSeats, activeSeatsNotifier, _bindSignalingListeners, _bindStateNotifiers, cancelSeatRequest (+42 more)

### Community 12 - "package:omnicast_client/omnicast_client.dart"
Cohesion: 0.14
Nodes (11): package:flutter_test/flutter_test.dart, package:omnicast_client/omnicast_client.dart, main, main, main, main, main, main (+3 more)

### Community 13 - "omnicast_client.dart"
Cohesion: 0.05
Nodes (40): package:permission_handler/permission_handler.dart, src/api/omnicast_api.dart, src/auth/omnicast_token_generator.dart, src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/datachannel/data_channel_manager.dart, src/interaction/interaction_manager.dart, src/media/audio_level_detector.dart (+32 more)

### Community 14 - "data_channel_manager.dart"
Cohesion: 0.07
Nodes (29): attachIncomingChannel, _bindDataChannel, _chatController, createPublisherChannel, _dataChannel, DataChannelManager, DataChannelReaction, dispose (+21 more)

### Community 15 - "room_models.dart"
Cohesion: 0.05
Nodes (44): ActiveLiveRoom, avatarUrl, ClientConnectionState, copyWith, createdAt, displayName, enableAudio, enableDynacast (+36 more)

### Community 16 - "seat_models.dart"
Cohesion: 0.09
Nodes (22): CoHostInvite, copyWith, createdAt, fromJson, hostId, inviteId, isCameraOff, isLocked (+14 more)

### Community 17 - "gift_overlay_manager.dart"
Cohesion: 0.05
Nodes (41): Alignment, ../auth/omnicast_token_generator.dart, Duration, apiKey, apiSecret, apiUrl, deriveApiUrl, deriveWebSocketUrl (+33 more)

### Community 18 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): DateTime, amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent (+16 more)

### Community 19 - "interaction_manager.dart"
Cohesion: 0.08
Nodes (23): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+15 more)

### Community 20 - "omnicast_pk_battle_view.dart"
Cohesion: 0.10
Nodes (19): Axis, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager, objectFit (+11 more)

### Community 21 - "omnicast_video_view.dart"
Cohesion: 0.10
Nodes (20): build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming, _initializeLazyRenderer (+12 more)

### Community 22 - "omnicast_media_control_bar.dart"
Cohesion: 0.13
Nodes (14): Color, IconData, activeColor, build, _CircleControlButton, icon, inactiveColor, isActive (+6 more)

### Community 23 - "webrtc_stats_monitor.dart"
Cohesion: 0.06
Nodes (30): bitrateKbps, currentStats, dispose, initial, interval, _isDisposed, jitterMs, _lastBytesReceived (+22 more)

### Community 24 - "omnicast_speaking_video_tile.dart"
Cohesion: 0.11
Nodes (17): AudioLevelDetector, audioDetector, avatarUrl, build, _buildAvatarPlaceholder, isCameraEnabled, isMicMuted, level (+9 more)

### Community 25 - "audio_level_detector.dart"
Cohesion: 0.13
Nodes (14): activeSpeakerNotifier, audioLevelsNotifier, dispose, _isDisposed, pollInterval, pollStats, _pollTimer, start (+6 more)

### Community 26 - "omnicast_video_canvas.dart"
Cohesion: 0.11
Nodes (17): PkScore, RoomMode, build, _buildCoHostStage, _buildPKScoreHeader, _buildPKSplitScreen, _buildSoloScreen, child (+9 more)

### Community 27 - "🚀 OmniCast Client Flutter SDK"
Cohesion: 0.06
Nodes (34): 1. Add dependency to `pubspec.yaml`, 1. Challenge & Accept PK, 1. Join a Live Room as a Viewer, 1. Send Chat & Virtual Gifts, 1. Send Metadata When Joining as a Viewer, 1. Video Resolution Presets (`VideoParameters`), 2. Configure Native Permissions, 2. Gift Banner Overlay Widget (`GiftOverlayManager`) (+26 more)

### Community 28 - "room_event_models.dart"
Cohesion: 0.33
Nodes (5): interaction_models.dart, pk_models.dart, room_models.dart, seat_models.dart, signaling_message.dart

### Community 29 - "⚔️ OmniCast SDK: PK Battle Integration Guide"
Cohesion: 0.09
Nodes (21): 1. PK Battle Architecture & Flow, 2. Signaling JSON Contracts, 3. SDK API Reference (`client.pk`), 4. Data Models & States, 5. Step-by-Step Flutter UI Integration, 6. Best Practices & Troubleshooting, A. Send PK Challenge (`pk_request`), B. Accept PK Challenge (`pk_accept`) (+13 more)

### Community 30 - "omnicast_token_generator.dart"
Cohesion: 0.50
Nodes (3): generate, OmniCastTokenGenerator, package:dart_jsonwebtoken/dart_jsonwebtoken.dart

### Community 31 - "package:flutter/foundation.dart"
Cohesion: 0.29
Nodes (6): enableLogging, error, log, OmniCastLogger, package:flutter/foundation.dart, static bool

### Community 33 - "omnicast_api.dart"
Cohesion: 0.18
Nodes (10): Client, ../core/omnicast_config.dart, _client, config, dispose, getLiveRooms, getRoom, OmniCastApi (+2 more)

### Community 34 - "👢 OmniCast SDK: Participant Kick & Ejection Guide"
Cohesion: 0.11
Nodes (18): 1. Architecture Overview, 2. Signaling JSON Protocol Contract, 3. SDK API Reference, 4. Data Models, 5. Flutter UI Integration Guide, 6. Under-The-Hood Lifecycle & Cleanup, A. Action Methods (`OmniCastClient` & `RoomManager`), A. Target User Handling (Viewer/Co-Host) (+10 more)

### Community 35 - "State"
Cohesion: 0.24
Nodes (11): LobbyScreen, _LobbyScreenState, MediaControlBar, _MediaControlBarState, OmniCastFlyingHeartsOverlay, _OmniCastFlyingHeartsOverlayState, OmniCastVideoView, _OmniCastVideoViewState (+3 more)

### Community 36 - "omnicast_native_viewport_tracker.dart"
Cohesion: 0.14
Nodes (13): MediaController, build, child, crossAxisCount, _evaluateVisibility, itemHeight, mediaController, OmniCastNativeViewportTracker (+5 more)

### Community 37 - "🎙️ OmniCast SDK: Co-Host & Stage Moderation Guide"
Cohesion: 0.11
Nodes (18): 1. Architecture & Flow, 1. Waiting List Sheet (Host Screen), 2. Co-Host Stage Management Bottom Sheet (Moderation Controls), 2. Lifecycle: Viewer Request & Host Acceptance, 3. Lifecycle: Host Invites Viewer to Stage, 4. Host & Admin Moderation Controls, 5. Waiting List & Reactive Notifiers, 6. Ready-to-Use Flutter UI Examples (+10 more)

### Community 38 - "👥 OmniCast SDK: Viewers & Metadata Integration Guide"
Cohesion: 0.13
Nodes (14): 1. Overview & State Access Points, 2. Data Model: `OmniCastParticipant`, 3. Passing Metadata When Joining a Room, 4. Real-Time Lifecycle & State Sync, 5. The Easiest Way: 1-Line Pre-Built Viewers Bottom Sheet, 6. Building Custom UI Elements, 7. Best Practices & Performance Tuning, A. Horizontal Top-Bar Live Avatars Row (+6 more)

### Community 39 - "🚀 OmniCast SDK: Complete Developer & Media Rendering Guide"
Cohesion: 0.10
Nodes (20): 1. Core Philosophy: Zero Direct WebRTC Knowledge Required, 2. Video & Audio Rendering Widgets, 3. Media Controls, 4. Virtual Gifting System, 5. PK Battle Timer & Red vs Blue Score Engine, 6. Complete Sample Live Screen Implementation, A. All-In-One Adaptive Video Canvas (`OmniCastVideoCanvas`), A. Microphone Controls (+12 more)

### Community 41 - "🚀 OmniCast SDK Developer Quickstart Guide"
Cohesion: 0.08
Nodes (24): 10. 🚪 Leaving Room, 1. 📦 Installation, 2. ⚡ SDK Initialization (Single Domain & Credentials), 3. 🎥 Create a Live Room (Host), 4. 👁️ Join a Live Room (Viewer), 5. 📺 Displaying Video Screen, 6. 👥 Real-Time Viewers List & Moderation, 7. 🎤 Co-Host & Multi-Guest Stage Management (+16 more)

### Community 42 - "🚪 OmniCast SDK: Room Management & Participant Ejection Guide"
Cohesion: 0.11
Nodes (17): 1. Handling on the Kicked User's Device:, 1. Overview & Architecture, 2. Handling on Other Viewers' Devices:, 2. How to Delete / End a Room (Host Action), 3. Handling Room Termination (Viewers & Lobby), 4. How to Remove / Kick a Participant from a Room, 5. Handling Ejection Events (Kicked User & Room Viewers), 6. Stage Demotion vs Full Room Kick (+9 more)

### Community 43 - "🔄 OmniCast SDK: Late-Join State Synchronization Guide"
Cohesion: 0.14
Nodes (13): 1. Architecture & How Late-Join Sync Works, 1. `OmniCastVideoCanvas`, 2. `OmniCastSpeakingVideoTile`, 2. The Authoritative Snapshot: `room_info_sync`, 3. What Gets Synchronized Automatically, 4. Reactive Flutter State Access Points, 5. Pre-Built Widgets with Automatic Late-Join Support, 6. Building Custom UI for Late-Join Scenarios (+5 more)

### Community 44 - "🎪 OmniCast SDK: Room Closure, Viewers List & Toggleable Entrance Banners Guide"
Cohesion: 0.12
Nodes (16): 1. Architecture & Lifecycle Overview, 2. 1. Host Ending the Room & Ejecting All Viewers, 3. 2. Viewing the Real-Time Viewers List, 4. 3. Real-Time Room Entrance Messages & On/Off Toggle, 5. Complete Ready-to-Use Flutter UI Screen Example, A. 1-Line Pre-built Modal Bottom Sheet, A. Entrance Event Stream & Data, A. Host Triggers Room Closure: (+8 more)

### Community 45 - "global_media_config.dart"
Cohesion: 0.22
Nodes (8): autoPauseOnBackground, defaultResolution, enableAdaptiveStreaming, enableDynacast, enableSimulcast, GlobalMediaConfig, VideoParameters, video_parameters.dart

### Community 46 - "Win32Window"
Cohesion: 0.05
Nodes (57): RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+49 more)

### Community 47 - "AppDelegate"
Cohesion: 0.06
Nodes (27): Any, Cocoa, AppDelegate, Bool, SceneDelegate, RunnerTests, RegisterGeneratedPlugins(), AppDelegate (+19 more)

### Community 48 - "🍎 iOS Setup & Permissions Configuration Guide for OmniCast SDK"
Cohesion: 0.29
Nodes (6): 1. 📝 `ios/Runner/Info.plist` Configuration, 2. 📦 `ios/Podfile` Permission Handler Macros, 3. 🛠️ CocoaPods Installation, 4. 📱 Requesting Permissions in Dart, 5. 💡 iOS Simulator vs Real Device Notice, 🍎 iOS Setup & Permissions Configuration Guide for OmniCast SDK

### Community 49 - "live_room_screen.dart"
Cohesion: 0.05
Nodes (42): _activeGiftNotification, _bindEventStreams, build, _buildHeaderOverlay, _buildVideoCanvas, _chatMessages, _client, createState (+34 more)

### Community 50 - "omnicast_dynamic_stage.dart"
Cohesion: 0.06
Nodes (30): avatarUrl, build, _build2x2Grid, _buildCoHostSlotBadge, _buildEmptyTile, _buildFullscreenSlot, _buildMainSeatBadge, _buildOccupiedTile (+22 more)

### Community 51 - "my_application.cc"
Cohesion: 0.09
Nodes (22): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+14 more)

### Community 52 - "media_control_bar.dart"
Cohesion: 0.08
Nodes (23): build, _buildCircleButton, _buildPillButton, _chatController, createState, dispose, isCameraOff, isCoHost (+15 more)

### Community 53 - "lobby_screen.dart"
Cohesion: 0.11
Nodes (17): dart:math, build, createState, dispose, _enterLiveRoom, _initLobbyClient, initState, _lobbyClient (+9 more)

### Community 54 - "omnicast_gifting_bottom_sheet.dart"
Cohesion: 0.11
Nodes (18): class, Function?, build, client, coinPrice, createState, emoji, gifts (+10 more)

### Community 55 - "pk_score_progress_bar.dart"
Cohesion: 0.12
Nodes (15): Gradient?, PKState, borderRadius, build, _formatTimer, height, hostGradient, opponentGradient (+7 more)

### Community 56 - "omnicast_stage_grid.dart"
Cohesion: 0.13
Nodes (14): build, _buildDefaultEmptySeat, _buildDefaultOccupiedSeat, childAspectRatio, client, crossAxisCount, crossAxisSpacing, _handleDefaultEmptySeatClick (+6 more)

### Community 57 - "gift_modal.dart"
Cohesion: 0.17
Nodes (12): ../config/app_constants.dart, DemoGift, build, createState, GiftModal, _GiftModalState, hostId, initState (+4 more)

### Community 58 - "app_constants.dart"
Cohesion: 0.15
Nodes (12): AppConstants, availableGifts, coins, defaultAndroidEmulator, defaultLanIP, defaultLocalhost, icon, id (+4 more)

### Community 59 - "StatelessWidget"
Cohesion: 0.10
Nodes (21): EdgeInsetsGeometry, _GiftBannerWidget, OmniCastDynamicStage, OmniCastPKBattleView, build, _buildDefaultEmptyState, _buildDefaultRoomCard, client (+13 more)

### Community 60 - "wWinMain"
Cohesion: 0.24
Nodes (9): wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), _In_, _In_opt_ (+1 more)

### Community 61 - "omnicast_viewers_bottom_sheet.dart"
Cohesion: 0.20
Nodes (11): build, client, enableHostKick, LiveRoomViewersDialog, OmniCastViewersBottomSheet, OmniCastViewersDialog, show, _showKickConfirmationDialog (+3 more)

### Community 62 - "live_chat_view.dart"
Cohesion: 0.20
Nodes (10): build, createState, didUpdateWidget, dispose, LiveChatView, _LiveChatViewState, messages, _scrollController (+2 more)

### Community 63 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 64 - "package:flutter/material.dart"
Cohesion: 0.17
Nodes (7): dart:async, package:flutter/material.dart, main, main, main, main, main

### Community 65 - "OmniCastClient"
Cohesion: 0.22
Nodes (8): ../core/omnicast_client.dart, OmniCastClient, build, client, OmniCastSeatRequestsBottomSheet, OmniCastSeatRequestsBuilder, show, ../models/seat_models.dart

### Community 66 - "pk_score_bar.dart"
Cohesion: 0.25
Nodes (7): build, hostName, hostScore, opponentName, opponentScore, PKScoreBar, remainingSeconds

### Community 67 - "dart:convert"
Cohesion: 0.29
Nodes (5): dart:convert, package:http/http.dart, package:http/testing.dart, main, main

### Community 68 - "main.dart"
Cohesion: 0.40
Nodes (4): build, main, OmniCastDemoApp, screens/lobby_screen.dart

### Community 80 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

## Knowledge Gaps
- **1367 isolated node(s):** `AppConstants`, `defaultLocalhost`, `defaultAndroidEmulator`, `defaultLanIP`, `availableGifts` (+1362 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `media_controller.dart`, `room_manager.dart`, `pk_models.dart`, `media_stream_manager.dart`, `omnicast_flying_hearts_overlay.dart`, `pk_manager.dart`, `seat_manager.dart`, `data_channel_manager.dart`, `gift_overlay_manager.dart`, `interaction_manager.dart`, `omnicast_pk_battle_view.dart`, `omnicast_speaking_video_tile.dart`, `audio_level_detector.dart`, `package:flutter/foundation.dart`, `omnicast_api.dart`, `omnicast_native_viewport_tracker.dart`, `global_media_config.dart`, `pk_score_progress_bar.dart`, `omnicast_stage_grid.dart`, `omnicast_viewers_bottom_sheet.dart`, `live_chat_view.dart`, `package:flutter/material.dart`, `OmniCastClient`, `MediaStreamManager`, `RoomState`?**
  _High betweenness centrality (0.150) - this node is a cross-community bridge._
- **Why does `OmniCastClient` connect `OmniCastClient` to `_`, `live_room_screen.dart`, `omnicast_dynamic_stage.dart`, `lobby_screen.dart`, `omnicast_gifting_bottom_sheet.dart`, `omnicast_stage_grid.dart`, `omnicast_video_canvas.dart`, `StatelessWidget`, `omnicast_viewers_bottom_sheet.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `RoomState` connect `RoomState` to `room_state.dart`, `_`, `media_controller.dart`, `room_manager.dart`, `pk_manager.dart`, `seat_manager.dart`, `data_channel_manager.dart`, `interaction_manager.dart`, `omnicast_speaking_video_tile.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `AppConstants`, `defaultLocalhost`, `defaultAndroidEmulator` to the rest of the system?**
  _1367 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.023529411764705882 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.020833333333333332 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02247191011235955 - nodes in this community are weakly interconnected._