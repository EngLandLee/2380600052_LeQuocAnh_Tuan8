class BurnoutRiskUser {
  final String userId;
  final String userName;
  final String fullName;
  final String department;
  final double energyScore;
  final String mood;

  BurnoutRiskUser({
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.department,
    required this.energyScore,
    required this.mood,
  });

  factory BurnoutRiskUser.fromJson(Map<String, dynamic> json) {
    final rawUser = (json['userName'] ?? json['username'])?.toString() ?? '';
    final rawFull = (json['fullName'] ?? rawUser)?.toString() ?? '';
    return BurnoutRiskUser(
      userId: json['userId']?.toString() ?? '',
      userName: rawUser,
      fullName: rawFull,
      department: json['department']?.toString() ?? 'Nhân sự chung',
      energyScore: (json['energyScore'] as num?)?.toDouble() ?? 0.0,
      mood: (json['mood'] ?? json['moodLabel'])?.toString() ?? 'Tired',
    );
  }
}

class EnergyAnalytics {
  final int totalCheckIns;
  final double averageEnergyScore;
  final Map<String, int> moodBreakdown;
  final List<BurnoutRiskUser> burnoutRiskAlerts;

  EnergyAnalytics({
    required this.totalCheckIns,
    required this.averageEnergyScore,
    required this.moodBreakdown,
    required this.burnoutRiskAlerts,
  });

  factory EnergyAnalytics.fromJson(Map<String, dynamic> json) {
    final rawMoods = (json['moodDistribution'] ?? json['moodBreakdown']) as Map<String, dynamic>? ?? {};
    final moods = rawMoods.map((key, value) => MapEntry(key, (value as num).toInt()));

    final rawAlerts = (json['fatigueAlerts'] ?? json['burnoutRiskAlerts']) as List<dynamic>? ?? [];
    final alerts = rawAlerts
        .map((a) => BurnoutRiskUser.fromJson(a as Map<String, dynamic>))
        .toList();

    return EnergyAnalytics(
      totalCheckIns: (json['totalCheckInsThisWeek'] ?? json['totalCheckIns']) as int? ?? 0,
      averageEnergyScore: ((json['averageEnergy'] ?? json['averageEnergyScore']) as num?)?.toDouble() ?? 75.0,
      moodBreakdown: moods,
      burnoutRiskAlerts: alerts,
    );
  }
}
