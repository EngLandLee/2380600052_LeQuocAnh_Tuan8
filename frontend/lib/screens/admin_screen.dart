import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/category.dart';
import '../models/energy_analytics.dart';
import '../models/meeting_room.dart';
import '../models/product.dart';
import '../services/attendance_service.dart';
import '../services/category_service.dart';
import '../services/meeting_service.dart';
import '../services/product_service.dart';
import '../utils/auth_helper.dart';
import 'group_video_call_screen.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final AttendanceService _attendanceService = AttendanceService();
  final MeetingService _meetingService = MeetingService();
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  String _adminUsername = '';

  List<AttendanceRecord> _todayRecords = [];
  EnergyAnalytics? _energyAnalytics;
  List<MeetingRoom> _meetingRooms = [];
  List<Category> _categories = [];
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);
    final user = await AuthHelper.getUsername();
    final today = await _attendanceService.getAllTodayRecords();
    final energy = await _attendanceService.getEnergyAnalytics();
    final rooms = await _meetingService.getActiveRooms();
    final cats = await _categoryService.getAll();
    final prods = await _productService.getAll();

    if (mounted) {
      setState(() {
        _adminUsername = user;
        _todayRecords = today;
        _energyAnalytics = energy;
        _meetingRooms = rooms;
        _categories = cats;
        _products = prods;
        _isLoading = false;
      });
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

  // Dialog gán thẻ NFC cho nhân viên
  Future<void> _showRegisterNfcDialog() async {
    final userController = TextEditingController();
    final nfcController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Gán Thẻ NFC Nhân Viên', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                labelText: 'User ID hoặc Tên nhân viên',
                labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nfcController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                labelText: 'Mã Thẻ NFC (UID)',
                labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = userController.text.trim();
              final nfc = nfcController.text.trim();
              if (uid.isEmpty || nfc.isEmpty) return;

              final ok = await _attendanceService.registerNfcCard(uid, nfc);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Gán thẻ NFC thành công!' : 'Lỗi khi gán thẻ NFC'),
                    backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Lưu Thẻ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WorkPulse AI • Quản Trị Viên',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Xin chào, ${_adminUsername.isNotEmpty ? _adminUsername : 'Admin'}',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Tải lại dữ liệu',
            onPressed: _loadAllAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: const Color(0xFF818CF8),
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Ca Trực Hôm Nay'),
            Tab(icon: Icon(Icons.bolt_rounded), text: 'AI Mood & Sức Khỏe'),
            Tab(icon: Icon(Icons.video_call_rounded), text: 'Họp & Thẻ NFC'),
            Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Kho & Danh Mục'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayAttendanceTab(),
                _buildEnergyAnalyticsTab(),
                _buildShiftMeetingTab(),
                _buildInventoryTab(),
              ],
            ),
    );
  }

  // TAB 1: Real-time Attendance Monitor
  Widget _buildTodayAttendanceTab() {
    return RefreshIndicator(
      onRefresh: _loadAllAdminData,
      color: const Color(0xFF6366F1),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat Header Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Đã Điểm Danh',
                  value: '${_todayRecords.length}',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Đúng Giờ',
                  value: '${_todayRecords.where((r) => r.status == 'OnTime').length}',
                  icon: Icons.timer_rounded,
                  color: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Đi Trễ',
                  value: '${_todayRecords.where((r) => r.status == 'Late').length}',
                  icon: Icons.warning_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'Nhật Ký Chấm Công Trực Tiếp',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_todayRecords.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Chưa có nhân viên nào check-in hôm nay', style: TextStyle(color: Colors.white38)),
              ),
            )
          else
            ..._todayRecords.map((r) => _buildAttendanceAdminCard(r)),
        ],
      ),
    );
  }

  Widget _buildAttendanceAdminCard(AttendanceRecord r) {
    final checkInStr = DateFormat('HH:mm:ss').format(r.checkInTime.toLocal());
    final checkOutStr = r.checkOutTime != null
        ? DateFormat('HH:mm:ss').format(r.checkOutTime!.toLocal())
        : 'Đang làm việc';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF6366F1),
                radius: 18,
                child: Text(
                  (r.fullName ?? r.userName ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.fullName ?? r.userName ?? 'Nhân viên',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Phòng: ${r.department ?? 'Chưa phân ban'} • User: ${r.userName ?? ''}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: r.status == 'OnTime'
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.status == 'OnTime' ? 'Đúng Giờ' : 'Đi Trễ',
                  style: TextStyle(
                    color: r.status == 'OnTime' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Check-in: $checkInStr', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text('Check-out: $checkOutStr', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Phương thức: ${r.method}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
              const Spacer(),
              if (r.energyScore != null)
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFF10B981), size: 14),
                    Text(
                      'AI Pulse: ${r.energyScore!.toStringAsFixed(0)}% (${r.mood ?? ''})',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: AI Mood & Energy Pulse Analytics (Unique Innovation)
  Widget _buildEnergyAnalyticsTab() {
    final analytics = _energyAnalytics;
    if (analytics == null) {
      return const Center(child: Text('Chưa có dữ liệu phân tích', style: TextStyle(color: Colors.white38)));
    }

    return RefreshIndicator(
      onRefresh: _loadAllAdminData,
      color: const Color(0xFF6366F1),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Average Energy Score Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chỉ Số Năng Lượng Đội Ngũ',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${analytics.averageEnergyScore.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Được tổng hợp từ camera AI 3D Liveness lúc check-in',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_rounded, size: 48, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Mood Breakdown Pills
          const Text(
            'Phân Bố Trạng Thái Tinh Thần',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: analytics.moodBreakdown.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getMoodIcon(entry.key), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${entry.value} người',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Burnout Risk Alerts (Cảnh báo kiệt sức cho quản lý)
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Cảnh Báo Nguy Cơ Kiệt Sức (Burnout Risk)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${analytics.burnoutRiskAlerts.length} cảnh báo',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (analytics.burnoutRiskAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sentiment_very_satisfied, color: Color(0xFF10B981)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tất cả nhân sự hôm nay đều tràn đầy năng lượng, không phát hiện nguy cơ kiệt sức!',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            ...analytics.burnoutRiskAlerts.map((user) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      child: const Icon(Icons.person_off_rounded, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName.isNotEmpty ? user.fullName : user.userName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Phòng: ${user.department} • Trạng thái: ${user.mood}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${user.energyScore.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // TAB 3: Shift Meeting & NFC Registration
  Widget _buildShiftMeetingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Action to Register NFC
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.contactless, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gán Thẻ Từ NFC Nhân Viên',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Liên kết UID thẻ từ vật lý vào tài khoản nhân viên',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showRegisterNfcDialog,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                child: const Text('Gán Thẻ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Các Phòng Họp Trực Tuyến Đang Mở',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShiftMeetingLobbyScreen()),
                );
              },
              icon: const Icon(Icons.open_in_new, color: Color(0xFF818CF8)),
              tooltip: 'Mở Sảnh Họp',
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_meetingRooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('Không có phòng họp nào đang hoạt động', style: TextStyle(color: Colors.white38)),
            ),
          )
        else
          ..._meetingRooms.map((room) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: Color(0xFF818CF8), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Mã: #${room.roomCode} • Bởi ${room.creatorName}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
                    tooltip: 'Đóng phòng này',
                    onPressed: () async {
                      await _meetingService.closeRoom(room.roomCode);
                      _loadAllAdminData();
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // TAB 4: Kho & Danh Mục (Preserving Week 7 CRUD)
  Widget _buildInventoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Danh Mục Sản Phẩm (${_categories.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
              onPressed: () => _showCategoryDialog(),
            ),
          ],
        ),
        ..._categories.map((c) => ListTile(
              leading: const Icon(Icons.category, color: Color(0xFF818CF8)),
              title: Text(c.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(c.description ?? '', style: const TextStyle(color: Colors.white54)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: () async {
                  await _categoryService.delete(c.id);
                  _loadAllAdminData();
                },
              ),
            )),
        const Divider(color: Colors.white12, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sản Phẩm Trong Kho (${_products.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
              onPressed: () => _showProductDialog(),
            ),
          ],
        ),
        ..._products.map((p) => ListTile(
              leading: const Icon(Icons.inventory_2, color: Color(0xFF38BDF8)),
              title: Text(p.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text('${p.price} VNĐ • ${p.description ?? ''}', style: const TextStyle(color: Colors.white54)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: () async {
                  await _productService.delete(p.id);
                  _loadAllAdminData();
                },
              ),
            )),
      ],
    );
  }

  void _showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(category == null ? 'Thêm Danh Mục' : 'Sửa Danh Mục', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Tên danh mục', labelStyle: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Mô tả', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim().isEmpty ? null : descController.text.trim();
              if (name.isEmpty) return;

              if (category == null) {
                await _categoryService.create(name, desc);
              } else {
                await _categoryService.update(category.id, name, desc);
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _loadAllAdminData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    int? selectedCatId = product?.categoryId ?? (_categories.isNotEmpty ? _categories.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(product == null ? 'Thêm Sản Phẩm' : 'Sửa Sản Phẩm', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Tên sản phẩm', labelStyle: TextStyle(color: Colors.white70)),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Giá', labelStyle: TextStyle(color: Colors.white70)),
              ),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Mô tả sản phẩm', labelStyle: TextStyle(color: Colors.white70)),
              ),
              if (_categories.isNotEmpty)
                DropdownButton<int?>(
                  dropdownColor: const Color(0xFF1E293B),
                  value: selectedCatId,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Không có danh mục', style: TextStyle(color: Colors.white54))),
                    ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(color: Colors.white)))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedCatId = val),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0;
                final desc = descController.text.trim().isEmpty ? null : descController.text.trim();
                if (name.isEmpty) return;

                if (product == null) {
                  await _productService.create(name, price, desc, selectedCatId);
                } else {
                  await _productService.update(product.id, name, price, desc, selectedCatId);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _loadAllAdminData();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  String _getMoodIcon(String mood) {
    switch (mood) {
      case 'Energized':
        return '🔥';
      case 'Calm':
        return '🌿';
      case 'Tired':
        return '🥱';
      case 'Exhausted':
        return '⚠️';
      default:
        return '✨';
    }
  }
}
