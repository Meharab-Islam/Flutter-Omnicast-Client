class DemoSession {
  final String serverUrl;
  final String roomId;
  final String userId;
  final String userName;
  final String role; // 'host', 'viewer', or 'cohost'

  const DemoSession({
    required this.serverUrl,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.role,
  });

  bool get isHost => role == 'host';
  bool get isViewer => role == 'viewer';
}
