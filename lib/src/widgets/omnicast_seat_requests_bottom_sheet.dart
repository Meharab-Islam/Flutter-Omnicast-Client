import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';
import '../models/seat_models.dart';

/// Highly customizable builder widget providing real-time pending co-host seat requests.
class OmniCastSeatRequestsBuilder extends StatelessWidget {
  final OmniCastClient client;
  final Widget Function(BuildContext context, List<SeatRequest> requests)
  builder;

  const OmniCastSeatRequestsBuilder({
    super.key,
    required this.client,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SeatRequest>>(
      valueListenable: client.seats.pendingSeatRequestsNotifier,
      builder: (context, requests, _) => builder(context, requests),
    );
  }
}

/// A ready-to-use yet fully customizable bottom sheet for hosts to manage seat requests.
///
/// Can be displayed via [OmniCastSeatRequestsBottomSheet.show] or placed directly into custom widget trees.
class OmniCastSeatRequestsBottomSheet extends StatelessWidget {
  final OmniCastClient client;
  final Widget Function(
    BuildContext context,
    SeatRequest request,
    VoidCallback onAccept,
    VoidCallback onDecline,
  )?
  itemBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  const OmniCastSeatRequestsBottomSheet({
    super.key,
    required this.client,
    this.itemBuilder,
    this.emptyBuilder,
  });

  /// Displays the bottom sheet modal.
  static Future<void> show(
    BuildContext context, {
    required OmniCastClient client,
    Widget Function(
      BuildContext context,
      SeatRequest request,
      VoidCallback onAccept,
      VoidCallback onDecline,
    )?
    itemBuilder,
    Widget Function(BuildContext context)? emptyBuilder,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2132),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OmniCastSeatRequestsBottomSheet(
        client: client,
        itemBuilder: itemBuilder,
        emptyBuilder: emptyBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Co-Host Seat Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<List<SeatRequest>>(
                    valueListenable: client.seats.pendingSeatRequestsNotifier,
                    builder: (context, requests, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${requests.length}',
                          style: const TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            Flexible(
              child: OmniCastSeatRequestsBuilder(
                client: client,
                builder: (context, requests) {
                  if (requests.isEmpty) {
                    if (emptyBuilder != null) return emptyBuilder!(context);
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No pending seat requests',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      void onAccept() {
                        client.seats.acceptSeatRequest(
                          req.requesterId,
                          seatIndex: req.preferredSeatIndex,
                        );
                      }

                      void onDecline() {
                        client.seats.rejectSeatRequest(req.requesterId);
                      }

                      if (itemBuilder != null) {
                        return itemBuilder!(context, req, onAccept, onDecline);
                      }

                      final name = req.requesterName ?? req.requesterId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF6C5CE7,
                          ).withValues(alpha: 0.3),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          req.preferredSeatIndex != null
                              ? 'Requested Seat ${req.preferredSeatIndex}'
                              : 'Requested Any Seat',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white60,
                              ),
                              tooltip: 'Decline',
                              onPressed: onDecline,
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                              ),
                              onPressed: onAccept,
                              child: const Text(
                                'Accept',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
