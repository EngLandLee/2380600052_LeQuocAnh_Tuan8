import 'package:flutter/material.dart';
import '../utils/auth_helper.dart';
import 'login_screen.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  String _username = '';
  final TextEditingController _hostController = TextEditingController(text: 'Bộ phận IT - Lê Quốc Anh');
  final TextEditingController _purposeController = TextEditingController(text: 'Tham quan & Hợp tác công nghệ WorkPulse');
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthHelper.getUsername();
    setState(() => _username = user);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cổng Check-in Khách Thăm (Visitor Hub)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Khách Thăm VIP
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'THẺ KHÁCH ĐIỆN TỬ • GUEST PASS',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 32),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Xin chào, ${_username.isNotEmpty ? _username : 'Quý Khách'}!',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chào mừng bạn đến với văn phòng công nghệ WorkPulse AI',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isCheckedIn ? Icons.check_circle : Icons.pending_actions,
                            color: _isCheckedIn ? const Color(0xFFFACC15) : Colors.white70,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isCheckedIn ? 'Trạng thái: ĐÃ CHECK-IN TẠI SẢNH' : 'Trạng thái: CHƯA CHECK-IN VÀO TÒA NHÀ',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form đăng ký vào cổng
              const Text(
                'Thông Tin Đăng Ký Khách Đến Làm Việc',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _hostController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  labelText: 'Người liên hệ / Nhân viên đón tiếp',
                  labelStyle: const TextStyle(color: Color(0xFF14B8A6)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF14B8A6)),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _purposeController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  labelText: 'Mục đích đến thăm',
                  labelStyle: const TextStyle(color: Color(0xFF14B8A6)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.meeting_room_rounded, color: Color(0xFF14B8A6)),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCheckedIn = !_isCheckedIn;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isCheckedIn
                            ? 'Xác thực check-in khách thăm thành công! Mã QR vào cổng đã được kích hoạt.'
                            : 'Đã check-out rời khỏi văn phòng.'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: Icon(_isCheckedIn ? Icons.logout_rounded : Icons.verified_user_rounded),
                  label: Text(
                    _isCheckedIn ? 'Check-out Rời Khỏi Tòa Nhà' : 'Xác Nhận Check-in Khách Thăm',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCheckedIn ? const Color(0xFFEF4444) : const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
