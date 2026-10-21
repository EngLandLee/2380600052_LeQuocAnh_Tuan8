class LeaveRequest {
  final int id;
  final String userId;
  final String employeeName;
  final String department;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;
  final String createdAt;
  final String? reviewedBy;
  final String? reviewNote;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.department,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewNote,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int? ?? 0,
      userId: json['userId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? 'Nhân viên',
      department: json['department']?.toString() ?? '',
      leaveType: json['leaveType']?.toString() ?? 'Nghỉ phép năm',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Chờ duyệt',
      createdAt: json['createdAt']?.toString() ?? '',
      reviewedBy: json['reviewedBy']?.toString(),
      reviewNote: json['reviewNote']?.toString(),
    );
  }
}
