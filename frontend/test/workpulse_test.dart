import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/attendance_record.dart';
import 'package:frontend/models/meeting_room.dart';
import 'package:frontend/models/energy_analytics.dart';

void main() {
  group('WorkPulse AI Models Test Suite', () {
    test('AttendanceRecord parsing and workingDuration calculation', () {
      final now = DateTime.now();
      final checkInTime = now.subtract(const Duration(hours: 3, minutes: 20));

      final json = {
        'id': 101,
        'userId': 'emp_01',
        'userName': 'nguyenvana',
        'fullName': 'Nguyễn Văn An',
        'department': 'Kỹ thuật',
        'date': now.toIso8601String(),
        'checkInTime': checkInTime.toIso8601String(),
        'checkOutTime': null,
        'method': 'FaceID',
        'energyScore': 92.5,
        'mood': 'Energized',
        'photoUrl': null,
        'detectedBlink': true,
        'status': 'OnTime',
      };

      final record = AttendanceRecord.fromJson(json);

      expect(record.id, 101);
      expect(record.fullName, 'Nguyễn Văn An');
      expect(record.energyScore, 92.5);
      expect(record.method, 'FaceID');
      expect(record.workingDuration.contains('3h 20m'), true);
    });

    test('MeetingRoom model serialization', () {
      final json = {
        'id': 1,
        'roomCode': 'SHIFT-123',
        'title': 'Giao ban ca sáng',
        'creatorName': 'Trưởng ca An',
        'creatorId': 'user_01',
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'maxParticipants': 12,
      };

      final room = MeetingRoom.fromJson(json);
      expect(room.roomCode, 'SHIFT-123');
      expect(room.title, 'Giao ban ca sáng');
      expect(room.maxParticipants, 12);
    });

    test('EnergyAnalytics parsing with Burnout Risk user detection', () {
      final json = {
        'totalCheckIns': 5,
        'averageEnergyScore': 78.4,
        'moodBreakdown': {'Energized': 3, 'Tired': 2},
        'burnoutRiskAlerts': [
          {
            'userId': 'user_bad',
            'userName': 'tranb',
            'fullName': 'Trần Văn B',
            'department': 'Vận hành kho',
            'energyScore': 38.0,
            'mood': 'Exhausted',
          }
        ]
      };

      final analytics = EnergyAnalytics.fromJson(json);
      expect(analytics.totalCheckIns, 5);
      expect(analytics.averageEnergyScore, 78.4);
      expect(analytics.burnoutRiskAlerts.length, 1);
      expect(analytics.burnoutRiskAlerts.first.energyScore, 38.0);
      expect(analytics.burnoutRiskAlerts.first.mood, 'Exhausted');
    });
  });
}
