import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/meeting_room.dart';
import '../services/meeting_service.dart';
import '../utils/auth_helper.dart';

/// Màn hình Danh sách & Tạo phòng họp ca trực (Lobby)
class ShiftMeetingLobbyScreen extends StatefulWidget {
  const ShiftMeetingLobbyScreen({super.key});

  @override
  State<ShiftMeetingLobbyScreen> createState() => _ShiftMeetingLobbyScreenState();
}

class _ShiftMeetingLobbyScreenState extends State<ShiftMeetingLobbyScreen> {
  final MeetingService _meetingService = MeetingService();
  List<MeetingRoom> _rooms = [];
  bool _isLoading = true;
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final user = await AuthHelper.getUsername();
    final rooms = await _meetingService.getActiveRooms();
    if (mounted) {
      setState(() {
        _currentUsername = user;
        _rooms = rooms;
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewRoomDialog() async {
    final titleController = TextEditingController(text: 'Giao ban ca trực - ${DateTime.now().hour}h00');
    final room = await showDialog<MeetingRoom?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Tạo Phòng Họp Ca Mới', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập tiêu đề cuộc họp bàn giao ca:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                labelText: 'Tiêu đề cuộc họp',
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
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final newRoom = await _meetingService.createRoom(title: title);
              if (ctx.mounted) {
                Navigator.pop(ctx, newRoom);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Bắt Đầu Ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (room != null && mounted) {
      _enterRoom(room);
    }
  }

  void _enterRoom(MeetingRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveVideoCallScreen(room: room),
      ),
    ).then((_) => _loadInitialData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Họp Giao Ban Ca Trực',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewRoomDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.video_call_rounded, color: Colors.white),
        label: const Text(
          'Tạo Phòng Mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitialData,
          color: const Color(0xFF6366F1),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Xin chào, ${_currentUsername.isNotEmpty ? _currentUsername : 'Bạn'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Kết nối trực tiếp với đội ngũ ca trực',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_rooms.length} phòng đang trực tuyến',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Các Phòng Họp Đang Hoạt Động',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_rooms.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 48, color: Colors.white38),
                            const SizedBox(height: 12),
                            const Text(
                              'Chưa có phòng họp nào đang mở',
                              style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Nhấn "Tạo Phòng Mới" bên dưới để bắt đầu cuộc gọi với đồng đội',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._rooms.map((room) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.video_camera_front_rounded,
                                  color: Color(0xFF818CF8),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mã: #${room.roomCode} • Bởi ${room.creatorName}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _enterRoom(room),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text(
                                  'Vào họp',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Màn hình Cuộc gọi Video Nhóm Trực Tiếp
class ActiveVideoCallScreen extends StatefulWidget {
  final MeetingRoom room;

  const ActiveVideoCallScreen({super.key, required this.room});

  @override
  State<ActiveVideoCallScreen> createState() => _ActiveVideoCallScreenState();
}

class _ActiveVideoCallScreenState extends State<ActiveVideoCallScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isMicMuted = false;
  bool _isVideoOff = false;

  Timer? _callDurationTimer;
  int _callSeconds = 0;

  final List<Map<String, dynamic>> _simulatedParticipants = [
    {
      'name': 'Nguyễn Văn An (Trưởng Ca)',
      'role': 'Giám sát vận hành',
      'avatarColor': const Color(0xFF3B82F6),
      'isSpeaking': true,
      'energyScore': 94,
    },
    {
      'name': 'Trần Minh Quân',
      'role': 'Kỹ thuật viên ca 1',
      'avatarColor': const Color(0xFF10B981),
      'isSpeaking': false,
      'energyScore': 86,
    },
    {
      'name': 'Lê Thị Mai',
      'role': 'Hậu cần & Điều phối',
      'avatarColor': const Color(0xFFEC4899),
      'isSpeaking': false,
      'energyScore': 78,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initFrontCamera();
    _startCallTimer();
  }

  void _startCallTimer() {
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callSeconds++;
        });
      }
    });
  }

  Future<void> _initFrontCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

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
      debugPrint('Camera error in Video Call: $e');
    }
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _sendReaction(String emoji) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bạn đã gửi cảm xúc $emoji đến cả nhóm'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Room Code & Duration Timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'REC ${_formatDuration(_callSeconds)}',
                          style: const TextStyle(
                            color: Colors.white,
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '#${widget.room.roomCode}',
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Video Participants Grid (2x2 layout)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3 / 4,
                  children: [
                    // Tile 1: Current User (Local Camera Feed)
                    _buildLocalUserTile(),

                    // Tiles 2, 3, 4: Other members in shift
                    ..._simulatedParticipants.map((p) => _buildRemoteUserTile(p)),
                  ],
                ),
              ),
            ),

            // Reactions quick bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['👍', '👏', '🎯', '🔥', '💡'].map((emoji) {
                  return InkWell(
                    onTap: () => _sendReaction(emoji),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bottom In-Call Controls Dock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic Mute Toggle
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isMicMuted = !_isMicMuted;
                      });
                    },
                    icon: Icon(
                      _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: _isMicMuted ? const Color(0xFFEF4444) : Colors.white,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isMicMuted
                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(14),
                    ),
                  ),

                  // Camera On/Off Toggle
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isVideoOff = !_isVideoOff;
                      });
                    },
                    icon: Icon(
                      _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                      color: _isVideoOff ? const Color(0xFFEF4444) : Colors.white,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isVideoOff
                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(14),
                    ),
                  ),

                  // Hang up / Leave Call Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(18),
                      elevation: 4,
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalUserTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_isVideoOff && _isCameraInitialized && _cameraController != null)
              CameraPreview(_cameraController!)
            else
              Container(
                color: const Color(0xFF312E81),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_rounded, size: 48, color: Colors.white70),
                      SizedBox(height: 6),
                      Text('Camera đã tắt', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ),

            // Badge overlay: "Tôi (Bạn)" & Mic status
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tôi (Bạn)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      _isMicMuted ? Icons.mic_off : Icons.mic,
                      color: _isMicMuted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteUserTile(Map<String, dynamic> participant) {
    final bool isSpeaking = participant['isSpeaking'] as bool;
    final String name = participant['name'] as String;
    final Color color = participant['avatarColor'] as Color;
    final int score = participant['energyScore'] as int;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpeaking ? const Color(0xFF10B981) : Colors.white10,
          width: isSpeaking ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder Avatar representation
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.3), const Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: color,
                  child: Text(
                    name.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // AI Pulse Score badge on top right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 12, color: Color(0xFF10B981)),
                    Text(
                      '$score%',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Name and speaking indicator
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isSpeaking)
                      const Icon(Icons.volume_up, color: Color(0xFF10B981), size: 14)
                    else
                      const Icon(Icons.mic, color: Colors.white54, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
