import 'package:flutter/material.dart';
import '../models/citizen_card_info.dart';
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
      _statusText = 'Đã nhận diện chip CCCD: $cardId. Đang trích xuất dữ liệu eKYC...';
    });

    try {
      final info = await _attendanceService.readCccdInfo(cardId);
      final res = await _attendanceService.linkMyCccd(cardId);

      if (res['success'] == true && mounted) {
        _showCccdIdentityDialog(cardId, info);
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

  void _showCccdIdentityDialog(String cardId, CitizenCardInfo? info) {
    final idNumber = info?.citizenId.isNotEmpty == true ? info!.citizenId : cardId;
    final fullName = info?.fullName ?? (widget.initialUsername?.toUpperCase() ?? 'LÊ QUỐC ANH');
    final dob = info?.dateOfBirth ?? '07/09/2005';
    final gender = info?.gender ?? 'Nam';
    final origin = info?.placeOfOrigin ?? 'Tỉnh Đắk Lắk';
    final residence = info?.permanentAddress ?? 'Số 125 Phan Chu Trinh, TP. Buôn Ma Thuột, Tỉnh Đắk Lắk';
    final nationality = info?.nationality ?? 'Việt Nam';
    final ethnicity = info?.ethnicity ?? 'Kinh';
    final department = info?.department ?? 'Công Nghệ & Kỹ Thuật';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 30,
              offset: Offset(0, -10),
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Title badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Đã Đọc Dữ Liệu Chip CCCD eKYC',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Digital Citizen Identity Card (Mô phỏng Thẻ Căn Cước Công Dân Gắn Chip)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2B48), Color(0xFF0B192C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 24),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                                style: TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Độc lập - Tự do - Hạnh phúc',
                                style: TextStyle(color: Colors.white70, fontSize: 9, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.contactless_rounded, color: Colors.white60, size: 22),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Number and Gold Chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Số / No.:', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            Text(
                              idNumber,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 38,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                          ),
                          child: const Center(
                            child: Icon(Icons.memory, color: Color(0xFFFEF3C7), size: 18),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),

                    // Extracted Identity Details
                    _buildInfoRow('Họ và tên:', fullName, isBold: true, textColor: Colors.white),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildInfoRow('Ngày sinh:', dob)),
                        Expanded(child: _buildInfoRow('Giới tính:', gender)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildInfoRow('Quốc tịch:', nationality)),
                        Expanded(child: _buildInfoRow('Dân tộc:', ethnicity)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow('Quê quán:', origin),
                    const SizedBox(height: 6),
                    _buildInfoRow('Nơi thường trú:', residence),
                    const SizedBox(height: 6),
                    _buildInfoRow('Phòng ban phân công:', department, textColor: const Color(0xFF10B981)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sync notification
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thông tin nhân viên đã được kích hoạt và đồng bộ vào hệ thống WorkPulse AI.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Xác Nhận & Hoàn Tất Kích Hoạt',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color textColor = Colors.white70}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
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
          'Định Danh Nhân Viên Mới (CCCD)',
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
