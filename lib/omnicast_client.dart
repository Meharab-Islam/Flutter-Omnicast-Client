/// OmniCast Live Streaming & WebRTC SFU Client SDK for Flutter.
///
/// Designed for high-scale interactive live broadcasting, WebRTC SFU media routing, multi-guest stages, and PK battles.
library;

// Core Facade, Configuration & Auth Token Generator
export 'src/core/omnicast_client.dart';
export 'src/core/omnicast_config.dart';
export 'src/auth/omnicast_token_generator.dart';
export 'src/api/omnicast_api.dart';

// Sub-Module Controllers & Managers
export 'src/room/room_manager.dart';
export 'src/media/media_controller.dart';
export 'src/media/media_stream_manager.dart';
export 'src/media/video_parameters.dart';
export 'src/media/global_media_config.dart';
export 'src/media/audio_level_detector.dart';
export 'src/seats/seat_manager.dart';
export 'src/interaction/interaction_manager.dart';
export 'src/datachannel/data_channel_manager.dart';
export 'src/pk/pk_manager.dart';
export 'src/signaling/signaling_client.dart';
export 'src/webrtc/webrtc_manager.dart';
export 'src/webrtc/webrtc_stats_monitor.dart';

// Reactive State
export 'src/state/room_state.dart';

// Models
export 'src/models/room_models.dart';
export 'src/models/pk_models.dart';
export 'src/models/interaction_models.dart';
export 'src/models/seat_models.dart';
export 'src/models/signaling_message.dart';

// UI Widgets
export 'src/widgets/omnicast_video_view.dart';
export 'src/widgets/omnicast_video_canvas.dart';
export 'src/widgets/omnicast_pk_battle_view.dart';
export 'src/widgets/pk_score_progress_bar.dart';
export 'src/widgets/gift_overlay_manager.dart';
export 'src/widgets/omnicast_speaking_video_tile.dart';
export 'src/widgets/omnicast_media_control_bar.dart';
export 'src/widgets/omnicast_native_viewport_tracker.dart';
export 'src/widgets/omnicast_flying_hearts_overlay.dart';
export 'src/widgets/omnicast_gifting_bottom_sheet.dart';
export 'src/widgets/omnicast_viewers_bottom_sheet.dart';
export 'src/utils/omnicast_logger.dart';
export 'package:permission_handler/permission_handler.dart';
