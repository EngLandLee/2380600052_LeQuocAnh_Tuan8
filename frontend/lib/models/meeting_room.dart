class MeetingRoom {
  final int id;
  final String roomCode;
  final String title;
  final String creatorName;
  final String creatorId;
  final DateTime createdAt;
  final bool isActive;
  final int maxParticipants;

  MeetingRoom({
    required this.id,
    required this.roomCode,
    required this.title,
    required this.creatorName,
    required this.creatorId,
    required this.createdAt,
    required this.isActive,
    required this.maxParticipants,
  });

  factory MeetingRoom.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final host = (json['creatorName'] ?? json['hostName'] ?? json['host'])?.toString() ?? 'Admin';

    return MeetingRoom(
      id: json['id'] as int? ?? 0,
      roomCode: json['roomCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      creatorName: host,
      creatorId: json['creatorId']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      isActive: json['isActive'] as bool? ?? true,
      maxParticipants: json['maxParticipants'] as int? ?? 12,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCode': roomCode,
      'title': title,
      'creatorName': creatorName,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'maxParticipants': maxParticipants,
    };
  }
}
