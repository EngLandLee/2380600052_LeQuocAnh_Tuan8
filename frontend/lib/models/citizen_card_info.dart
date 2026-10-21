class CitizenCardInfo {
  final String citizenId;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String placeOfOrigin;
  final String permanentAddress;
  final String nationality;
  final String ethnicity;
  final String chipSerial;
  final String department;

  CitizenCardInfo({
    required this.citizenId,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.placeOfOrigin,
    required this.permanentAddress,
    required this.nationality,
    required this.ethnicity,
    required this.chipSerial,
    required this.department,
  });

  factory CitizenCardInfo.fromJson(Map<String, dynamic> json) {
    return CitizenCardInfo(
      citizenId: json['citizenId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Nhân viên',
      dateOfBirth: json['dateOfBirth']?.toString() ?? 'Chưa cập nhật',
      gender: json['gender']?.toString() ?? 'Nam',
      placeOfOrigin: json['placeOfOrigin']?.toString() ?? 'Việt Nam',
      permanentAddress: json['permanentAddress']?.toString() ?? 'Việt Nam',
      nationality: json['nationality']?.toString() ?? 'Việt Nam',
      ethnicity: json['ethnicity']?.toString() ?? 'Kinh',
      chipSerial: json['chipSerial']?.toString() ?? '',
      department: json['department']?.toString() ?? 'Công Nghệ & Kỹ Thuật',
    );
  }
}
