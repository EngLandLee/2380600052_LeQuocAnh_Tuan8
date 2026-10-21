import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import '../services/nfc_service.dart';
import 'face_checkin_screen.dart';

class NfcCheckInScreen extends StatefulWidget {
  const NfcCheckInScreen({super.key});

  @override
  State<NfcCheckInScreen> createState() => _NfcCheckInScreenState();
}

class _NfcCheckInScreenState extends State<NfcCheckInScreen>
    with SingleTickerProviderStateMixin {
  final NfcService _nfcService = NfcService();
  final AttendanceService _attendanceService = AttendanceService();

  late AnimationController _pulseController;
  bool _isNfcAvailable = true;
  bool _isProcessing = false;
  String _statusText = 'Sẵn sàng chạm thẻ nhân viên...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startNfcReading();
  }

  Future<void> _startNfcReading() async {
    final available = await _nfcService.isAvailable();
    if (!mounted) return;

    if (!available) {
      setState(() {
        _isNfcAvailable = false;
        _statusText = 'Thiết bị chưa bật hoặc không hỗ trợ NFC';
      });
      return;
    }

    setState(() {
      _isNfcAvailable = true;
      _statusText = 'Đang chờ thẻ NFC... Chạm thẻ vào mặt sau máy';
    });

    await _nfcService.startSession(
      onDiscovered: (cardId) async {
        if (_isProcessing) return;
        await _handleCardScanned(cardId);
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _statusText = error;
          });
        }
      },
    );
  }

  Future<void> _handleCardScanned(String cardId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Đã nhận diện thẻ: $cardId. Đang xác thực...';
    });

    try {
      final result = await _attendanceService.checkInNfc(cardId);
      if (result['success'] == true && mounted) {
        final record = result['record'] as AttendanceRecord;
        final user = result['user'] as Map<String, dynamic>?;
        _showSuccessSheet(record, user, cardId);
      } else {
        _showErrorSnackBar(result['message'] ?? 'Thẻ NFC chưa được đăng ký trong hệ thống.');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi xác thực thẻ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Sẵn sàng chạm thẻ nhân viên...';
        });
      }
    }
  }

  Future<void> _simulateTap() async {
    final TextEditingController cardController = TextEditingController(text: 'NFC-EMU-8899');
    final enteredCard = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Mô Phỏng Chạm Thẻ NFC', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã thẻ NFC hoặc dùng mã mặc định để kiểm tra:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cardController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                labelText: 'Mã thẻ (UID)',
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
            onPressed: () => Navigator.pop(ctx, cardController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Chạm Thẻ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (enteredCard != null && enteredCard.isNotEmpty) {
      await _handleCardScanned(enteredCard);
    }
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.credit_card_off, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSheet(
    AttendanceRecord record,
    Map<String, dynamic>? user,
    String cardId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, -10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              // Success Icon Circle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: const Icon(
                  Icons.nfc_rounded,
                  color: Color(0xFF10B981),
                  size: 54,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quẹt Thẻ NFC Thành Công!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thời gian: ${DateFormat('HH:mm:ss - dd/MM/yyyy').format(record.checkInTime.toLocal())}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Employee Card Information
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.2),
                      const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.badge, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?['fullName'] ?? 'Nhân viên',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phòng: ${user?['department'] ?? 'Văn phòng chính'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mã thẻ NFC: $cardId',
                            style: const TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons (Done OR Continue Dual-Factor)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // Chuyển sang quét Face ID để hoàn thành bảo mật kép
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FaceCheckInScreen(
                              isDualFactor: true,
                              nfcCardId: cardId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF818CF8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.security, color: Color(0xFF818CF8), size: 18),
                      label: const Text(
                        'Quét Face ID Kép',
                        style: TextStyle(color: Color(0xFF818CF8), fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Hoàn Tất',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          'Chấm Công Thẻ Từ NFC',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Status Chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isNfcAvailable
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isNfcAvailable
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isNfcAvailable ? Icons.nfc : Icons.nfc_outlined,
                      color: _isNfcAvailable
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isNfcAvailable ? 'NFC Sẵn Sàng (1 Chạm)' : 'NFC Không Khả Dụng',
                      style: TextStyle(
                        color: _isNfcAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Ripple Wave Animation Centerpiece
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: NfcRipplePainter(_pulseController.value),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 8,
                          )
                        ],
                      ),
                      child: Center(
                        child: _isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(
                                Icons.contactless_rounded,
                                size: 84,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 48),

            // Instructional text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đặt thẻ nhân viên sát phần ăng-ten NFC ở mặt lưng thiết bị',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Fallback / Demo Simulation Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: OutlinedButton.icon(
                onPressed: _simulateTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.touch_app_rounded, color: Colors.white70),
                label: const Text(
                  'Mô phỏng Chạm Thẻ (Test Demo)',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for NFC concentric ripple waves
class NfcRipplePainter extends CustomPainter {
  final double progress;

  NfcRipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 1.1;

    for (int i = 0; i < 3; i++) {
      final currentProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 110 + (maxRadius - 110) * currentProgress;
      final opacity = math.max(0.0, 1.0 - currentProgress);

      final paint = Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: opacity * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant NfcRipplePainter oldDelegate) => true;
}
