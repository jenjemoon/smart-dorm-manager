import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MachineDetailPage extends StatefulWidget {
  const MachineDetailPage({Key? key}) : super(key: key);

  @override
  State<MachineDetailPage> createState() => _MachineDetailPageState();
}

class _MachineDetailPageState extends State<MachineDetailPage> {
  bool _waitingPersisted = false; // endTime 만료 시 WAITING 1회만 반영하기 위한 가드

  String _formatType(String? type) => type == 'DRYER' ? '건조기' : '세탁기';

  // laundryRoomId(숫자) -> floor 조회용
  Future<int?> _loadFloor(dynamic laundryRoomId) async {
    if (laundryRoomId == null) return null;
    final snap = await FirebaseFirestore.instance
        .collection('laundryRooms')
        .where('laundryRoomId', isEqualTo: laundryRoomId.toString())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final floor = snap.docs.first.data()['floor'];
    return floor is int ? floor : int.tryParse('$floor');
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final machineId = args['machineId'] as String;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('세탁실'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('machines')
            .doc(machineId)
            .snapshots(),
        builder: (context, machineSnapshot) {
          if (!machineSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final machine = machineSnapshot.data!.data() as Map<String, dynamic>?;
          if (machine == null) {
            return const Center(child: Text('기기 정보가 없습니다.'));
          }

          final machineType = machine['machineType'] as String?;
          final machineNo = machine['machineNo'] ?? '';
          final rawStatus = machine['status'] ?? 'AVAILABLE';
          final currentUserId = machine['currentUserId'] ?? '';
          final endTime = (machine['endTime'] as Timestamp?)?.toDate();
          final startTime = (machine['startTime'] as Timestamp?)?.toDate();
          final extendCount = (machine['extendCount'] ?? 0) as int;

          // endTime이 지났으면 USING이라도 수거대기로 간주
          final bool expired =
              endTime != null && DateTime.now().isAfter(endTime);
          final String status =
              (rawStatus == 'USING' && expired) ? 'WAITING' : rawStatus;

          final bool isMine = currentUid != null && currentUid == currentUserId;
          final bool isAvailable = status == 'AVAILABLE';

          // 소유자 화면에서만 만료 시 DB에 WAITING 한 번 반영
          if (rawStatus == 'USING' && expired && isMine && !_waitingPersisted) {
            _waitingPersisted = true;
            FirebaseFirestore.instance
                .collection('machines')
                .doc(machineId)
                .update({
              'status': 'WAITING',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          if (rawStatus == 'USING' && !expired) {
            _waitingPersisted = false; // 연장 등으로 다시 진행되면 가드 해제
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusBadge(status),
                const SizedBox(height: 28),
                FutureBuilder<int?>(
                  future: _loadFloor(machine['laundryRoomId']),
                  builder: (context, floorSnap) {
                    final floor = floorSnap.data;
                    final title = floor != null
                        ? '${_formatType(machineType)} · $floor층 · $machineNo번'
                        : '${_formatType(machineType)} $machineNo번';
                    return _MachineInfoCard(
                      title: title,
                      status: status,
                      startTime: startTime,
                      endTime: endTime,
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (isAvailable)
                  _availableButton(context)
                else if (isMine)
                  _myUsingButtons(
                    context,
                    machineId: machineId,
                    machineType: machineType,
                    status: status,
                    extendCount: extendCount,
                  )
                else
                  _otherUsingButtons(context, machineId),
                const SizedBox(height: 28),
                const Text('메시지',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (isAvailable)
                  _messageCard(
                    icon: Icons.info_outline,
                    title: '사용 가능',
                    message: 'QR을 태깅하면 바로 사용을 시작할 수 있습니다.',
                  )
                else if (isMine)
                  _messageCard(
                    icon: Icons.notifications_none,
                    title: status == 'WAITING' ? '수거 대기 중' : '사용 중',
                    message: status == 'WAITING'
                        ? '세탁이 끝났습니다. 세탁물을 수거한 뒤 사용 종료를 눌러 QR을 다시 태깅해주세요.'
                        : '사용이 진행 중입니다. 종료하려면 사용 종료 후 QR을 다시 태깅해주세요.',
                  )
                else ...[
                  _messageCard(
                    icon: Icons.notifications_none,
                    title: '세탁물 수거 요청',
                    message: '사용 중인 다른 학생에게 수거 요청을 보낼 수 있습니다.',
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    final text = status == 'AVAILABLE'
        ? '사용 가능'
        : status == 'USING'
            ? '사용 중'
            : status == 'WAITING'
                ? '수거 대기'
                : '고장';
    final isAvailable = status == 'AVAILABLE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.grey.shade200
            : status == 'WAITING'
                ? Colors.orange
                : Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isAvailable ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 사용 가능: QR 스캔으로 시작 (시작은 반드시 기기 QR을 태깅해서)
  Widget _availableButton(BuildContext context) {
    return _actionButton(
      icon: Icons.qr_code_scanner,
      title: 'QR 스캔하여 사용 시작',
      isDark: true,
      onTap: () => Navigator.pushNamed(context, '/qrScan'),
    );
  }

  // 내 기기: 시간 연장 + 사용 종료 (QR 스캔 버튼 없음)
  Widget _myUsingButtons(
    BuildContext context, {
    required String machineId,
    required String? machineType,
    required String status,
    required int extendCount,
  }) {
    final remainExtend = 3 - extendCount;
    final canExtend = remainExtend > 0;
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.more_time,
            title:
                canExtend ? '시간 연장\n(${remainExtend}회 가능)' : '연장 불가\n(3회 소진)',
            isDark: false,
            enabled: canExtend,
            onTap: () => _extendTime(context, machineId, extendCount),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.stop_circle_outlined,
            title: '사용 종료',
            isDark: true,
            // 종료는 기기 QR 재태깅으로 처리 -> QR 스캔 화면으로 이동
            onTap: () => Navigator.pushNamed(context, '/qrScan'),
          ),
        ),
      ],
    );
  }

  Future<void> _extendTime(
      BuildContext context, String machineId, int extendCount) async {
    if (extendCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연장은 최대 3회까지만 가능합니다.')),
      );
      return;
    }

    final machineRef =
        FirebaseFirestore.instance.collection('machines').doc(machineId);
    final snap = await machineRef.get();
    final data = snap.data();
    if (data == null) return;

    final currentEnd = (data['endTime'] as Timestamp?)?.toDate();
    // 이미 만료됐다면 지금부터 +10분, 아직 진행 중이면 기존 endTime +10분
    final base = (currentEnd == null || DateTime.now().isAfter(currentEnd))
        ? DateTime.now()
        : currentEnd;
    final newEnd = base.add(const Duration(minutes: 10));

    final batch = FirebaseFirestore.instance.batch();
    batch.update(machineRef, {
      'status': 'USING', // 연장하면 다시 진행 상태로
      'endTime': Timestamp.fromDate(newEnd),
      'extendCount': extendCount + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 진행 중 세션의 endTime도 동기화
    final sessions = await FirebaseFirestore.instance
        .collection('usageSessions')
        .where('machineId', isEqualTo: machineId)
        .where('status', isEqualTo: 'RUNNING')
        .limit(1)
        .get();
    if (sessions.docs.isNotEmpty) {
      batch.update(sessions.docs.first.reference, {
        'endTime': Timestamp.fromDate(newEnd),
      });
    }

    await batch.commit();

    if (!mounted) return;
    setState(() => _waitingPersisted = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('10분 연장되었습니다. (${extendCount + 1}/3)')),
    );
  }

  // 남이 사용 중: 줄서기
  Widget _otherUsingButtons(BuildContext context, String machineId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('machineQueues')
          .where('machineId', isEqualTo: machineId)
          .where('status', isEqualTo: 'WAITING')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('대기 정보를 불러올 수 없습니다.');
        }
        final docs = snapshot.data?.docs ?? [];
        final count = docs.length;

        int myOrder = 0;
        if (uid != null) {
          final index = docs.indexWhere((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['userId'] == uid;
          });
          if (index != -1) myOrder = index + 1;
        }
        final bool isQueued = myOrder != 0;

        return Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: isQueued
                    ? Icons.hourglass_bottom
                    : Icons.people_alt_outlined,
                title: isQueued ? '대기중\n${myOrder}번째' : '줄서기',
                isDark: isQueued,
                onTap: () {
                  if (isQueued) {
                    _cancelQueue(context, machineId);
                  } else {
                    _joinQueue(context, machineId);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 94,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    myOrder == 0 ? '현재 $count명 대기' : '$myOrder번째 / 총 $count명',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final Color bg = !enabled
        ? Colors.grey.shade300
        : isDark
            ? Colors.black
            : Colors.grey.shade200;
    final Color fg = !enabled
        ? Colors.grey.shade500
        : isDark
            ? Colors.white
            : Colors.black;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinQueue(BuildContext context, String machineId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final existing = await FirebaseFirestore.instance
        .collection('machineQueues')
        .where('machineId', isEqualTo: machineId)
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'WAITING')
        .get();
    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 줄서기 중입니다.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('machineQueues').add({
      'machineId': machineId,
      'userId': user.uid,
      'status': 'WAITING',
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('줄서기가 완료되었습니다.')),
    );
  }

  Future<void> _cancelQueue(BuildContext context, String machineId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final queueDocs = await FirebaseFirestore.instance
        .collection('machineQueues')
        .where('machineId', isEqualTo: machineId)
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'WAITING')
        .get();
    for (final doc in queueDocs.docs) {
      await doc.reference.update({
        'status': 'CANCELLED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('줄서기가 취소되었습니다.')),
    );
  }
}

// ── 실시간 카운트다운 카드 ──────────────────────────────
class _MachineInfoCard extends StatelessWidget {
  final String title;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;

  const _MachineInfoCard({
    required this.title,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = status == 'AVAILABLE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('세탁 시설'),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 28),
          if (isAvailable)
            const Text('사용 가능',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))
          else if (endTime == null)
            const Text('시간 정보 없음',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
          else
            StreamBuilder<int>(
              stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
              builder: (context, _) {
                final now = DateTime.now();
                final diff = endTime!.difference(now);
                final total = (startTime != null)
                    ? endTime!.difference(startTime!).inSeconds
                    : 0;
                final remainSec = diff.inSeconds;
                final progress =
                    (total > 0) ? (remainSec / total).clamp(0.0, 1.0) : 0.0;

                final bool done = remainSec <= 0;
                final mm = (remainSec.abs() ~/ 60).toString().padLeft(2, '0');
                final ss = (remainSec.abs() % 60).toString().padLeft(2, '0');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? '수거 대기' : '$mm:$ss',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: done ? Colors.orange : Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: done ? 1.0 : progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        color: done ? Colors.orange : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      done ? '세탁이 끝났습니다. 수거 후 종료해주세요.' : '남은 시간',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
