import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/omnicast_config.dart';
import '../models/room_models.dart';

/// REST API service for interacting with the OmniCast backend (fetching live rooms, server status, etc.).
class OmniCastApi {
  final OmniCastConfig config;
  final http.Client _client;

  OmniCastApi({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

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
      return replaced.replaceAll(RegExp(r'/ws$'), '').replaceAll(RegExp(r'/+$'), '');
    } else if (host.startsWith('ws://')) {
      final replaced = host.replaceFirst('ws://', 'http://');
      return replaced.replaceAll(RegExp(r'/ws$'), '').replaceAll(RegExp(r'/+$'), '');
    }
    return host.replaceAll(RegExp(r'/+$'), '');
  }

  /// Fetches active live broadcasting rooms from the backend (`GET /rooms`).
  Future<List<RoomModel>> getLiveRooms({Duration timeout = const Duration(seconds: 10)}) async {
    final baseUrl = baseApiUrl;
    final urlString = baseUrl.endsWith('/api') ? '$baseUrl/rooms' : '$baseUrl/rooms';
    final uri = Uri.parse(urlString);

    debugPrint('[OmniCastApi] Fetching active rooms from: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: defaultHeaders,
      ).timeout(timeout);

      debugPrint('[OmniCastApi] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null') return [];

        final decoded = jsonDecode(body);
        List roomList = [];

        if (decoded is List) {
          roomList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['rooms'] is List) {
            roomList = decoded['rooms'] as List;
          } else if (decoded['rooms'] is Map<String, dynamic>) {
            roomList = (decoded['rooms'] as Map<String, dynamic>).values.toList();
          } else if (decoded['data'] is List) {
            roomList = decoded['data'] as List;
          } else if (decoded['active_rooms'] is List) {
            roomList = decoded['active_rooms'] as List;
          } else if (decoded['result'] is List) {
            roomList = decoded['result'] as List;
          }
        }

        return roomList
            .whereType<Map<String, dynamic>>()
            .map((item) => RoomModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 404 || response.statusCode == 204) {
        return [];
      } else {
        throw Exception('OmniCastApi.getLiveRooms failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[OmniCastApi] Error fetching live rooms: $e');
      rethrow;
    }
  }

  /// Disposes the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
