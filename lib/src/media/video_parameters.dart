/// Specifies video capture resolution, framerate, bitrates, and hardware constraints
/// for WebRTC publishing and local previews.
class VideoParameters {
  final int width;
  final int height;
  final int frameRate;
  final int? maxBitrate;
  final String facingMode;

  const VideoParameters({
    required this.width,
    required this.height,
    this.frameRate = 24,
    this.maxBitrate,
    this.facingMode = 'user',
  });

  /// 480p Smooth (Bandwidth-Friendly & Android Optimized): 640x480 @ 24fps (Max 800 kbps)
  /// Recommended default to prevent packet loss, hardware encoder crashes, and green/pink glitches.
  static const VideoParameters presetSmooth480p = VideoParameters(
    width: 640,
    height: 480,
    frameRate: 24,
    maxBitrate: 800000,
    facingMode: 'user',
  );

  /// 720p HD: 1280x720 @ 30fps (Standard mobile live streaming preset)
  static const VideoParameters presetHD720p = VideoParameters(
    width: 1280,
    height: 720,
    frameRate: 30,
    maxBitrate: 2500000,
    facingMode: 'user',
  );

  /// 1080p Full HD: 1920x1080 @ 30fps (Recommended for studio/high-bandwidth hosts)
  static const VideoParameters presetFHD1080p = VideoParameters(
    width: 1920,
    height: 1080,
    frameRate: 30,
    maxBitrate: 4500000,
    facingMode: 'user',
  );

  /// 540p QHD: 960x540 @ 30fps (Balanced quality for mobile co-hosts)
  static const VideoParameters presetQHD540p = VideoParameters(
    width: 960,
    height: 540,
    frameRate: 30,
    maxBitrate: 1200000,
    facingMode: 'user',
  );

  /// 360p VGA: 640x360 @ 30fps (Low bandwidth / multi-guest grids)
  static const VideoParameters presetVGA360p = VideoParameters(
    width: 640,
    height: 360,
    frameRate: 30,
    maxBitrate: 600000,
    facingMode: 'user',
  );

  /// 240p QVGA: 320x240 @ 15fps (Extreme low bandwidth / battery saving)
  static const VideoParameters presetQVGA240p = VideoParameters(
    width: 320,
    height: 240,
    frameRate: 15,
    maxBitrate: 200000,
    facingMode: 'user',
  );

  /// Allows developers to define custom resolutions and framerates.
  factory VideoParameters.custom({
    required int width,
    required int height,
    int fps = 24,
    int? maxBitrate,
    String facingMode = 'user',
  }) {
    return VideoParameters(
      width: width,
      height: height,
      frameRate: fps,
      maxBitrate: maxBitrate,
      facingMode: facingMode,
    );
  }

  /// Converts parameters to ideal/mandatory getUserMedia constraints map.
  /// Strictly caps framerate (min: 15, ideal: 24, max: 30) and disables CPU-heavy software processing
  /// to eliminate latency, encoder throttling, and freezing.
  Map<String, dynamic> toMediaConstraints({
    bool video = true,
    bool audio = true,
  }) {
    return {
      'audio': audio
          ? {
              'mandatory': {
                'googEchoCancellation': 'false',
                'googAutoGainControl': 'false',
                'googNoiseSuppression': 'false',
                'googHighpassFilter': 'false',
                'googAudioMirroring': 'false',
              },
              'echoCancellation': false,
              'noiseSuppression': false,
              'autoGainControl': false,
            }
          : false,
      'video': video
          ? {
              'mandatory': {
                'minWidth': '480',
                'minHeight': '640',
                'maxWidth': '720',
                'maxHeight': '1280',
                'minFrameRate': '15',
                'maxFrameRate': '30',
              },
              'facingMode': facingMode,
              'optional': [],
              'frameRate': {'ideal': 24, 'max': 30},
            }
          : false,
    };
  }

  VideoParameters copyWith({
    int? width,
    int? height,
    int? frameRate,
    int? maxBitrate,
    String? facingMode,
  }) {
    return VideoParameters(
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      maxBitrate: maxBitrate ?? this.maxBitrate,
      facingMode: facingMode ?? this.facingMode,
    );
  }
}
