import 'dart:convert';
import 'api_client.dart';
import '../models/meeting_room.dart';

class MeetingService {
  final ApiClient _client;

  MeetingService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Lấy danh sách các phòng họp ca trực đang mở
  Future<List<MeetingRoom>> getActiveRooms() async {
    final response = await _client.get('meeting/rooms');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => MeetingRoom.fromJson(item)).toList();
    }
    return [];
  }

  /// Tạo phòng họp giao ban ca trực mới
  Future<MeetingRoom?> createRoom({required String title, int maxParticipants = 12}) async {
    final response = await _client.post('meeting/create-room', {
      'title': title,
      'maxParticipants': maxParticipants,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['room'] != null) {
        return MeetingRoom.fromJson(data['room']);
      }
    }
    return null;
  }

  /// Đóng phòng họp
  Future<bool> closeRoom(String roomCode) async {
    final response = await _client.post('meeting/close-room/$roomCode', {});
    return response.statusCode == 200;
  }
}
