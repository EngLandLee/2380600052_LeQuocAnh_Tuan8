class AttendanceRecord {
  final int id;
  final String userId;
  final String? userName;
  final String? fullName;
  final String? department;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String method;
  final double? energyScore;
  final String? mood;
  final String? photoUrl;
  final bool detectedBlink;
  final String status;
  final String? deviceInfo;

  AttendanceRecord({
    required this.id,
    required this.userId,
    this.userName,
    this.fullName,
    this.department,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.method,
    this.energyScore,
    this.mood,
    this.photoUrl,
    this.detectedBlink = false,
    required this.status,
    this.deviceInfo,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int? ?? 0,
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString(),
      fullName: json['fullName']?.toString(),
      department: json['department']?.toString(),
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'].toString())
          : DateTime.now(),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'].toString())
          : null,
      method: json['method']?.toString() ?? 'FaceID',
      energyScore: json['energyScore'] != null
          ? (json['energyScore'] as num).toDouble()
          : null,
      mood: json['mood']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      detectedBlink: json['detectedBlink'] as bool? ?? false,
      status: json['status']?.toString() ?? 'OnTime',
      deviceInfo: json['deviceInfo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'fullName': fullName,
      'department': department,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'method': method,
      'energyScore': energyScore,
      'mood': mood,
      'photoUrl': photoUrl,
      'detectedBlink': detectedBlink,
      'status': status,
      'deviceInfo': deviceInfo,
    };
  }

  // Helper for UI duration
  String get workingDuration {
    if (checkOutTime == null) {
      final diff = DateTime.now().difference(checkInTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      return '${hours}h ${minutes}m (Đang làm)';
    } else {
      final diff = checkOutTime!.difference(checkInTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    }
  }
}
