import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/product.dart';
import '../services/attendance_service.dart';
import '../services/product_service.dart';
import '../utils/auth_helper.dart';
import 'face_checkin_screen.dart';
import 'group_video_call_screen.dart';
import 'login_screen.dart';
import 'nfc_checkin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ProductService _productService = ProductService();

  String _username = '';
  bool _isLoading = true;
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  AttendanceRecord? _todayRecord;
  List<AttendanceRecord> _history = [];
  List<Product> _products = [];
  Timer? _liveClockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startLiveClock();
  }

  void _startLiveClock() {
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final username = await AuthHelper.getUsername();
    final status = await _attendanceService.getTodayStatus();
    final history = await _attendanceService.getMyHistory(days: 14);
    final products = await _productService.getAll();

    if (mounted) {
      setState(() {
        _username = username;
        _hasCheckedIn = status['hasCheckedIn'] as bool? ?? false;
        _hasCheckedOut = status['hasCheckedOut'] as bool? ?? false;
        _todayRecord = status['todayRecord'] as AttendanceRecord?;
        _history = history;
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xác nhận kết thúc ca làm việc?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Hệ thống sẽ ghi nhận giờ Check-out và tổng thời gian làm việc hôm nay của bạn.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Check-out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _attendanceService.checkOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Check-out hoàn tất!'),
            backgroundColor: res['success'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
        _loadDashboardData();
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthHelper.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFF6366F1),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
              : CustomScrollView(
                  slivers: [
                    // Top App Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào, ${_username.isNotEmpty ? _username : 'Nhân Viên'} 👋',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_currentTime),
                                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                              tooltip: 'Đăng xuất',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Today Status Executive Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildTodayStatusCard(),
                      ),
                    ),

                    // Quick Actions Section Title
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(
                          'Tiện Ích Chấm Công & Ca Trực',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 4 Core 1-touch Actions Grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.15,
                          children: [
                            _buildActionTile(
                              title: 'Chấm Công Face ID',
                              subtitle: '3D Liveness & Mood Pulse',
                              icon: Icons.face_retouching_natural_rounded,
                              gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                              onTap: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const FaceCheckInScreen()),
                                );
                                if (res == true) _loadDashboardData();
                              },
                            ),
                            _buildActionTile(
                              title: 'Quẹt Thẻ Từ NFC',
                              subtitle: '1 chạm vào mặt sau máy',
                              icon: Icons.contactless_rounded,
                              gradientColors: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                              onTap: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NfcCheckInScreen()),
                                );
                                if (res == true) _loadDashboardData();
                              },
                            ),
                            _buildActionTile(
                              title: 'Bảo Mật Kép (Dual)',
                              subtitle: 'Thẻ NFC + Khuôn mặt',
                              icon: Icons.verified_user_rounded,
                              gradientColors: [const Color(0xFF059669), const Color(0xFF047857)],
                              onTap: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FaceCheckInScreen(isDualFactor: true),
                                  ),
                                );
                                if (res == true) _loadDashboardData();
                              },
                            ),
                            _buildActionTile(
                              title: 'Họp Video Ca Trực',
                              subtitle: 'Giao ban & kết nối nhóm',
                              icon: Icons.video_camera_front_rounded,
                              gradientColors: [const Color(0xFF9333EA), const Color(0xFF7E22CE)],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ShiftMeetingLobbyScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Attendance History Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lịch Sử Chấm Công Gần Đây',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_history.length} bản ghi',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_history.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Chưa có lịch sử chấm công',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _history[index];
                              return _buildHistoryItem(item);
                            },
                            childCount: _history.length,
                          ),
                        ),
                      ),

                    // Products from previous week (collapsible section)
                    if (_products.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          child: ExpansionTile(
                            collapsedBackgroundColor: const Color(0xFF1E293B),
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              'Kho Hàng & Sản Phẩm (${_products.length})',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            children: _products.map((p) {
                              return ListTile(
                                leading: const Icon(Icons.inventory_2, color: Color(0xFF818CF8)),
                                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                                subtitle: Text('${p.price} VNĐ', style: const TextStyle(color: Colors.white54)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);

    if (!_hasCheckedIn) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.white70, size: 14),
                      SizedBox(width: 6),
                      Text('Chưa Chấm Công', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Chào buổi sáng! Hãy chọn Face ID hoặc quẹt thẻ NFC bên dưới để bắt đầu ca làm việc của bạn.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      );
    }

    final record = _todayRecord!;
    final checkInStr = DateFormat('HH:mm').format(record.checkInTime.toLocal());
    final checkOutStr = record.checkOutTime != null
        ? DateFormat('HH:mm').format(record.checkOutTime!.toLocal())
        : '--:--';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            _hasCheckedOut ? const Color(0xFF0F172A) : const Color(0xFF1E1B4B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _hasCheckedOut
              ? Colors.white10
              : const Color(0xFF10B981).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: _hasCheckedOut
                ? Colors.transparent
                : const Color(0xFF10B981).withValues(alpha: 0.1),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasCheckedOut
                      ? Colors.white12
                      : const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _hasCheckedOut ? Colors.white54 : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _hasCheckedOut ? 'Đã Kết Thúc Ca' : 'Đang Trong Ca Trực',
                      style: TextStyle(
                        color: _hasCheckedOut ? Colors.white70 : const Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (record.energyScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Color(0xFF818CF8), size: 14),
                      Text(
                        'AI Pulse: ${record.energyScore!.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Giờ Vào', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      checkInStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cách thức: ${record.method}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Giờ Ra', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        checkOutStr,
                        style: TextStyle(
                          color: _hasCheckedOut ? Colors.white : Colors.white38,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        record.workingDuration,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!_hasCheckedOut) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _handleCheckOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'Check-out Kết Thúc Ca Làm Việc',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record) {
    final checkInStr = DateFormat('HH:mm').format(record.checkInTime.toLocal());
    final checkOutStr = record.checkOutTime != null
        ? DateFormat('HH:mm').format(record.checkOutTime!.toLocal())
        : 'Đang làm';
    final dateStr = DateFormat('dd/MM/yyyy').format(record.date.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              record.method == 'NFC'
                  ? Icons.contactless
                  : record.method == 'DualFactor'
                      ? Icons.verified_user
                      : Icons.face,
              color: const Color(0xFF818CF8),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ca: $checkInStr → $checkOutStr (${record.method})',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (record.energyScore != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 12, color: Color(0xFF10B981)),
                  Text(
                    '${record.energyScore!.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
