class Employee {
  final String id;
  final String userName;
  final String email;
  final String fullName;
  final String department;
  final String? phoneNumber;
  final String? nfcCardId;
  final String role;
  final String? lastCheckIn;
  final double lastEnergyScore;
  final String lastMood;

  Employee({
    required this.id,
    required this.userName,
    required this.email,
    required this.fullName,
    required this.department,
    this.phoneNumber,
    this.nfcCardId,
    required this.role,
    this.lastCheckIn,
    required this.lastEnergyScore,
    required this.lastMood,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['userName']?.toString() ?? '',
      department: json['department']?.toString() ?? 'Chưa phân bổ',
      phoneNumber: json['phoneNumber']?.toString(),
      nfcCardId: json['nfcCardId']?.toString(),
      role: json['role']?.toString() ?? 'User',
      lastCheckIn: json['lastCheckIn']?.toString(),
      lastEnergyScore: (json['lastEnergyScore'] as num?)?.toDouble() ?? 85.0,
      lastMood: json['lastMood']?.toString() ?? 'Bình thường',
    );
  }
}
