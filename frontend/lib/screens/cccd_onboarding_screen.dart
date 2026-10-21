import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/nfc_service.dart';

class CccdOnboardingScreen extends StatefulWidget {
  final String? initialUsername;

  const CccdOnboardingScreen({super.key, this.initialUsername});

  @override
  State<CccdOnboardingScreen> createState() => _CccdOnboardingScreenState();
}

class _CccdOnboardingScreenState extends State<CccdOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final NfcService _nfcService = NfcService();
  final AttendanceService _attendanceService = AttendanceService();

  late AnimationController _pulseController;
  bool _isProcessing = false;
  String _statusText = 'Sẵn sàng chạm thẻ CCCD gắn chip...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startNfcScanning();
  }

  Future<void> _startNfcScanning() async {
    final available = await _nfcService.isAvailable();
    if (!mounted) return;

    if (!available) {
      setState(() {
        _statusText = 'Thiết bị chưa bật hoặc không hỗ trợ NFC';
      });
      return;
    }

    setState(() {
      _statusText = 'Đang chờ thẻ... Áp thẻ CCCD gắn chip vào mặt sau máy';
    });

    await _nfcService.startSession(
      onDiscovered: (cardId) async {
        if (_isProcessing) return;
        await _handleCccdDiscovered(cardId);
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _statusText = err;
          });
        }
      },
    );
  }

  Future<void> _handleCccdDiscovered(String cardId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Đã nhận diện chip CCCD: $cardId. Đang liên kết hồ sơ...';
    });

    try {
      final res = await _attendanceService.linkMyCccd(cardId);
      if (res['success'] == true && mounted) {
        _showSuccessDialog(cardId);
      } else {
        _showErrorSnackBar(res['message'] ?? 'Không thể liên kết thẻ CCCD này');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Sẵn sàng chạm thẻ CCCD gắn chip...';
        });
      }
    }
  }

  Future<void> _simulateTap() async {
    final controller = TextEditingController(text: '066205014657');
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Mô Phỏng Chạm Chip CCCD', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số định danh con chip trên thẻ Căn cước công dân:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                labelText: 'Mã Chip CCCD (UID)',
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
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Chạm Thẻ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (entered != null && entered.isNotEmpty) {
      await _handleCccdDiscovered(entered);
    }
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String cardId) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 54),
            ),
            const SizedBox(height: 18),
            const Text(
              'Định Danh CCCD Thành Công!',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hồ sơ nhân viên mới đã được kích hoạt hoàn tất.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: Color(0xFF818CF8), size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã Chip CCCD: $cardId',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Trạng thái: Đã liên kết & Sẵn sàng chấm công 1 chạm',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Bắt Đầu Sử Dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Định Danh Nhân Viên Mới',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Card graphic
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CĂN CƯỚC CÔNG DÂN',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.sim_card_outlined, color: Color(0xFFF59E0B), size: 14),
                              SizedBox(width: 4),
                              Text('CHIP NFC', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                          ),
                          child: const Center(
                            child: Icon(Icons.memory, color: Color(0xFFFEF3C7), size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.contactless_rounded, color: Colors.white70, size: 28),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.initialUsername != null ? 'Chủ thẻ: ${widget.initialUsername}' : 'Chạm thẻ vào mặt sau điện thoại',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Animated Scanning Status
              AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, child) {
                  return Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3 + 0.4 * _pulseController.value),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Color(0xFF6366F1))
                          : const Icon(Icons.nfc_rounded, color: Color(0xFF818CF8), size: 54),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thẻ CCCD gắn chip sẽ được đồng bộ làm Thẻ nhân viên chính thức trong toàn bộ hệ thống.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),

              const Spacer(),

              // Simulation Button
              OutlinedButton.icon(
                onPressed: _simulateTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.touch_app_rounded, color: Colors.white70),
                label: const Text('Mô phỏng Chạm CCCD (Demo Test)', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
