import 'dart:convert';
import 'api_client.dart';
import '../models/meeting_room.dart';

class MeetingService {
  final ApiClient _client;

  MeetingService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Lấy danh sách các phòng họp ca trực đang mở
  Future<List<MeetingRoom>> getActiveRooms() async {
    try {
      final response = await _client.get('meeting/rooms');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List
            ? decoded
            : (decoded['data'] as List<dynamic>? ?? []);
        return data.map((item) => MeetingRoom.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Tạo phòng họp giao ban ca trực mới
  Future<MeetingRoom?> createRoom({required String title, int maxParticipants = 12}) async {
    try {
      final response = await _client.post('meeting/create-room', {
        'title': title,
        'maxParticipants': maxParticipants,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roomData = data['room'] ?? data['data'];
        if (roomData != null) {
          return MeetingRoom.fromJson(roomData as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Đóng phòng họp
  Future<bool> closeRoom(String roomCode) async {
    try {
      final response = await _client.post('meeting/close-room/$roomCode', {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
