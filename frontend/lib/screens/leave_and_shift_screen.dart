import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_request.dart';
import '../services/leave_request_service.dart';
import '../utils/auth_helper.dart';

class LeaveAndShiftScreen extends StatefulWidget {
  const LeaveAndShiftScreen({super.key});

  @override
  State<LeaveAndShiftScreen> createState() => _LeaveAndShiftScreenState();
}

class _LeaveAndShiftScreenState extends State<LeaveAndShiftScreen> {
  final LeaveRequestService _leaveService = LeaveRequestService();
  List<LeaveRequest> _requests = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final role = await AuthHelper.getRole();
    final list = await _leaveService.getAll();
    if (mounted) {
      setState(() {
        _isAdmin = role.toLowerCase() == 'admin';
        _requests = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _openLeaveDialog({LeaveRequest? request}) async {
    final isEdit = request != null;
    String selectedType = request?.leaveType ?? 'Nghỉ phép năm';
    DateTime startDate = request != null ? DateTime.tryParse(request.startDate) ?? DateTime.now() : DateTime.now().add(const Duration(days: 1));
    DateTime endDate = request != null ? DateTime.tryParse(request.endDate) ?? DateTime.now().add(const Duration(days: 1)) : DateTime.now().add(const Duration(days: 2));
    final reasonCtrl = TextEditingController(text: request?.reason ?? '');

    final dateFormat = DateFormat('dd/MM/yyyy');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(isEdit ? Icons.edit_calendar_rounded : Icons.add_circle_outline_rounded, color: const Color(0xFF818CF8), size: 28),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'Chỉnh Sửa Đơn Xin Nghỉ' : 'Tạo Đơn Xin Nghỉ Phép / Đổi Ca',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Loại nghỉ
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1E293B),
                    initialValue: selectedType,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      labelText: 'Hình thức nghỉ phép',
                      labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Nghỉ phép năm', child: Text('Nghỉ phép năm (hưởng lương)')),
                      DropdownMenuItem(value: 'Nghỉ ốm hưởng BHXH', child: Text('Nghỉ ốm / Khám bệnh (BHXH)')),
                      DropdownMenuItem(value: 'Đi công tác ngoài', child: Text('Đi công tác / Ra ngoài làm việc')),
                      DropdownMenuItem(value: 'Việc riêng không lương', child: Text('Việc riêng (không hưởng lương)')),
                    ],
                    onChanged: (val) => setSheetState(() => selectedType = val ?? selectedType),
                  ),
                  const SizedBox(height: 14),

                  // Chọn ngày bắt đầu và kết thúc
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setSheetState(() => startDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Từ ngày', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(dateFormat.format(startDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setSheetState(() => endDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Đến hết ngày', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(dateFormat.format(endDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      labelText: 'Lý do xin nghỉ / Ghi chú ca trực *',
                      labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final reason = reasonCtrl.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập lý do'), backgroundColor: Color(0xFFEF4444)),
                          );
                          return;
                        }

                        bool ok;
                        if (isEdit) {
                          ok = await _leaveService.update(
                            request.id,
                            leaveType: selectedType,
                            startDate: startDate,
                            endDate: endDate,
                            reason: reason,
                          );
                        } else {
                          ok = await _leaveService.create(
                            leaveType: selectedType,
                            startDate: startDate,
                            endDate: endDate,
                            reason: reason,
                          );
                        }

                        if (!mounted) return;
                        if (ctx.mounted) Navigator.pop(ctx);

                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Đã cập nhật đơn thành công!' : 'Đã gửi đơn xin nghỉ phép thành công!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                          _loadRequests();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEdit ? 'Lưu Thay Đổi' : 'Gửi Đơn Lên Quản Lý',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleReviewDialog(LeaveRequest req) async {
    final noteCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Phê Duyệt Đơn Xin Nghỉ', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhân viên: ${req.employeeName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Hình thức: ${req.leaveType}', style: const TextStyle(color: Color(0xFF38BDF8))),
            Text('Thời gian: ${req.startDate} → ${req.endDate}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text('Lý do: "${req.reason}"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                labelText: 'Lời nhắn phản hồi của Quản lý',
                labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _leaveService.updateStatus(req.id, 'Từ chối', reviewNote: noteCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _loadRequests();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Từ Chối', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _leaveService.updateStatus(req.id, 'Đã duyệt', reviewNote: noteCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _loadRequests();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Chấp Thuận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(LeaveRequest req) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hủy Đơn Xin Nghỉ', style: TextStyle(color: Colors.white)),
        content: Text('Bạn có chắc chắn muốn hủy đơn nghỉ từ "${req.startDate}" đến "${req.endDate}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Hủy Đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _leaveService.delete(req.id);
      _loadRequests();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã duyệt':
        return const Color(0xFF10B981);
      case 'Từ chối':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Quản Lý Đơn Nghỉ Phép & Đổi Ca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFF59E0B)),
            tooltip: 'Nạp đơn mẫu',
            onPressed: () async {
              await _leaveService.seedSample();
              _loadRequests();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
            onPressed: _loadRequests,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLeaveDialog(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tạo Đơn Mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: _loadRequests,
              color: const Color(0xFF6366F1),
              child: _requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_available_rounded, size: 64, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('Chưa có đơn xin nghỉ phép nào', style: TextStyle(color: Colors.white54, fontSize: 15)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openLeaveDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Gửi Đơn Xin Nghỉ Phép'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _requests.length,
                      itemBuilder: (ctx, idx) {
                        final req = _requests[idx];
                        final statusColor = _getStatusColor(req.status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.calendar_month_rounded, color: statusColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.employeeName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          '${req.leaveType} • ${req.department}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      req.status,
                                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range, color: Color(0xFF818CF8), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${req.startDate}  đến  ${req.endDate}',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text('Lý do: ${req.reason}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              if (req.reviewNote != null && req.reviewNote!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Phản hồi từ ${req.reviewedBy ?? 'Quản lý'}: "${req.reviewNote}"',
                                  style: TextStyle(color: statusColor, fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ],
                              const Divider(color: Colors.white12, height: 22),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_isAdmin && req.status == 'Chờ duyệt')
                                    ElevatedButton.icon(
                                      onPressed: () => _handleReviewDialog(req),
                                      icon: const Icon(Icons.approval, size: 16),
                                      label: const Text('Phê Duyệt / Xét Đơn'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                    )
                                  else if (req.status == 'Chờ duyệt') ...[
                                    TextButton.icon(
                                      onPressed: () => _openLeaveDialog(request: req),
                                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF818CF8)),
                                      label: const Text('Sửa', style: TextStyle(color: Color(0xFF818CF8))),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _confirmDelete(req),
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                                      label: const Text('Hủy Đơn', style: TextStyle(color: Color(0xFFEF4444))),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
