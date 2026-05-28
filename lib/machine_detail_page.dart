import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MachineDetailPage extends StatelessWidget {
  const MachineDetailPage({Key? key}) : super(key: key);

  String _formatType(String type) {
    return type == 'DRYER' ? '건조기' : '세탁기';
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final machineId = args['machineId'];
    final machineType = args['machineType'];

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('홈'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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

          final machineNo = machine['machineNo'] ?? '';
          final status = machine['status'] ?? 'AVAILABLE';
          final currentUserId = machine['currentUserId'] ?? '';
          final remainingTime = machine['remainingTime'] ?? '00:00';
          final progressPercent = machine['progressPercent'] ?? 0;

          final bool isUsing = status == 'USING';
          final bool isMine = currentUid != null && currentUid == currentUserId;
          final bool isAvailable = status == 'AVAILABLE';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusBadge(status),
                const SizedBox(height: 28),
                _machineInfoCard(
                  title: '${_formatType(machineType)} $machineNo번',
                  progressPercent: progressPercent,
                  remainingTime: remainingTime,
                  isUsing: isUsing,
                ),
                const SizedBox(height: 20),
                if (isAvailable)
                  _availableButtons()
                else if (isMine)
                  _myUsingButtons()
                else
                  _otherUsingButtons(machineId),
                const SizedBox(height: 28),
                const Text(
                  '메시지',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (isAvailable)
                  _messageCard(
                    icon: Icons.info_outline,
                    title: '사용 가능',
                    message: '현재 사용자가 없습니다.',
                  )
                else if (isMine) ...[
                  _messageCard(
                    icon: Icons.notifications_none,
                    title: '사용 내역',
                    message: '현재 사용 중입니다. 종료 후 세탁물을 수거해주세요.',
                  ),
                ] else ...[
                  _messageCard(
                    icon: Icons.notifications_none,
                    title: '세탁물 수거 부탁',
                    message: '사용자에게 세탁물 수거 요청 메시지를 보낼 수 있습니다.',
                  ),
                  _messageCard(
                    icon: Icons.check_circle_outline,
                    title: '세탁물 수거 완료',
                    message: '세탁물이 수거되면 다음 사용자가 이용할 수 있습니다.',
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: status == 'AVAILABLE' ? Colors.grey.shade200 : Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: status == 'AVAILABLE' ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _machineInfoCard({
    required String title,
    required int progressPercent,
    required String remainingTime,
    required bool isUsing,
  }) {
    final progress = (progressPercent / 100).clamp(0.0, 1.0);

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
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isUsing ? '$progressPercent%' : '사용 가능',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isUsing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Text('남은 시간: $remainingTime'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _availableButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.qr_code_scanner,
            title: 'QR 스캔',
            isDark: false,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.play_circle_outline,
            title: '사용 시작',
            isDark: true,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _myUsingButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.more_time,
            title: '시간 연장',
            isDark: false,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.stop_circle_outlined,
            title: '사용 종료',
            isDark: true,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _otherUsingButtons(String machineId) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.people_alt_outlined,
            title: '줄서기',
            isDark: false,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _queueInfo(machineId),
        ),
      ],
    );
  }

  Widget _queueInfo(String machineId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('machineQueues')
          .where('machineId', isEqualTo: machineId)
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        int myOrder = 0;
        final uid = FirebaseAuth.instance.currentUser?.uid;

        if (snapshot.hasData && uid != null) {
          final docs = snapshot.data!.docs;
          final index = docs.indexWhere((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['userId'] == uid;
          });

          if (index != -1) {
            myOrder = index + 1;
          }
        }

        return Container(
          height: 94,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              myOrder == 0 ? '현재 $count명 대기' : '$myOrder번째 / 총 $count명',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isDark ? Colors.white : Colors.black),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
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
}
