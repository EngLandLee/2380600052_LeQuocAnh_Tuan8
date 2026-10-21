import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String username;
  final String? initialDevOtp;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.username,
    this.initialDevOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _currentDevOtp;

  // Countdown timer 60s
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentDevOtp = widget.initialDevOtp;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số của mã OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyRegisterOtp(
      email: widget.email,
      otp: otp,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isLoading = true);

    final result = await _authService.resendOtp(widget.email);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _currentDevOtp = result['devOtp'];
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác Thực Mã OTP')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFE8F0FE),
                child: Icon(Icons.mark_email_read_outlined, size: 48, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Xác Thực Email',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Mã xác thực gồm 6 chữ số đã được gửi đến:\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              // Dev OTP hint banner
              if (_currentDevOtp != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    border: Border.all(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '[Dev Mode]: Mã OTP của bạn là: $_currentDevOtp',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _otpController.text = _currentDevOtp!;
                        },
                        child: const Text('Điền mã'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // OTP input box
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 16,
                  color: Colors.blue,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 16),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Xác Nhận & Hoàn Tất Đăng Ký',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
              Center(
                child: _secondsRemaining > 0
                    ? Text(
                        'Gửi lại mã sau: $_secondsRemaining giây',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      )
                    : TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Gửi lại mã OTP'),
                        onPressed: _isLoading ? null : _handleResend,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
