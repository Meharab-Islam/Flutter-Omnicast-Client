import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/omnicast_config.dart';
import '../models/room_models.dart';
import '../utils/omnicast_logger.dart';

/// REST API service for interacting with the OmniCast backend (fetching live rooms, server status, etc.).
class OmniCastApi {
  final OmniCastConfig config;
  final http.Client _client;

  OmniCastApi({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  /// Headers automatically computed from the SDK initialization credentials.
  Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      headers['X-API-KEY'] = config.apiKey!;
      headers['X-API-Key'] = config.apiKey!;
      headers['x-api-key'] = config.apiKey!;
      headers['Authorization'] = 'Bearer ${config.apiKey!}';
    }
    if (config.apiSecret != null && config.apiSecret!.isNotEmpty) {
      headers['X-API-SECRET'] = config.apiSecret!;
      headers['X-API-Secret'] = config.apiSecret!;
      headers['x-api-secret'] = config.apiSecret!;
    }
    return headers;
  }

  /// Resolves the base HTTP API URL from [OmniCastConfig.apiUrl] or derived from [OmniCastConfig.hostUrl].
  String get baseApiUrl {
    if (config.apiUrl != null && config.apiUrl!.isNotEmpty) {
      return config.apiUrl!.replaceAll(RegExp(r'/+$'), '');
    }
    final host = config.hostUrl.trim();
    if (host.startsWith('wss://')) {
      final replaced = host.replaceFirst('wss://', 'https://');
      return replaced
          .replaceAll(RegExp(r'/ws$'), '')
          .replaceAll(RegExp(r'/+$'), '');
    } else if (host.startsWith('ws://')) {
      final replaced = host.replaceFirst('ws://', 'http://');
      return replaced
          .replaceAll(RegExp(r'/ws$'), '')
          .replaceAll(RegExp(r'/+$'), '');
    }
    return host.replaceAll(RegExp(r'/+$'), '');
  }

  /// Fetches active live broadcasting rooms from the backend (`GET /rooms` or `GET /api/rooms`).
  Future<List<RoomModel>> getLiveRooms({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final base = baseApiUrl;
    final root = base.replaceAll(RegExp(r'/api$'), '');

    final candidateUrls = <String>[
      '$root/rooms',
      if (base != root) '$base/rooms' else '$root/api/rooms',
    ];

    Exception? lastError;

    for (final urlString in candidateUrls) {
      final uri = Uri.parse(urlString);
      try {
        final response = await _client
            .get(uri, headers: defaultHeaders)
            .timeout(timeout);

        OmniCastLogger.log(
          '[OmniCastApi] Rooms response from $urlString (${response.statusCode}): ${response.body}',
        );

        if (response.statusCode == 200) {
          final body = response.body.trim();
          if (body.isEmpty || body == 'null') return [];

          try {
            final decoded = jsonDecode(body);
            List roomList = [];

            if (decoded is List) {
              roomList = decoded;
            } else if (decoded is Map<String, dynamic>) {
              if (decoded['rooms'] is List) {
                roomList = decoded['rooms'] as List;
              } else if (decoded['rooms'] is Map<String, dynamic>) {
                roomList = (decoded['rooms'] as Map<String, dynamic>).values
                    .toList();
              } else if (decoded['data'] is List) {
                roomList = decoded['data'] as List;
              } else if (decoded['active_rooms'] is List) {
                roomList = decoded['active_rooms'] as List;
              } else if (decoded['result'] is List) {
                roomList = decoded['result'] as List;
              }
            }

            final rooms = roomList
                .whereType<Map<String, dynamic>>()
                .map((item) => RoomModel.fromJson(item))
                .toList();

            return rooms;
          } catch (e) {
            OmniCastLogger.error('[OmniCastApi] JSON Parsing Error: $e');
            rethrow;
          }
        } else if (response.statusCode == 404 || response.statusCode == 204) {
          continue; // Try next candidate endpoint
        } else {
          lastError = Exception(
            'OmniCastApi.getLiveRooms failed ($urlString): ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        lastError = Exception(
          'OmniCastApi.getLiveRooms request error ($urlString): $e',
        );
      }
    }

    if (lastError != null) {
      OmniCastLogger.error(
        '[OmniCastApi] Error fetching live rooms: $lastError',
      );
      return []; // Graceful fallback to empty list instead of throwing
    }

    return [];
  }

  /// Fetches a single room's details including active viewers (`GET /rooms/{roomId}`).
  Future<Map<String, dynamic>?> getRoom(
    String roomId, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final base = baseApiUrl;
    final root = base.replaceAll(RegExp(r'/api$'), '');
    final candidateUrls = [
      '$root/rooms/$roomId',
      if (base != root) '$base/rooms/$roomId' else '$root/api/rooms/$roomId',
    ];

    for (final urlString in candidateUrls) {
      try {
        final response = await _client
            .get(Uri.parse(urlString), headers: defaultHeaders)
            .timeout(timeout);
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Disposes the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
