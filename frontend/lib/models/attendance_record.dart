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
    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      final str = val.toString();
      final dt = DateTime.tryParse(str);
      if (dt != null) return dt;
      // Handle HH:mm:ss format
      if (str.contains(':')) {
        final parts = str.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          final h = int.tryParse(parts[0]) ?? now.hour;
          final m = int.tryParse(parts[1]) ?? now.minute;
          final s = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
          return DateTime(now.year, now.month, now.day, h, m, s);
        }
      }
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic val) {
      if (val == null) return null;
      final str = val.toString();
      if (str.isEmpty || str == 'Đang làm việc') return null;
      final dt = DateTime.tryParse(str);
      if (dt != null) return dt;
      if (str.contains(':')) {
        final parts = str.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          final h = int.tryParse(parts[0]) ?? now.hour;
          final m = int.tryParse(parts[1]) ?? now.minute;
          final s = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
          return DateTime(now.year, now.month, now.day, h, m, s);
        }
      }
      return null;
    }

    final rawUser = (json['userName'] ?? json['username'])?.toString();
    final rawFullName = (json['fullName'] ?? rawUser)?.toString();

    return AttendanceRecord(
      id: json['id'] as int? ?? 0,
      userId: json['userId']?.toString() ?? '',
      userName: rawUser,
      fullName: rawFullName,
      department: json['department']?.toString(),
      date: json['date'] != null ? parseDateTime(json['date']) : DateTime.now(),
      checkInTime: parseDateTime(json['checkInTime']),
      checkOutTime: parseNullableDateTime(json['checkOutTime']),
      method: json['method']?.toString() ?? 'FaceID',
      energyScore: json['energyScore'] != null
          ? (json['energyScore'] as num).toDouble()
          : null,
      mood: (json['mood'] ?? json['moodLabel'])?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      detectedBlink: (json['detectedBlink'] ?? json['isLivenessVerified']) as bool? ?? false,
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
