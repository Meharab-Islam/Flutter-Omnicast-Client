import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/omnicast_client.dart';
import '../models/seat_models.dart';

/// Highly customizable builder widget providing real-time multi-guest stage data.
///
/// Developers can construct ANY custom stage design (9-seat grid, circular stage,
/// bottom row, floating avatar bubbles, custom overlays) using this builder.
class OmniCastStageBuilder extends StatelessWidget {
  final OmniCastClient client;
  final Widget Function(BuildContext context, List<StageSeat> seats, int occupiedCount) builder;

  const OmniCastStageBuilder({
    super.key,
    required this.client,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<StageSeat>>(
      valueListenable: client.seats.activeSeatsNotifier,
      builder: (context, seats, _) {
        final occupiedCount = seats.where((s) => s.isOccupied).length;
        return builder(context, seats, occupiedCount);
      },
    );
  }
}

/// A ready-to-use yet fully customizable 9-seat interactive stage grid.
///
/// Developers can use it directly with zero boilerplate, or override any visual element
/// ([seatBuilder], [emptySeatBuilder], [occupiedSeatBuilder], [onSeatTap]) to match their custom app design.
class OmniCastStageGrid extends StatelessWidget {
  final OmniCastClient client;
  final int maxSeats;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final void Function(StageSeat seat, int seatIndex)? onSeatTap;
  final Widget Function(BuildContext context, StageSeat seat, int index)? seatBuilder;
  final Widget Function(BuildContext context, int seatIndex)? emptySeatBuilder;
  final Widget Function(BuildContext context, StageSeat seat)? occupiedSeatBuilder;

  const OmniCastStageGrid({
    super.key,
    required this.client,
    this.maxSeats = 9,
    this.crossAxisCount = 3,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 0.85,
    this.padding = const EdgeInsets.all(8),
    this.onSeatTap,
    this.seatBuilder,
    this.emptySeatBuilder,
    this.occupiedSeatBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return OmniCastStageBuilder(
      client: client,
      builder: (context, activeSeats, occupiedCount) {
        return GridView.builder(
          padding: padding,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: maxSeats,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final seatIndex = index + 1;
            StageSeat? seat;
            try {
              seat = activeSeats.firstWhere((s) => s.seatIndex == seatIndex);
            } catch (_) {}

            final effectiveSeat = seat ?? StageSeat(seatIndex: seatIndex);

            if (seatBuilder != null) {
              return seatBuilder!(context, effectiveSeat, seatIndex);
            }

            if (effectiveSeat.isOccupied) {
              if (occupiedSeatBuilder != null) {
                return occupiedSeatBuilder!(context, effectiveSeat);
              }
              return _buildDefaultOccupiedSeat(context, effectiveSeat);
            } else {
              if (emptySeatBuilder != null) {
                return emptySeatBuilder!(context, seatIndex);
              }
              return _buildDefaultEmptySeat(context, seatIndex);
            }
          },
        );
      },
    );
  }

  Widget _buildDefaultOccupiedSeat(BuildContext context, StageSeat seat) {
    final uId = seat.userId ?? '';
    final displayName = seat.user?.displayName ?? uId;
    final isMuted = client.seats.isUserMuted(uId) || seat.isMuted;
    final isCameraOff = client.seats.isUserCameraOff(uId) || seat.isCameraOff;
    final renderer = client.media.getRenderer(uId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: const Color(0xFF1E2132),
        child: InkWell(
          onTap: () {
            if (onSeatTap != null) {
              onSeatTap!(seat, seat.seatIndex);
            } else {
              _handleDefaultSeatClick(context, seat);
            }
          },
          child: Stack(
            children: [
              // Video View or Avatar Placeholder
              Positioned.fill(
                child: (!isCameraOff && renderer != null && (renderer.srcObject != null || renderer.renderVideo))
                    ? RTCVideoView(
                        renderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Container(
                        color: const Color(0xFF1E2132),
                        child: Center(
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),

              // Seat Number Badge
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${seat.seatIndex}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Media Indicators (Mic & Camera)
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMuted)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_off_rounded, size: 10, color: Colors.white),
                      ),
                    if (isCameraOff) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_off_rounded, size: 10, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),

              // User Name Footer Label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEmptySeat(BuildContext context, int seatIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (onSeatTap != null) {
              onSeatTap!(StageSeat(seatIndex: seatIndex), seatIndex);
            } else {
              _handleDefaultEmptySeatClick(context, seatIndex);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 24, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(height: 4),
              Text(
                'Seat $seatIndex',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDefaultEmptySeatClick(BuildContext context, int seatIndex) {
    if (client.state.isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seat $seatIndex is open for guest viewers.')),
      );
    } else {
      client.seats.requestSeat(seatIndex: seatIndex);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Requested seat $seatIndex from Host!'), backgroundColor: Colors.indigo),
      );
    }
  }

  void _handleDefaultSeatClick(BuildContext context, StageSeat seat) {
    if (!client.state.isHost) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2132),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(seat.user?.displayName ?? seat.userId ?? 'Guest', style: const TextStyle(color: Colors.white)),
              subtitle: Text('Seat ${seat.seatIndex}', style: const TextStyle(color: Colors.white54)),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
              title: const Text('Kick from Seat', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                client.seats.kickSeat(seat.seatIndex, targetUserId: seat.userId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
