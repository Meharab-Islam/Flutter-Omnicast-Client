import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_controller.dart';
import '../media/media_stream_manager.dart';

/// An atomic, headless, and lightweight WebRTC video rendering widget.
///
/// Designed with zero forced styling, borders, or fixed aspect ratios.
/// Implements lazy [RTCVideoRenderer] initialization upon mount and aggressive
/// disposal on unmount to completely eliminate memory and VRAM leaks.
class OmniCastVideoView extends StatefulWidget {
  /// The [MediaStreamManager] holding local and remote video streams.
  final MediaStreamManager mediaStreamManager;

  /// The user ID or peer ID to render. If null or `'local'`, renders local camera.
  final String? userId;

  /// Optional [MediaController] to dispatch adaptive streaming layer requests.
  final MediaController? mediaController;

  /// Whether to mirror the video rendering (typically true for local front camera).
  final bool mirror;

  /// The object fit strategy for rendering the video (cover, contain, fill).
  final RTCVideoViewObjectFit objectFit;

  /// Whether to automatically send adaptive streaming layer requests. Defaults to false (headless).
  final bool enableAdaptiveStreaming;

  /// Optional custom placeholder widget when video stream is loading or inactive.
  final Widget? placeholder;

  /// Optional callback invoked when the [RTCVideoRenderer] is initialized and ready.
  final void Function(RTCVideoRenderer renderer)? onRendererReady;

  const OmniCastVideoView({
    super.key,
    required this.mediaStreamManager,
    this.userId,
    this.mediaController,
    this.mirror = false,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    this.enableAdaptiveStreaming = false,
    this.placeholder,
    this.onRendererReady,
  });

  @override
  State<OmniCastVideoView> createState() => _OmniCastVideoViewState();
}

class _OmniCastVideoViewState extends State<OmniCastVideoView> {
  RTCVideoRenderer? _renderer;
  bool _isMounted = false;
  String? _lastAdaptiveLayer;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeLazyRenderer();
  }

  @override
  void didUpdateWidget(covariant OmniCastVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.mediaStreamManager != widget.mediaStreamManager) {
      _cleanupRenderer();
      _initializeLazyRenderer();
    }
  }

  /// Lazy initialization: only allocate renderer resources when mounted in widget tree.
  Future<void> _initializeLazyRenderer() async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();

    if (!_isMounted) {
      await renderer.dispose();
      return;
    }

    final isLocal = widget.userId == null || widget.userId == 'local';
    if (isLocal) {
      if (widget.mediaStreamManager.localStream != null) {
        renderer.srcObject = widget.mediaStreamManager.localStream;
      }
    } else {
      final remoteStream = widget.mediaStreamManager.remoteStreams[widget.userId!];
      if (remoteStream != null) {
        renderer.srcObject = remoteStream;
      }
    }

    if (_isMounted) {
      setState(() {
        _renderer = renderer;
      });
      widget.onRendererReady?.call(renderer);
    } else {
      renderer.srcObject = null;
      await renderer.dispose();
    }
  }

  void _checkAdaptiveStreaming(BoxConstraints constraints) {
    if (!widget.enableAdaptiveStreaming ||
        widget.mediaController == null ||
        widget.userId == null ||
        widget.userId == 'local') {
      return;
    }

    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (width.isInfinite || height.isInfinite || width <= 0 || height <= 0) return;

    final maxDim = width > height ? width : height;
    final targetLayer = maxDim <= 360 ? 'q' : (maxDim <= 720 ? 'h' : 'f');

    if (_lastAdaptiveLayer != targetLayer) {
      _lastAdaptiveLayer = targetLayer;
      widget.mediaController!.requestLayerForUser(
        targetUserId: widget.userId!,
        layer: targetLayer,
      );
    }
  }

  void _cleanupRenderer() {
    if (_renderer != null) {
      _renderer!.srcObject = null;
      _renderer!.dispose();
      _renderer = null;
    }
  }

  /// Aggressive Disposal: Free VRAM and hardware resources immediately on unmount.
  @override
  void dispose() {
    _isMounted = false;
    _cleanupRenderer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_renderer == null || _renderer!.srcObject == null) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    if (widget.enableAdaptiveStreaming) {
      return LayoutBuilder(
        builder: (context, constraints) {
          _checkAdaptiveStreaming(constraints);
          return RTCVideoView(
            _renderer!,
            mirror: widget.mirror,
            objectFit: widget.objectFit,
          );
        },
      );
    }

    return RTCVideoView(
      _renderer!,
      mirror: widget.mirror,
      objectFit: widget.objectFit,
    );
  }
}
