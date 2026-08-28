import 'package:flutter/foundation.dart';
import '../models/interaction_models.dart';
import '../models/pk_models.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';

/// Global reactive state container (ChangeNotifier) holding room metadata,
/// viewers count, chat history, gifts, active seats, stage layout, and PK battle state.
class RoomState extends ChangeNotifier {
  String? _roomId;
  String? _hostId;
  String? _userId;
  UserRole _role = UserRole.viewer;
  ClientConnectionState _connectionState = ClientConnectionState.disconnected;

  int _viewersCount = 0;
  int _hostCoinBalance = 0;
  int _userCoinBalance = 0;
  String? _pinnedStageUserId;

  final List<Participant> _viewers = [];
  final List<StageSeat> _activeSeats = [];
  final Set<String> _activeRemoteUserIds = {};
  final List<ChatMessage> _chatHistory = [];
  final List<GiftEvent> _recentGifts = [];
  final List<SeatRequest> _pendingSeatRequests = [];
  final List<CoHostInvite> _pendingInvites = [];

  PKBattleInfo? _activePK;

  // Getters
  String? get roomId => _roomId;
  String? get hostId => _hostId;
  String? get userId => _userId;
  UserRole get role => _role;
  ClientConnectionState get connectionState => _connectionState;

  int get viewersCount => _viewersCount;
  int get hostCoinBalance => _hostCoinBalance;
  int get userCoinBalance => _userCoinBalance;
  String? get pinnedStageUserId => _pinnedStageUserId;

  List<Participant> get viewers => List.unmodifiable(_viewers);
  List<StageSeat> get activeSeats => List.unmodifiable(_activeSeats);
  Set<String> get activeRemoteUserIds => Set.unmodifiable(_activeRemoteUserIds);
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  List<GiftEvent> get recentGifts => List.unmodifiable(_recentGifts);
  List<SeatRequest> get pendingSeatRequests =>
      List.unmodifiable(_pendingSeatRequests);
  List<CoHostInvite> get pendingInvites => List.unmodifiable(_pendingInvites);

  PKBattleInfo? get activePK => _activePK;
  PKState get pkState => _activePK != null
      ? PKState.fromBattleInfo(_activePK!, currentUserId: _userId)
      : PKState.idle;

  bool get isInPKBattle =>
      _activePK != null &&
      (_activePK!.status == PKStatus.inProgress ||
          _activePK!.status == PKStatus.punishment);

  bool get isHost => _role == UserRole.host;
  bool get isCoHost => _role == UserRole.coHost;
  bool get isViewer => _role == UserRole.viewer;
  bool get isInRoom => _roomId != null && _roomId!.isNotEmpty;

  /// Sets up room session identity and role.
  void setSession({
    required String roomId,
    required String userId,
    required UserRole role,
    String? hostId,
  }) {
    _roomId = roomId;
    _userId = userId;
    _role = role;
    _hostId = hostId ?? (role == UserRole.host ? userId : null);
    notifyListeners();
  }

  /// Updates connection state.
  void updateConnectionState(ClientConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    notifyListeners();
  }

  /// Updates user role.
  void updateRole(UserRole newRole) {
    if (_role == newRole) return;
    _role = newRole;
    notifyListeners();
  }

  /// Synchronizes full room info on join or late-join (`room_info_sync`).
  void syncRoomInfo(Map<String, dynamic> data) {
    _roomId = data['room_id'] as String? ?? _roomId;
    _hostId = data['host_id'] as String? ?? _hostId;
    _viewersCount = (data['viewers_count'] as num?)?.toInt() ??
        (data['viewer_count'] as num?)?.toInt() ??
        _viewersCount;
    _hostCoinBalance = (data['host_coin_balance'] as num?)?.toInt() ??
        (data['host_coins'] as num?)?.toInt() ??
        _hostCoinBalance;
    _pinnedStageUserId = data['pinned_user_id'] as String? ?? _pinnedStageUserId;

    // Populate active users/viewers
    if (data['viewers'] is List) {
      _viewers.clear();
      for (final item in data['viewers'] as List) {
        if (item is Map<String, dynamic>) {
          _viewers.add(Participant.fromJson(item));
        }
      }
    }

    // Populate active seats
    if (data['active_seats'] is List) {
      _activeSeats.clear();
      for (final item in data['active_seats'] as List) {
        if (item is Map<String, dynamic>) {
          final seat = StageSeat.fromJson(item);
          _activeSeats.add(seat);
          if (seat.userId != null && seat.userId!.isNotEmpty && seat.userId != _userId) {
            _activeRemoteUserIds.add(seat.userId!);
          }
        }
      }
    }

    // Populate chat history
    if (data['chat_history'] is List) {
      _chatHistory.clear();
      for (final item in data['chat_history'] as List) {
        if (item is Map<String, dynamic>) {
          _chatHistory.add(ChatMessage.fromJson(item));
        }
      }
    }

    // Populate current gifts
    if (data['recent_gifts'] is List) {
      _recentGifts.clear();
      for (final item in data['recent_gifts'] as List) {
        if (item is Map<String, dynamic>) {
          _recentGifts.add(GiftEvent.fromJson(item));
        }
      }
    }

    // Populate active PK
    if (data['active_pk'] is Map<String, dynamic>) {
      _activePK = PKBattleInfo.fromJson(data['active_pk'] as Map<String, dynamic>);
      if (_activePK != null && _activePK!.opponentUserId.isNotEmpty) {
        _activeRemoteUserIds.add(_activePK!.opponentUserId);
      }
    } else if (data['active_pk'] == null && _activePK != null) {
      _activePK = null;
    }

    notifyListeners();
  }

  /// Updates the viewer count and list of active viewers.
  void updateViewers({
    required int count,
    List<Participant>? viewersList,
  }) {
    _viewersCount = count;
    if (viewersList != null) {
      _viewers.clear();
      _viewers.addAll(viewersList);
    }
    notifyListeners();
  }

  /// Adds a new chat message to history (capped to last 200 items).
  void addChatMessage(ChatMessage message) {
    _chatHistory.add(message);
    if (_chatHistory.length > 200) {
      _chatHistory.removeRange(0, _chatHistory.length - 200);
    }
    notifyListeners();
  }

  /// Processes a gift event, updates host coin balance, and atomically bumps active PK scores.
  void processGift(GiftEvent event) {
    _recentGifts.add(event);
    if (_recentGifts.length > 50) {
      _recentGifts.removeRange(0, _recentGifts.length - 50);
    }
    _hostCoinBalance = event.hostTotalCoins;

    // Atomically bump PK battle points if a PK is active
    if (_activePK != null && isInPKBattle) {
      final points = event.coinValue > 0 ? (event.coinValue * event.amount) : event.amount;
      int newHostScore = _activePK!.hostScore;
      int newOpponentScore = _activePK!.opponentScore;

      if (event.targetUserId == _activePK!.hostUserId || event.targetUserId == _hostId) {
        newHostScore += points;
      } else if (event.targetUserId == _activePK!.opponentUserId) {
        newOpponentScore += points;
      } else {
        // Default to host if no target explicitly specified
        newHostScore += points;
      }

      _activePK = PKBattleInfo(
        battleId: _activePK!.battleId,
        hostRoomId: _activePK!.hostRoomId,
        hostUserId: _activePK!.hostUserId,
        opponentRoomId: _activePK!.opponentRoomId,
        opponentUserId: _activePK!.opponentUserId,
        opponentDisplayName: _activePK!.opponentDisplayName,
        opponentAvatarUrl: _activePK!.opponentAvatarUrl,
        status: _activePK!.status,
        hostScore: newHostScore,
        opponentScore: newOpponentScore,
        durationSeconds: _activePK!.durationSeconds,
        remainingSeconds: _activePK!.remainingSeconds,
        startedAt: _activePK!.startedAt,
      );
    }

    notifyListeners();
  }

  /// Updates personal or host balance.
  void updateBalance(BalanceUpdate update) {
    if (update.userId == _userId) {
      _userCoinBalance = update.newBalance;
    }
    if (update.userId == _hostId) {
      _hostCoinBalance = update.newBalance;
    }
    notifyListeners();
  }

  /// Sets or clears the pinned stage user ID.
  void setPinnedStageUser(String? userId) {
    _pinnedStageUserId = userId;
    notifyListeners();
  }

  /// Adds or updates a stage seat.
  void updateStageSeat(StageSeat seat) {
    final idx = _activeSeats.indexWhere((s) => s.seatIndex == seat.seatIndex);
    if (idx >= 0) {
      _activeSeats[idx] = seat;
    } else {
      _activeSeats.add(seat);
    }
    if (seat.userId != null && seat.userId != _userId) {
      _activeRemoteUserIds.add(seat.userId!);
    }
    notifyListeners();
  }

  /// Removes a user from a stage seat.
  void removeStageSeat(int seatIndex) {
    final idx = _activeSeats.indexWhere((s) => s.seatIndex == seatIndex);
    if (idx >= 0) {
      final removed = _activeSeats.removeAt(idx);
      if (removed.userId != null) {
        _activeRemoteUserIds.remove(removed.userId);
      }
      notifyListeners();
    }
  }

  /// Adds a pending seat request from a viewer.
  void addSeatRequest(SeatRequest request) {
    _pendingSeatRequests.removeWhere((r) => r.requesterId == request.requesterId);
    _pendingSeatRequests.add(request);
    notifyListeners();
  }

  /// Removes a handled seat request.
  void removeSeatRequest(String requesterId) {
    _pendingSeatRequests.removeWhere((r) => r.requesterId == requesterId);
    notifyListeners();
  }

  /// Adds a co-host invite from host.
  void addInvite(CoHostInvite invite) {
    _pendingInvites.removeWhere((i) => i.inviteId == invite.inviteId);
    _pendingInvites.add(invite);
    notifyListeners();
  }

  /// Removes a handled invite.
  void removeInvite(String inviteId) {
    _pendingInvites.removeWhere((i) => i.inviteId == inviteId);
    notifyListeners();
  }

  /// Starts or updates a PK battle.
  void updatePKBattle(PKBattleInfo pkInfo) {
    _activePK = pkInfo;
    if (pkInfo.opponentUserId.isNotEmpty) {
      _activeRemoteUserIds.add(pkInfo.opponentUserId);
    }
    notifyListeners();
  }

  /// Updates PK scores in real-time.
  void updatePKScore(PKScoreUpdate scoreUpdate) {
    if (_activePK == null) return;
    _activePK = PKBattleInfo(
      battleId: _activePK!.battleId,
      hostRoomId: _activePK!.hostRoomId,
      hostUserId: _activePK!.hostUserId,
      opponentRoomId: _activePK!.opponentRoomId,
      opponentUserId: _activePK!.opponentUserId,
      opponentDisplayName: _activePK!.opponentDisplayName,
      opponentAvatarUrl: _activePK!.opponentAvatarUrl,
      status: _activePK!.status,
      hostScore: scoreUpdate.hostScore,
      opponentScore: scoreUpdate.opponentScore,
      durationSeconds: _activePK!.durationSeconds,
      remainingSeconds: _activePK!.remainingSeconds,
      startedAt: _activePK!.startedAt,
    );
    notifyListeners();
  }

  /// Updates PK remaining seconds timer tick.
  void updatePKTimer(PKTimerTick tick) {
    if (_activePK == null) return;
    _activePK = PKBattleInfo(
      battleId: _activePK!.battleId,
      hostRoomId: _activePK!.hostRoomId,
      hostUserId: _activePK!.hostUserId,
      opponentRoomId: _activePK!.opponentRoomId,
      opponentUserId: _activePK!.opponentUserId,
      opponentDisplayName: _activePK!.opponentDisplayName,
      opponentAvatarUrl: _activePK!.opponentAvatarUrl,
      status: tick.isPunishmentPhase ? PKStatus.punishment : _activePK!.status,
      hostScore: _activePK!.hostScore,
      opponentScore: _activePK!.opponentScore,
      durationSeconds: _activePK!.durationSeconds,
      remainingSeconds: tick.remainingSeconds,
      startedAt: _activePK!.startedAt,
    );
    notifyListeners();
  }

  /// Ends the active PK battle.
  void endPKBattle() {
    if (_activePK != null) {
      _activeRemoteUserIds.remove(_activePK!.opponentUserId);
      _activePK = null;
      notifyListeners();
    }
  }

  /// Registers an active remote user track.
  void addActiveRemoteUser(String userId) {
    if (_activeRemoteUserIds.add(userId)) {
      notifyListeners();
    }
  }

  /// Unregisters an active remote user track.
  void removeActiveRemoteUser(String userId) {
    if (_activeRemoteUserIds.remove(userId)) {
      notifyListeners();
    }
  }

  /// Resets state when disconnecting or leaving room.
  void reset() {
    _roomId = null;
    _hostId = null;
    _userId = null;
    _role = UserRole.viewer;
    _viewersCount = 0;
    _hostCoinBalance = 0;
    _userCoinBalance = 0;
    _pinnedStageUserId = null;
    _viewers.clear();
    _activeSeats.clear();
    _activeRemoteUserIds.clear();
    _chatHistory.clear();
    _recentGifts.clear();
    _pendingSeatRequests.clear();
    _pendingInvites.clear();
    _activePK = null;
    notifyListeners();
  }
}
