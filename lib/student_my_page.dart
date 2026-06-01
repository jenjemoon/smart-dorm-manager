import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentMyPage extends StatefulWidget {
  const StudentMyPage({Key? key}) : super(key: key);

  @override
  State<StudentMyPage> createState() => _StudentMyPageState();
}

class _StudentMyPageState extends State<StudentMyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatSessionStatus(String status) {
    switch (status) {
      case 'COMPLETED': return '완료';
      case 'RUNNING': return '진행 중';
      case 'OVERDUE': return '미수거';
      case 'PICKED_UP': return '수거완료';
      default: return '상태 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('마이페이지', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_currentUid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(child: Text('사용자 정보를 찾을 수 없습니다.'));
          }

          final String name = userData['name'] ?? '사용자';
          final String studentNo = userData['studentNo'] ?? '-';
          final String rcName = userData['rcName'] ?? '-';
          final String buildingName = userData['buildingName'] ?? '-';
          final int roomNo = userData['roomNo'] ?? 0;
          final int penaltyScore = userData['penaltyScore'] ?? 0;
          final String fridgeContainerNo = userData['fridgeContainerNo'] ?? '등록 정보 없음';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserProfile(name, studentNo, rcName, buildingName, roomNo, penaltyScore, fridgeContainerNo),
                const SizedBox(height: 32),

                _buildLiveStatusSection(),
                const SizedBox(height: 32),

                _buildRecentUsageSection(),
                const SizedBox(height: 32),

                _buildNotificationCenter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserProfile(String name, String studentNo, String rc, String building, int room, int penalty, String fridgeContainerNo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$name 님', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: penalty > 0 ? Colors.red.shade800 : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('벌점 $penalty점', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('학번: $studentNo', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text('소속: $rc ($building관) / $room호', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text('냉장고 보관함: $fridgeContainerNo', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLiveStatusSection() {
    return Row(
      children: [
        //세탁
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usageSessions')
                .where('userId', isEqualTo: _currentUid)
                .where('status', isEqualTo: 'RUNNING')
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              bool isRunning = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/home'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRunning ? const Color(0xFF9BC3FF) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.local_laundry_service_outlined, size: 24),
                      const SizedBox(height: 12),
                      const Text('세탁실 이용 현황', style: TextStyle(fontSize: 13, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(isRunning ? '작동 중' : '이용 중 기기 없음', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        //냉장거
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('refrigeratorItems')
                .where('userId', isEqualTo: _currentUid)
                .where('status', isEqualTo: 'ACTIVE')
                .snapshots(),
            builder: (context, snapshot) {
              int activeCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/refrigeratorHome'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activeCount > 0 ? const Color(0xFFFFD83D) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.kitchen_outlined, size: 24),
                      const SizedBox(height: 12),
                      const Text('내 냉장고 보관함', style: TextStyle(fontSize: 13, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(activeCount > 0 ? '보관 식품 $activeCount건' : '보관 식품 없음', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('최근 이용 내역', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () { /* 전체 내역 보기 */ },
              child: const Text('전체보기', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usageSessions')
              .where('userId', isEqualTo: _currentUid)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('기록된 이용 내역이 없습니다.', style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String machineId = data['machineId'] ?? '기기 정보 없음';
                final String status = data['status'] ?? '';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, size: 20, color: Colors.black54),
                          const SizedBox(width: 12),
                          Text(machineId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      Text(
                        _formatSessionStatus(status),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == 'RUNNING' ? Colors.blue : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('알림 센터', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [Tab(text: '시스템 알림'), Tab(text: '받은 메시지')],
        ),
        SizedBox(
          height: 200,
          child: TabBarView(
            controller: _tabController,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: _currentUid)
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('새로운 시스템 알림이 없습니다.', style: TextStyle(color: Colors.grey)));
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.notifications_outlined, size: 20),
                        title: Text(data['message'] ?? '', style: const TextStyle(fontSize: 13)),
                        dense: true,
                      );
                    }).toList(),
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .where('toUserId', isEqualTo: _currentUid)
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('받은 메시지함이 비어있습니다.', style: TextStyle(color: Colors.grey)));
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.mail_outline, size: 20),
                        title: Text(data['content'] ?? '', style: const TextStyle(fontSize: 13)),
                        subtitle: Text(data['fromUserName'] ?? '익명 사용자', style: const TextStyle(fontSize: 11)),
                        dense: true,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}