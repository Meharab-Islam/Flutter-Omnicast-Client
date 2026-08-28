import 'video_parameters.dart';

/// Centralized global configuration for all media capture, quality presets, simulcast,
/// Dynacast, and adaptive streaming across the OmniCast SDK.
class GlobalMediaConfig {
  /// Default video capture and encoding resolution/framerate parameters.
  final VideoParameters defaultResolution;

  /// Whether multi-layer simulcast ('f', 'h', 'q') is enabled by default for publishers.
  final bool enableSimulcast;

  /// Whether smart publisher layer muting (Dynacast) is active.
  final bool enableDynacast;

  /// Whether viewers dynamically adjust subscribed layer based on viewport size.
  final bool enableAdaptiveStreaming;

  /// Whether camera automatically pauses when app enters background state to save battery.
  final bool autoPauseOnBackground;

  const GlobalMediaConfig({
    this.defaultResolution = VideoParameters.presetHD720p,
    this.enableSimulcast = true,
    this.enableDynacast = true,
    this.enableAdaptiveStreaming = true,
    this.autoPauseOnBackground = true,
  });
}
