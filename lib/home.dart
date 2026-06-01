import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 경빈 push 테스트
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
// 방금 수정 완료 테스트 (혜연)
  String _formatStatus(String status) {
    switch (status) {
      case 'COMPLETED':
        return '완료';
      case 'RUNNING':
        return '진행';
      case 'OVERDUE':
        return '미수거';
      case 'PICKED_UP':
        return '수거완료';
      default:
        return '상태 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          '홈',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('로그인이 필요합니다.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;

                final name = userData?['name'] ?? '사용자';
                final role = userData?['role'] ?? 'STUDENT';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (role == 'BOTH')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '학생',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/adminHome',
                                    );
                                  },
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F0F0),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '관리자',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '안녕하세요 $name님',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '시설 카테고리',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'View all',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/machineHome');
                        },
                        child: _categoryCard(
                          color: const Color(0xFF9BC3FF),
                          icon: Icons.local_laundry_service_outlined,
                          title: '세탁',
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/refrigeratorHome');
                        },
                        child: _categoryCard(
                          color: const Color(0xFFFFD83D),
                          icon: Icons.kitchen_outlined,
                          title: '냉장고',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _categoryCard(
                        color: const Color(0xFFB8F7A7),
                        icon: Icons.notifications_none,
                        title: '알림',
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        '최근 이용 내역',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('usageSessions')
                            .where('userId', isEqualTo: uid)
                            .orderBy('createdAt', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, sessionSnapshot) {
                          if (sessionSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!sessionSnapshot.hasData ||
                              sessionSnapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                '최근 이용 내역이 없습니다.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          final sessions = sessionSnapshot.data!.docs;

                          return Column(
                            children: sessions.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;

                              final machineId = data['machineId'] ?? '기기 정보 없음';
                              final status = data['status'] ?? '';
                              final endTime = data['endTime'];

                              String subText = '이용 기록';
                              if (endTime is Timestamp) {
                                final date = endTime.toDate();
                                subText =
                                    '사용 종료 · ${date.year}.${date.month}.${date.day}';
                              }

                              return _usageItem(
                                title: machineId,
                                subtitle: subText,
                                status: _formatStatus(status),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFEAEAEA),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomItem(
              icon: Icons.star,
              label: '즐겨찾기',
              onTap: () {},
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '실행할 기능을 선택해주세요',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ListTile(
                            leading: const Icon(Icons.qr_code_scanner),
                            title: const Text('QR 스캔'),
                            subtitle: const Text('세탁기/건조기 사용 시작'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/qrScan');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt_outlined),
                            title: const Text('사진 촬영'),
                            subtitle: const Text('냉장고 식품 등록'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/camera');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E7E7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 36,
                      color: Colors.black54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '카메라',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomItem(
              icon: Icons.person_outline,
              label: '내 정보',
              onTap: () {
                Navigator.pushNamed(context, '/myPage');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard({
    required Color color,
    required IconData icon,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      height: 116,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageItem({
    required String title,
    required String subtitle,
    required String status,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.local_laundry_service_outlined),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: status == '진행' ? Colors.black : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == '진행' ? Colors.white : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
