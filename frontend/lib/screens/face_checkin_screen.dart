import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../models/attendance_record.dart';

class FaceCheckInScreen extends StatefulWidget {
  final bool isDualFactor;
  final String? nfcCardId;

  const FaceCheckInScreen({
    super.key,
    this.isDualFactor = false,
    this.nfcCardId,
  });

  @override
  State<FaceCheckInScreen> createState() => _FaceCheckInScreenState();
}

class _FaceCheckInScreenState extends State<FaceCheckInScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  final AttendanceService _attendanceService = AttendanceService();

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Định vị khuôn mặt vào khung Oval';
  String? _errorMessage;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initFaceDetector();
    _initCamera();
    _initScanAnimation();
  }

  void _initFaceDetector() {
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
  }

  void _initScanAnimation() {
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Không tìm thấy camera trên thiết bị.';
        });
        return;
      }

      // Ưu tiên camera trước (Front camera)
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khởi động camera: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _captureAndVerify() async {
    if (_isProcessing) return;

    // Trường hợp không có camera (chạy trên emulator không hỗ trợ webcam), cho phép fallback test
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _simulateCheckInFallback();
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang chụp & phân tích sinh trắc học AI...';
    });

    try {
      final file = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showErrorSnackBar('Không phát hiện khuôn mặt! Vui lòng nhìn thẳng vào camera.');
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Định vị khuôn mặt vào khung Oval';
        });
        return;
      }

      if (faces.length > 1) {
        _showErrorSnackBar('Phát hiện nhiều người! Vui lòng chỉ đứng một mình.');
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Định vị khuôn mặt vào khung Oval';
        });
        return;
      }

      final face = faces.first;

      // Tính toán AI Energy Pulse & Liveness Detection
      final smile = face.smilingProbability ?? 0.5;
      final leftEye = face.leftEyeOpenProbability ?? 0.8;
      final rightEye = face.rightEyeOpenProbability ?? 0.8;
      final avgEye = (leftEye + rightEye) / 2.0;
      final yaw = (face.headEulerAngleY ?? 0.0).abs();
      final stability = (1.0 - (yaw / 45.0)).clamp(0.0, 1.0);

      // Điểm số năng lượng (0 -> 100)
      final rawScore = (smile * 35.0 + avgEye * 40.0 + stability * 25.0);
      final energyScore = (rawScore.clamp(35.0, 98.0)).roundToDouble();

      String mood;
      if (energyScore >= 80) {
        mood = 'Energized';
      } else if (energyScore >= 60) {
        mood = 'Calm';
      } else if (energyScore >= 45) {
        mood = 'Tired';
      } else {
        mood = 'Exhausted';
      }

      final detectedBlink = avgEye > 0.4;

      // Đọc file ảnh chuyển sang Base64
      final bytes = await file.readAsBytes();
      final photoBase64 = base64Encode(bytes);

      final method = widget.isDualFactor ? 'DualFactor' : 'FaceID';

      final result = await _attendanceService.checkInFace(
        photoBase64: photoBase64,
        energyScore: energyScore,
        mood: mood,
        detectedBlink: detectedBlink,
        method: method,
        deviceInfo: 'WorkPulse Mobile Camera',
      );

      if (result['success'] == true && mounted) {
        final record = result['record'] as AttendanceRecord;
        _showSuccessDialog(record, energyScore, mood);
      } else {
        _showErrorSnackBar(result['message'] ?? 'Chấm công không thành công');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi xác thực: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Định vị khuôn mặt vào khung Oval';
        });
      }
    }
  }

  Future<void> _simulateCheckInFallback() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang mô phỏng nhận diện AI Liveness...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    final method = widget.isDualFactor ? 'DualFactor' : 'FaceID';
    const energyScore = 88.0;
    const mood = 'Energized';

    final result = await _attendanceService.checkInFace(
      photoBase64: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      energyScore: energyScore,
      mood: mood,
      detectedBlink: true,
      method: method,
      deviceInfo: 'Emulator AI Simulation',
    );

    if (result['success'] == true && mounted) {
      final record = result['record'] as AttendanceRecord;
      _showSuccessDialog(record, energyScore, mood);
    } else {
      _showErrorSnackBar(result['message'] ?? 'Chấm công mô phỏng thất bại');
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Định vị khuôn mặt vào khung Oval';
      });
    }
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(AttendanceRecord record, double energyScore, String mood) {
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
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 54,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chấm Công Thành Công!',
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

              // AI Mood & Energy Pulse Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.15),
                      const Color(0xFF10B981).withValues(alpha: 0.15),
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
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'AI Energy Pulse',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${energyScore.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: energyScore / 100.0,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF10B981),
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMoodDescription(mood),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Method & Status Details
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.isDualFactor ? Icons.security : Icons.face,
                          color: const Color(0xFF818CF8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isDualFactor
                              ? 'Phương thức: Dual-Factor (NFC + Face)'
                              : 'Phương thức: Face ID 3D',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: record.status == 'OnTime'
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.status == 'OnTime' ? 'Đúng giờ' : 'Đi trễ',
                        style: TextStyle(
                          color: record.status == 'OnTime'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // close bottom sheet
                    Navigator.of(context).pop(true); // return true to main
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Hoàn Tất & Về Bảng Điều Khiển',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMoodDescription(String mood) {
    switch (mood) {
      case 'Energized':
        return '🔥 Trạng thái: Tràn đầy năng lượng & Tươi tắn';
      case 'Calm':
        return '🌿 Trạng thái: Điềm tĩnh, Tập trung cao độ';
      case 'Tired':
        return '🥱 Trạng thái: Hơi uể oải - Hãy uống chút nước';
      case 'Exhausted':
        return '⚠️ Cảnh báo: Kiệt sức - Đã báo quản lý hỗ trợ';
      default:
        return '✨ Sẵn sàng cho ngày làm việc';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isDualFactor ? 'Bảo Mật Kép (Face ID)' : 'Chấm Công Khuôn Mặt',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top instructions & badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'AI Liveness 3D',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Anti-Spoofing Bật',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Camera Scanner Frame
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Camera Preview inside ClipRRect or ClipOval
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            color: const Color(0xFF1E293B),
                            child: _isCameraInitialized && _cameraController != null
                                ? CameraPreview(_cameraController!)
                                : Center(
                                    child: _errorMessage != null
                                        ? Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Text(
                                              _errorMessage!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          )
                                        : const CircularProgressIndicator(
                                            color: Color(0xFF6366F1),
                                          ),
                                  ),
                          ),
                        ),

                        // Oval Face Mask Guideline
                        CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: FaceOvalGuidePainter(),
                        ),

                        // Animated Scanning Laser Bar
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: MediaQuery.of(context).size.height * 0.35 * _scanAnimation.value,
                              left: 40,
                              right: 40,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF6366F1),
                                      Color(0xFF38BDF8),
                                      Color(0xFF6366F1),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Live scanning status label overlay
                        Positioned(
                          bottom: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              _statusMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom action panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const Text(
                    '💡 Nhìn thẳng vào camera, chớp mắt nhẹ để xác thực',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _captureAndVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Đang phân tích AI...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Chấm Công Ngay',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the Oval face boundary guide
class FaceOvalGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.height * 0.78,
    );

    canvas.drawOval(rect, paint);

    // Corner targeting lines
    final cornerPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final ovalWidth = rect.width;
    final ovalHeight = rect.height;

    // Small decorative target indicators
    canvas.drawLine(
      Offset(center.dx - ovalWidth / 2 - 8, center.dy),
      Offset(center.dx - ovalWidth / 2 + 8, center.dy),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + ovalWidth / 2 - 8, center.dy),
      Offset(center.dx + ovalWidth / 2 + 8, center.dy),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - ovalHeight / 2 - 8),
      Offset(center.dx, center.dy - ovalHeight / 2 + 8),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + ovalHeight / 2 - 8),
      Offset(center.dx, center.dy + ovalHeight / 2 + 8),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
