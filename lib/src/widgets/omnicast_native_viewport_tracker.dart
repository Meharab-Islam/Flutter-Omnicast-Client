import 'package:flutter/material.dart';
import '../media/media_controller.dart';

/// Native zero-dependency viewport detector that calculates visible items in a GridView/ListView
/// mathematically from scroll metrics and notifies the SFU to pause hidden video streams.
class OmniCastNativeViewportTracker extends StatelessWidget {
  final Widget child;
  final List<String> trackIds;
  final double itemHeight;
  final int crossAxisCount;
  final MediaController? mediaController;
  final void Function(List<String> visibleTracks, List<String> hiddenTracks)? onVisibilityChanged;

  const OmniCastNativeViewportTracker({
    super.key,
    required this.child,
    required this.trackIds,
    this.itemHeight = 220.0,
    this.crossAxisCount = 2,
    this.mediaController,
    this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollUpdateNotification || scrollInfo is ScrollEndNotification) {
          _evaluateVisibility(
            scrollOffset: scrollInfo.metrics.pixels,
            viewportDimension: scrollInfo.metrics.viewportDimension,
          );
        }
        return false;
      },
      child: child,
    );
  }

  void _evaluateVisibility({
    required double scrollOffset,
    required double viewportDimension,
  }) {
    if (trackIds.isEmpty) return;

    final firstRow = (scrollOffset / itemHeight).floor().clamp(0, 10000);
    final lastRow = ((scrollOffset + viewportDimension) / itemHeight).ceil();

    final firstVisibleIndex = (firstRow * crossAxisCount).clamp(0, trackIds.length);
    final lastVisibleIndex = (lastRow * crossAxisCount).clamp(0, trackIds.length);

    final visibleTrackIds = <String>[];
    final hiddenTrackIds = <String>[];

    for (int i = 0; i < trackIds.length; i++) {
      final id = trackIds[i];
      if (i >= firstVisibleIndex && i < lastVisibleIndex) {
        visibleTrackIds.add(id);
        mediaController?.setRemoteTrackVisibility(id, true);
      } else {
        hiddenTrackIds.add(id);
        mediaController?.setRemoteTrackVisibility(id, false);
      }
    }

    onVisibilityChanged?.call(visibleTrackIds, hiddenTrackIds);
  }
}
