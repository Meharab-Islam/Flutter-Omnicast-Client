import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../webrtc/webrtc_manager.dart';

/// Real-time WebRTC audio energy and active speaker detector.
/// Polls [RTCPeerConnection.getStats] to extract normalized decibel levels (0.0 to 1.0).
class AudioLevelDetector {
  final WebRTCManager _webRTCManager;
  final Duration pollInterval;

  Timer? _pollTimer;
  bool _isDisposed = false;

  /// Map of trackId or userId -> audioLevel (0.0 = silence, 1.0 = maximum volume)
  final ValueNotifier<Map<String, double>> audioLevelsNotifier = ValueNotifier<Map<String, double>>({});

  /// Identifier of the currently loudest speaker
  final ValueNotifier<String?> activeSpeakerNotifier = ValueNotifier<String?>(null);

  AudioLevelDetector({
    required WebRTCManager webRTCManager,
    this.pollInterval = const Duration(milliseconds: 200),
  }) : _webRTCManager = webRTCManager;

  /// Starts polling audio levels from active WebRTC PeerConnection stats.
  void start() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => pollStats());
  }

  /// Manually polls audio stats for active audio tracks.
  Future<void> pollStats() async {
    if (_isDisposed) return;
    final pc = _webRTCManager.peerConnection;
    if (pc == null) return;

    try {
      final stats = await pc.getStats();
      final currentLevels = <String, double>{};
      String? loudestSpeakerId;
      double maxLevel = 0.05; // Minimum speech activity threshold

      for (final report in stats) {
        if (report.values.containsKey('audioLevel')) {
          final level = (report.values['audioLevel'] as num?)?.toDouble() ?? 0.0;
          final trackId = report.values['trackIdentifier'] as String? ?? report.id;

          currentLevels[trackId] = level;

          if (level > maxLevel) {
            maxLevel = level;
            loudestSpeakerId = trackId;
          }
        }
      }

      if (!_isDisposed) {
        audioLevelsNotifier.value = currentLevels;
        activeSpeakerNotifier.value = loudestSpeakerId;
      }
    } catch (_) {
      // Ignored during connection handshakes or renegotiations
    }
  }

  /// Stops audio polling.
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Cleans up internal timers and notifiers.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    stop();
    audioLevelsNotifier.dispose();
    activeSpeakerNotifier.dispose();
  }
}
