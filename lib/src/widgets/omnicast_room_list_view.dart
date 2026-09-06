import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';
import '../models/room_models.dart';

/// Highly customizable builder widget providing real-time live rooms data without manual REST API calls.
///
/// Developers can build completely custom UI designs (Grid, Carousel, Custom Cards, Stories, etc.)
/// while the SDK automatically keeps the room list fresh in the background.
class OmniCastLiveRoomsBuilder extends StatelessWidget {
  final OmniCastClient client;
  final Widget Function(BuildContext context, List<RoomModel> rooms) builder;

  const OmniCastLiveRoomsBuilder({
    super.key,
    required this.client,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RoomModel>>(
      valueListenable: client.liveRoomsNotifier,
      builder: (context, rooms, _) => builder(context, rooms),
    );
  }
}

/// A ready-to-use yet fully customizable live rooms list widget.
///
/// Developers can use it directly with zero boilerplate, or override any visual element
/// ([itemBuilder], [emptyBuilder], [headerBuilder]) to match their custom app design.
class OmniCastRoomListView extends StatelessWidget {
  final OmniCastClient client;
  final void Function(RoomModel room)? onRoomTap;
  final Widget Function(BuildContext context, RoomModel room, int index)?
  itemBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, int count)? headerBuilder;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const OmniCastRoomListView({
    super.key,
    required this.client,
    this.onRoomTap,
    this.itemBuilder,
    this.emptyBuilder,
    this.headerBuilder,
    this.padding = const EdgeInsets.all(16),
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return OmniCastLiveRoomsBuilder(
      client: client,
      builder: (context, rooms) {
        if (rooms.isEmpty) {
          if (emptyBuilder != null) return emptyBuilder!(context);
          return _buildDefaultEmptyState();
        }

        return ListView.separated(
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          itemCount: rooms.length + (headerBuilder != null ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (headerBuilder != null && index == 0) {
              return headerBuilder!(context, rooms.length);
            }
            final roomIndex = headerBuilder != null ? index - 1 : index;
            final room = rooms[roomIndex];

            if (itemBuilder != null) {
              return itemBuilder!(context, room, roomIndex);
            }
            return _buildDefaultRoomCard(context, room);
          },
        );
      },
    );
  }

  Widget _buildDefaultRoomCard(BuildContext context, RoomModel room) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E2132),
      child: InkWell(
        onTap: () => onRoomTap?.call(room),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Host Avatar / Badge
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                child: const Icon(
                  Icons.live_tv_rounded,
                  color: Color(0xFF6C5CE7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Room Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.roomName.isNotEmpty
                          ? room.roomName
                          : 'Room: ${room.roomId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Host: ${room.hostId}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Live Status & Viewer Counter
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.redAccent, size: 6),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${room.totalViewers}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tv_off_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            const Text(
              'No active rooms right now',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start broadcasting as a host or wait for new live streams.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
