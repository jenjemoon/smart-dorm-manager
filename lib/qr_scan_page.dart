import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({Key? key}) : super(key: key);

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;

  // route arguments에서 stopMode 여부와 기기 ID 받기
  String? _expectedMachineId; // 종료 모드일 때 재태깅 확인용
  bool _isStopMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _isStopMode = args['mode'] == 'STOP';
      _expectedMachineId = args['machineId'] as String?;
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    _cameraController.stop();

    final doc = await FirebaseFirestore.instance
        .collection('machines')
        .doc(code)
        .get();

    if (!doc.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('등록되지 않은 기기입니다.')));
      setState(() => _isProcessing = false);
      _cameraController.start();
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'AVAILABLE';
    final currentUserId = data['currentUserId'] ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // ── 종료 모드: 사용 종료 버튼 누르고 재태깅 ──
    if (_isStopMode) {
      if (_expectedMachineId != null && code != _expectedMachineId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용 중인 기기와 다른 QR입니다.')));
        setState(() => _isProcessing = false);
        _cameraController.start();
        return;
      }
      await _stopMachine(code, uid);
      return;
    }

    // ── 일반 스캔 모드 ──
    if (status == 'AVAILABLE') {
      // 사용 가능 → 시작 확인 바텀시트
      _showStartBottomSheet(code, data);
    } else if ((status == 'USING' || status == 'WAITING') &&
        uid != null &&
        currentUserId == uid) {
      // 내가 사용 중 → 종료 확인 바텀시트
      _showStopBottomSheet(code, data);
    } else {
      // 다른 사람이 사용 중
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 다른 사용자가 이용 중인 기기입니다.')));
      setState(() => _isProcessing = false);
      _cameraController.start();
    }
  }

  // ── 사용 시작 바텀시트 ──
  void _showStartBottomSheet(String machineId, Map<String, dynamic> data) {
    final typeStr = data['machineType'] == 'DRYER' ? '건조기' : '세탁기';
    final floor = data['floor'] ?? '?';
    final machineNo = data['machineNo'] ?? '';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$floor층 $typeStr',
                          style: const TextStyle(color: Colors.grey)),
                      Text('$machineNo번 기기',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('기본 사용 시간: 50분',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _startMachine(machineId, data['machineType']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('시작',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 사용 종료 바텀시트 (내가 사용 중일 때 재태깅) ──
  void _showStopBottomSheet(String machineId, Map<String, dynamic> data) {
    final typeStr = data['machineType'] == 'DRYER' ? '건조기' : '세탁기';
    final floor = data['floor'] ?? '?';
    final machineNo = data['machineNo'] ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$floor층 $typeStr',
                          style: const TextStyle(color: Colors.grey)),
                      Text('$machineNo번 기기',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('사용을 종료하시겠습니까?',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _stopMachine(machineId, uid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('종료',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 시작 처리 ──
  Future<void> _startMachine(String machineId, String machineType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final endTime = now.add(const Duration(minutes: 50));

    final batch = FirebaseFirestore.instance.batch();

    final machineRef =
        FirebaseFirestore.instance.collection('machines').doc(machineId);
    batch.update(machineRef, {
      'status': 'USING',
      'currentUserId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final usageRef =
        FirebaseFirestore.instance.collection('usageSessions').doc();
    batch.set(usageRef, {
      'userId': uid,
      'machineId': machineId,
      'machineType': machineType,
      'status': 'RUNNING',
      'startTime': Timestamp.fromDate(now),
      'endTime': Timestamp.fromDate(endTime),
      'extendCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (!mounted) return;
    Navigator.pop(context); // 바텀시트 닫기
    Navigator.pushReplacementNamed(context, '/machineDetail',
        arguments: {'machineId': machineId, 'machineType': machineType});
  }

  // ── 종료 처리 ──
  Future<void> _stopMachine(String machineId, String? uid) async {
    if (uid == null) return;

    // 진행 중인 세션 찾기
    final sessionQuery = await FirebaseFirestore.instance
        .collection('usageSessions')
        .where('machineId', isEqualTo: machineId)
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'RUNNING')
        .get();

    final batch = FirebaseFirestore.instance.batch();

    // 세션 COMPLETED 처리
    for (final doc in sessionQuery.docs) {
      batch.update(doc.reference, {
        'status': 'COMPLETED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 기기 AVAILABLE로 초기화
    final machineRef =
        FirebaseFirestore.instance.collection('machines').doc(machineId);
    batch.update(machineRef, {
      'status': 'AVAILABLE',
      'currentUserId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (!mounted) return;
    // 바텀시트가 열려있으면 닫고
    if (Navigator.canPop(context)) Navigator.pop(context);
    // 홈으로
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isStopMode ? 'QR 재태깅 (종료)' : 'QR 스캔',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _cameraController, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isStopMode ? Colors.red : Colors.yellow,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isStopMode
                    ? '사용한 기기의 QR을 스캔하세요'
                    : 'QR 코드를 사각형 안에 맞춰주세요',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}