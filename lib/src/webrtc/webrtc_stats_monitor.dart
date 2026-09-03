import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../utils/omnicast_logger.dart';

/// Rating describing WebRTC network stream quality.
enum NetworkQualityRating {
  excellent,
  good,
  fair,
  poor,
  bad,
  unknown,
}

/// Snapshot of real-time WebRTC network metrics (packet loss, jitter, RTT, bitrate).
class NetworkQualityStats {
  final double packetLossPercent;
  final double jitterMs;
  final double rttMs;
  final double bitrateKbps;
  final int totalPacketsLost;
  final int totalPacketsReceived;
  final int totalPacketsSent;
  final NetworkQualityRating rating;
  final DateTime timestamp;

  const NetworkQualityStats({
    this.packetLossPercent = 0.0,
    this.jitterMs = 0.0,
    this.rttMs = 0.0,
    this.bitrateKbps = 0.0,
    this.totalPacketsLost = 0,
    this.totalPacketsReceived = 0,
    this.totalPacketsSent = 0,
    this.rating = NetworkQualityRating.unknown,
    required this.timestamp,
  });

  factory NetworkQualityStats.initial() {
    return NetworkQualityStats(
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'packet_loss_percent': packetLossPercent,
        'jitter_ms': jitterMs,
        'rtt_ms': rttMs,
        'bitrate_kbps': bitrateKbps,
        'total_packets_lost': totalPacketsLost,
        'total_packets_received': totalPacketsReceived,
        'total_packets_sent': totalPacketsSent,
        'rating': rating.name,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Periodically polls [RTCPeerConnection.getStats] to extract real-time jitter, packet loss, RTT, and bitrate.
class WebRTCStatsMonitor {
  final Future<RTCPeerConnection?> Function() _getPeerConnection;
  final Duration interval;

  Timer? _pollingTimer;
  bool _isDisposed = false;

  int _lastBytesReceived = 0;
  int _lastBytesSent = 0;
  DateTime? _lastTimestamp;

  final ValueNotifier<NetworkQualityStats> qualityNotifier =
      ValueNotifier<NetworkQualityStats>(NetworkQualityStats.initial());
  final StreamController<NetworkQualityStats> _statsStreamController =
      StreamController<NetworkQualityStats>.broadcast();

  WebRTCStatsMonitor({
    required Future<RTCPeerConnection?> Function() getPeerConnection,
    this.interval = const Duration(seconds: 2),
  }) : _getPeerConnection = getPeerConnection;

  NetworkQualityStats get currentStats => qualityNotifier.value;
  Stream<NetworkQualityStats> get onStatsUpdated => _statsStreamController.stream;

  /// Starts the periodic stats polling loop.
  void start() {
    if (_isDisposed) return;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => pollStats());
  }

  /// Stops stats polling.
  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Performs a single manual getStats() snapshot and parses inbound/outbound/candidate-pair metrics.
  Future<NetworkQualityStats?> pollStats() async {
    if (_isDisposed) return null;

    final pc = await _getPeerConnection();
    if (pc == null) return null;

    try {
      final reports = await pc.getStats();
      if (_isDisposed) return null;

      var packetsLost = 0;
      var packetsReceived = 0;
      var packetsSent = 0;
      var currentBytesReceived = 0;
      var currentBytesSent = 0;
      var maxJitter = 0.0;
      var currentRtt = 0.0;

      for (final report in reports) {
        final values = report.values;
        final type = report.type;

        if (type == 'inbound-rtp' || values.containsKey('packetsLost')) {
          final lost = (values['packetsLost'] as num?)?.toInt() ?? 0;
          final received = (values['packetsReceived'] as num?)?.toInt() ?? 0;
          final bytes = (values['bytesReceived'] as num?)?.toInt() ?? 0;
          final jitter = (values['jitter'] as num?)?.toDouble() ?? 0.0;

          packetsLost += lost;
          packetsReceived += received;
          currentBytesReceived += bytes;
          if (jitter > maxJitter) {
            maxJitter = jitter;
          }
        } else if (type == 'outbound-rtp' || values.containsKey('packetsSent')) {
          final sent = (values['packetsSent'] as num?)?.toInt() ?? 0;
          final bytes = (values['bytesSent'] as num?)?.toInt() ?? 0;
          packetsSent += sent;
          currentBytesSent += bytes;
        } else if (type == 'candidate-pair' || values.containsKey('currentRoundTripTime')) {
          final rtt = (values['currentRoundTripTime'] as num?)?.toDouble() ??
              (values['roundTripTime'] as num?)?.toDouble() ??
              0.0;
          if (rtt > currentRtt) {
            currentRtt = rtt;
          }
        }
      }

      final now = DateTime.now();
      double bitrateKbps = 0.0;
      if (_lastTimestamp != null) {
        final durationSeconds = now.difference(_lastTimestamp!).inMilliseconds / 1000.0;
        if (durationSeconds > 0) {
          final deltaBytes = (currentBytesReceived - _lastBytesReceived) + (currentBytesSent - _lastBytesSent);
          if (deltaBytes > 0) {
            bitrateKbps = (deltaBytes * 8.0) / (durationSeconds * 1000.0);
          }
        }
      }

      _lastBytesReceived = currentBytesReceived;
      _lastBytesSent = currentBytesSent;
      _lastTimestamp = now;

      // Compute packet loss percentage
      final totalPackets = packetsLost + packetsReceived;
      final packetLossPercent = totalPackets > 0 ? (packetsLost / totalPackets) * 100.0 : 0.0;

      // Jitter in ms (WebRTC report may give seconds e.g. 0.015s = 15ms)
      final jitterMs = maxJitter > 1.0 ? maxJitter : maxJitter * 1000.0;
      final rttMs = currentRtt > 1.0 ? currentRtt : currentRtt * 1000.0;

      // Determine Quality Rating
      NetworkQualityRating rating;
      if (packetLossPercent < 2.0 && rttMs < 100.0 && jitterMs < 30.0) {
        rating = NetworkQualityRating.excellent;
      } else if (packetLossPercent < 5.0 && rttMs < 200.0 && jitterMs < 50.0) {
        rating = NetworkQualityRating.good;
      } else if (packetLossPercent < 10.0 && rttMs < 350.0) {
        rating = NetworkQualityRating.fair;
      } else if (packetLossPercent < 20.0) {
        rating = NetworkQualityRating.poor;
      } else {
        rating = NetworkQualityRating.bad;
      }

      final stats = NetworkQualityStats(
        packetLossPercent: double.parse(packetLossPercent.toStringAsFixed(2)),
        jitterMs: double.parse(jitterMs.toStringAsFixed(1)),
        rttMs: double.parse(rttMs.toStringAsFixed(1)),
        bitrateKbps: double.parse(bitrateKbps.toStringAsFixed(1)),
        totalPacketsLost: packetsLost,
        totalPacketsReceived: packetsReceived,
        totalPacketsSent: packetsSent,
        rating: rating,
        timestamp: now,
      );

      qualityNotifier.value = stats;
      _statsStreamController.add(stats);
      return stats;
    } catch (e) {
      OmniCastLogger.error('[WebRTCStatsMonitor] Error polling getStats: $e');
      return null;
    }
  }

  /// Cleans up timers, notifiers, and stream controllers.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    stop();
    qualityNotifier.dispose();
    _statsStreamController.close();
  }
}
