# Graph Report - omnicast_client  (2026-09-10)

## Corpus Check
- 122 files · ~77,986 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1986 nodes · 2425 edges · 85 communities (78 shown, 7 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `62126a1b`
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
- test_realtime_sync.dart
- ⚔️ OmniCast SDK: PK Battle Integration Guide
- omnicast_gifting_bottom_sheet.dart
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
- bool get
- enterprise_optimization_test.dart
- room_event_models.dart
- omnicast_stage_grid.dart
- lobby_screen.dart
- StatelessWidget
- omnicast_room_list_view.dart
- wWinMain
- omnicast_viewers_bottom_sheet.dart
- OmniCastClient
- manifest.json
- package:flutter/material.dart
- omnicast_live_room.dart
- pk_score_bar.dart
- dart:convert
- omnicast_live_chat.dart
- MainActivity.kt
- omnicast_example
- LaunchImage.imageset/README.md
- omnicast_live_header.dart
- bool?
- String?
- video_parameters.dart
- pk_score_progress_bar.dart
- gift_modal.dart
- app_constants.dart
- 🚀 OmniCast Flutter SDK — Plug-and-Play Quickstart Guide
- RoomState

## God Nodes (most connected - your core abstractions)
1. `_` - 169 edges
2. `Win32Window` - 24 edges
3. `🚀 OmniCast Client Flutter SDK` - 16 edges
4. `OmniCastClient` - 14 edges
5. `MessageHandler` - 12 edges
6. `🚀 OmniCast SDK Developer Quickstart Guide` - 12 edges
7. `FlutterWindow` - 10 edges
8. `Create` - 10 edges
9. `WndProc` - 10 edges
10. `MessageHandler` - 9 edges

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

## Communities (85 total, 7 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.02
Nodes (80): _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addParticipant, addSeatRequest (+72 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.03
Nodes (65): ClientConnectionState get, _answerController, autoReconnect, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect (+57 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (55): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, gift (+47 more)

### Community 3 - "_"
Cohesion: 0.02
Nodes (128): DataChannelManager get, ../interaction/interaction_manager.dart, InteractionManager get, _, acceptCoHostInvite, acceptCoHostRequest, activeViewersList, _api (+120 more)

### Community 4 - "media_controller.dart"
Cohesion: 0.03
Nodes (60): audio_level_detector.dart, AudioLevelDetector get, global_media_config.dart, GlobalMediaConfig get, activeSpeakerNotifier, _adaptiveStreamingEnabled, audioDetector, _audioLevelDetector (+52 more)

### Community 5 - "room_manager.dart"
Cohesion: 0.04
Nodes (56): ../api/omnicast_api.dart, activeSeatsNotifier, activeViewersList, _api, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, closeRoom (+48 more)

### Community 6 - "webrtc_manager.dart"
Cohesion: 0.04
Nodes (55): Future, addLocalMediaTracks, addMusicTrack, addRemoteCandidate, addScreenTrack, _audioSender, closePeerConnection, createAndSetLocalOffer (+47 more)

### Community 7 - "pk_models.dart"
Cohesion: 0.05
Nodes (37): double get, Duration get, int get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo (+29 more)

### Community 8 - "media_stream_manager.dart"
Cohesion: 0.04
Nodes (50): _aliases, attachRemoteScreenStream, attachRemoteStream, _currentParameters, dispose, getOrCreateRemoteRenderer, getOrCreateRemoteScreenRenderer, getRemoteScreenRenderer (+42 more)

### Community 9 - "omnicast_flying_hearts_overlay.dart"
Cohesion: 0.09
Nodes (22): AnimationController, ../datachannel/data_channel_manager.dart, Key, build, controller, createState, dispose, drift (+14 more)

### Community 10 - "pk_manager.dart"
Cohesion: 0.06
Nodes (30): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+22 more)

### Community 11 - "seat_manager.dart"
Cohesion: 0.04
Nodes (45): acceptCoHostInvite, acceptSeatRequest, activeCoHostsList, activeSeatsNotifier, _bindSignalingListeners, _bindStateNotifiers, cancelSeatRequest, demoteToViewer (+37 more)

### Community 12 - "package:omnicast_client/omnicast_client.dart"
Cohesion: 0.12
Nodes (13): package:flutter_test/flutter_test.dart, package:flutter/widgets.dart, package:omnicast_client/omnicast_client.dart, main, main, main, main, main (+5 more)

### Community 13 - "omnicast_client.dart"
Cohesion: 0.04
Nodes (44): package:permission_handler/permission_handler.dart, src/api/omnicast_api.dart, src/auth/omnicast_token_generator.dart, src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/datachannel/data_channel_manager.dart, src/interaction/interaction_manager.dart, src/media/audio_level_detector.dart (+36 more)

### Community 14 - "data_channel_manager.dart"
Cohesion: 0.06
Nodes (32): attachIncomingChannel, _bindDataChannel, broadcast, _chatController, createPublisherChannel, _dataChannel, DataChannelManager, DataChannelReaction (+24 more)

### Community 15 - "room_models.dart"
Cohesion: 0.05
Nodes (44): ActiveLiveRoom, avatarUrl, ClientConnectionState, copyWith, createdAt, displayName, enableAudio, enableDynacast (+36 more)

### Community 16 - "seat_models.dart"
Cohesion: 0.08
Nodes (23): DateTime, CoHostInvite, copyWith, createdAt, fromJson, hostId, inviteId, isCameraOff (+15 more)

### Community 17 - "gift_overlay_manager.dart"
Cohesion: 0.08
Nodes (25): Alignment, _ActiveGiftItem, _activeGifts, bannerAlignment, build, child, combo, createState (+17 more)

### Community 18 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent, giftIconUrl (+16 more)

### Community 19 - "interaction_manager.dart"
Cohesion: 0.07
Nodes (27): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+19 more)

### Community 20 - "omnicast_pk_battle_view.dart"
Cohesion: 0.10
Nodes (19): Axis, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager, objectFit (+11 more)

### Community 21 - "omnicast_video_view.dart"
Cohesion: 0.10
Nodes (19): build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming, _initializeLazyRenderer (+11 more)

### Community 22 - "omnicast_media_control_bar.dart"
Cohesion: 0.13
Nodes (14): Color, IconData, activeColor, build, _CircleControlButton, icon, inactiveColor, isActive (+6 more)

### Community 23 - "webrtc_stats_monitor.dart"
Cohesion: 0.06
Nodes (30): bitrateKbps, currentStats, dispose, initial, interval, _isDisposed, jitterMs, _lastBytesReceived (+22 more)

### Community 24 - "omnicast_speaking_video_tile.dart"
Cohesion: 0.12
Nodes (16): AudioLevelDetector, audioDetector, avatarUrl, build, _buildAvatarPlaceholder, isCameraEnabled, isMicMuted, level (+8 more)

### Community 25 - "audio_level_detector.dart"
Cohesion: 0.12
Nodes (15): dart:async, activeSpeakerNotifier, audioLevelsNotifier, dispose, _isDisposed, pollInterval, pollStats, _pollTimer (+7 more)

### Community 26 - "omnicast_video_canvas.dart"
Cohesion: 0.11
Nodes (17): PkScore, RoomMode, build, _buildCoHostStage, _buildPKScoreHeader, _buildPKSplitScreen, _buildSoloScreen, child (+9 more)

### Community 27 - "🚀 OmniCast Client Flutter SDK"
Cohesion: 0.06
Nodes (34): 1. Add dependency to `pubspec.yaml`, 1. Challenge & Accept PK, 1. Join a Live Room as a Viewer, 1. Send Chat & Virtual Gifts, 1. Send Metadata When Joining as a Viewer, 1. Video Resolution Presets (`VideoParameters`), 2. Configure Native Permissions, 2. Gift Banner Overlay Widget (`GiftOverlayManager`) (+26 more)

### Community 28 - "test_realtime_sync.dart"
Cohesion: 0.08
Nodes (25): dart:io, Map, apiKey, apiSecret, approveJoinReceived, close, delayed, fakeSdpOffer (+17 more)

### Community 29 - "⚔️ OmniCast SDK: PK Battle Integration Guide"
Cohesion: 0.09
Nodes (21): 1. PK Battle Architecture & Flow, 2. Signaling JSON Contracts, 3. SDK API Reference (`client.pk`), 4. Data Models & States, 5. Step-by-Step Flutter UI Integration, 6. Best Practices & Troubleshooting, A. Send PK Challenge (`pk_request`), B. Accept PK Challenge (`pk_accept`) (+13 more)

### Community 30 - "omnicast_gifting_bottom_sheet.dart"
Cohesion: 0.12
Nodes (16): class, Function?, build, client, coinPrice, createState, emoji, gifts (+8 more)

### Community 31 - "package:flutter/foundation.dart"
Cohesion: 0.25
Nodes (7): enableLogging, error, log, OmniCastLogger, warn, package:flutter/foundation.dart, static bool

### Community 33 - "omnicast_api.dart"
Cohesion: 0.18
Nodes (10): Client, ../core/omnicast_config.dart, _client, config, dispose, getLiveRooms, getRoom, OmniCastApi (+2 more)

### Community 34 - "👢 OmniCast SDK: Participant Kick & Ejection Guide"
Cohesion: 0.11
Nodes (18): 1. Architecture Overview, 2. Signaling JSON Protocol Contract, 3. SDK API Reference, 4. Data Models, 5. Flutter UI Integration Guide, 6. Under-The-Hood Lifecycle & Cleanup, A. Action Methods (`OmniCastClient` & `RoomManager`), A. Target User Handling (Viewer/Co-Host) (+10 more)

### Community 35 - "State"
Cohesion: 0.21
Nodes (13): LiveRoomScreen, _LiveRoomScreenState, LobbyScreen, _LobbyScreenState, OmniCastFlyingHeartsOverlay, _OmniCastFlyingHeartsOverlayState, OmniCastGiftingBottomSheet, _OmniCastGiftingBottomSheetState (+5 more)

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
Nodes (40): _activeGiftNotification, _bindEventStreams, build, _buildHeaderOverlay, _buildVideoCanvas, _chatMessages, _client, createState (+32 more)

### Community 50 - "omnicast_dynamic_stage.dart"
Cohesion: 0.06
Nodes (30): avatarUrl, build, _build2x2Grid, _buildCoHostSlotBadge, _buildEmptyTile, _buildFullscreenSlot, _buildMainSeatBadge, _buildOccupiedTile (+22 more)

### Community 51 - "my_application.cc"
Cohesion: 0.09
Nodes (22): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+14 more)

### Community 52 - "media_control_bar.dart"
Cohesion: 0.05
Nodes (44): build, _buildCircleButton, _buildPillButton, _chatController, createState, dispose, isCameraOff, isCoHost (+36 more)

### Community 53 - "bool get"
Cohesion: 0.20
Nodes (9): bool get, DemoSession, isHost, isViewer, role, roomId, serverUrl, userId (+1 more)

### Community 54 - "enterprise_optimization_test.dart"
Cohesion: 0.27
Nodes (4): dart:typed_data, package:omnicast_client/src/webrtc/webrtc_manager.dart, main, main

### Community 55 - "room_event_models.dart"
Cohesion: 0.33
Nodes (5): interaction_models.dart, pk_models.dart, room_models.dart, seat_models.dart, signaling_message.dart

### Community 56 - "omnicast_stage_grid.dart"
Cohesion: 0.13
Nodes (14): build, _buildDefaultEmptySeat, _buildDefaultOccupiedSeat, childAspectRatio, client, crossAxisCount, crossAxisSpacing, _handleDefaultEmptySeatClick (+6 more)

### Community 57 - "lobby_screen.dart"
Cohesion: 0.11
Nodes (17): dart:math, build, createState, dispose, _enterLiveRoom, _initLobbyClient, initState, _lobbyClient (+9 more)

### Community 58 - "StatelessWidget"
Cohesion: 0.12
Nodes (15): build, main, OmniCastDemoApp, _GiftBannerWidget, OmniCastDynamicStage, OmniCastLiveRoom, OmniCastPKBattleView, OmniCastSpeakingVideoTile (+7 more)

### Community 59 - "omnicast_room_list_view.dart"
Cohesion: 0.17
Nodes (11): EdgeInsetsGeometry, build, _buildDefaultEmptyState, _buildDefaultRoomCard, client, OmniCastLiveRoomsBuilder, OmniCastRoomListView, padding (+3 more)

### Community 60 - "wWinMain"
Cohesion: 0.24
Nodes (9): wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), _In_, _In_opt_ (+1 more)

### Community 61 - "omnicast_viewers_bottom_sheet.dart"
Cohesion: 0.18
Nodes (12): ../core/omnicast_client.dart, build, client, enableHostKick, LiveRoomViewersDialog, OmniCastViewersBottomSheet, OmniCastViewersDialog, show (+4 more)

### Community 62 - "OmniCastClient"
Cohesion: 0.25
Nodes (7): OmniCastClient, build, client, OmniCastSeatRequestsBottomSheet, OmniCastSeatRequestsBuilder, show, ../models/seat_models.dart

### Community 63 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 64 - "package:flutter/material.dart"
Cohesion: 0.14
Nodes (8): main, package:flutter/material.dart, package:omnicast_example/main.dart, main, main, main, main, main

### Community 65 - "omnicast_live_room.dart"
Cohesion: 0.10
Nodes (20): gift_overlay_manager.dart, build, client, customStage, hostAvatarUrl, hostDisplayName, isFollowing, onClosePressed (+12 more)

### Community 66 - "pk_score_bar.dart"
Cohesion: 0.25
Nodes (7): build, hostName, hostScore, opponentName, opponentScore, PKScoreBar, remainingSeconds

### Community 67 - "dart:convert"
Cohesion: 0.18
Nodes (8): dart:convert, generate, OmniCastTokenGenerator, package:crypto/crypto.dart, package:http/http.dart, package:http/testing.dart, main, main

### Community 68 - "omnicast_live_chat.dart"
Cohesion: 0.04
Nodes (46): ../auth/omnicast_token_generator.dart, Duration, build, createState, didUpdateWidget, dispose, LiveChatView, _LiveChatViewState (+38 more)

### Community 73 - "omnicast_live_header.dart"
Cohesion: 0.11
Nodes (18): build, client, createState, dispose, _formatDuration, hostAvatarUrl, hostDisplayName, initState (+10 more)

### Community 80 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

### Community 82 - "pk_score_progress_bar.dart"
Cohesion: 0.12
Nodes (15): Gradient?, PKState, borderRadius, build, _formatTimer, height, hostGradient, opponentGradient (+7 more)

### Community 83 - "gift_modal.dart"
Cohesion: 0.17
Nodes (12): ../config/app_constants.dart, DemoGift, build, createState, GiftModal, _GiftModalState, hostId, initState (+4 more)

### Community 84 - "app_constants.dart"
Cohesion: 0.15
Nodes (12): AppConstants, availableGifts, coins, defaultAndroidEmulator, defaultLanIP, defaultLocalhost, icon, id (+4 more)

### Community 85 - "🚀 OmniCast Flutter SDK — Plug-and-Play Quickstart Guide"
Cohesion: 0.17
Nodes (11): 1. Video Stage (`OmniCastDynamicStage` or `OmniCastVideoView`), 2. Real-Time Chat & Join/Leave Overlay (`OmniCastLiveChat`), 3. Header Bar with Viewers Counter (`OmniCastLiveHeader`), ⚡ 3-Line Ultra Quickstart (Turnkey Live Room), 4. Interactive Bottom Action Bar (`OmniCastLiveBottomBar`), 🧩 Building a Custom Live Layout, 🛡️ Built-in Zero-Config Features, 🎙️ Co-Host & Multi-Guest Stage Management (+3 more)

### Community 88 - "RoomState"
Cohesion: 0.67
Nodes (3): ChangeNotifier, MediaStreamManager, RoomState

## Knowledge Gaps
- **1411 isolated node(s):** `AppConstants`, `defaultLocalhost`, `defaultAndroidEmulator`, `defaultLanIP`, `availableGifts` (+1406 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `media_controller.dart`, `room_manager.dart`, `media_stream_manager.dart`, `omnicast_flying_hearts_overlay.dart`, `pk_manager.dart`, `seat_manager.dart`, `data_channel_manager.dart`, `room_models.dart`, `gift_overlay_manager.dart`, `interaction_manager.dart`, `omnicast_pk_battle_view.dart`, `webrtc_stats_monitor.dart`, `audio_level_detector.dart`, `package:flutter/foundation.dart`, `omnicast_api.dart`, `omnicast_native_viewport_tracker.dart`, `global_media_config.dart`, `bool get`, `omnicast_stage_grid.dart`, `omnicast_viewers_bottom_sheet.dart`, `OmniCastClient`, `omnicast_live_chat.dart`, `omnicast_live_header.dart`, `pk_score_progress_bar.dart`, `RoomState`?**
  _High betweenness centrality (0.156) - this node is a cross-community bridge._
- **Why does `OmniCastClient` connect `OmniCastClient` to `omnicast_live_room.dart`, `_`, `omnicast_live_chat.dart`, `omnicast_live_header.dart`, `live_room_screen.dart`, `omnicast_dynamic_stage.dart`, `media_control_bar.dart`, `omnicast_stage_grid.dart`, `lobby_screen.dart`, `omnicast_video_canvas.dart`, `omnicast_room_list_view.dart`, `omnicast_viewers_bottom_sheet.dart`, `omnicast_gifting_bottom_sheet.dart`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Why does `MediaStreamManager` connect `RoomState` to `_`, `media_controller.dart`, `webrtc_manager.dart`, `media_stream_manager.dart`, `omnicast_pk_battle_view.dart`, `omnicast_video_view.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `AppConstants`, `defaultLocalhost`, `defaultAndroidEmulator` to the rest of the system?**
  _1411 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.024691358024691357 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.030303030303030304 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03571428571428571 - nodes in this community are weakly interconnected._