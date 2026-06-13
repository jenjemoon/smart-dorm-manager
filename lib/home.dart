import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

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

  void _showCameraModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '무엇을 실행할까요?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF9BC3FF),
                    child: Icon(Icons.qr_code_2, color: Colors.black),
                  ),
                  title: const Text('QR 스캔',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('세탁기 / 건조기 사용 시작'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/qrScan');
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFD83D),
                    child: Icon(Icons.camera_alt, color: Colors.black),
                  ),
                  title: const Text('음식 등록',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('냉장고 보관 식품 등록'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/refrigeratorCamera');
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
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
        title: const Text('홈', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 30),
            onPressed: () => Navigator.pushNamed(context, '/notificationPage'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말 로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  );
                },
              );

              if (result == true) {
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: uid != null
          ? Container(
              height: 65,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () => _showCameraModal(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            )
          : null,
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
                                    child: Text('학생',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(
                                      context, '/adminHome'),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F0F0),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Center(
                                      child: Text('관리자',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 인사말 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '안녕하세요\n$name님',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/studentMy'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    '마이페이지',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        '시설 카테고리',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/machineHome'),
                        child: _categoryCard(
                          color: const Color(0xFF9BC3FF),
                          icon: Icons.local_laundry_service_outlined,
                          title: '세탁',
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/refrigeratorHome'),
                        child: _categoryCard(
                          color: const Color(0xFFFFD83D),
                          icon: Icons.kitchen_outlined,
                          title: '냉장고',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // -- 사용 중 / 수거 대기 기기 실시간 모듈 (알림 자리) --
                      // 사용 중인 기기가 없으면 자리째 접혀서 빈 여백이 안 생김
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('usageSessions')
                            .where('userId', isEqualTo: uid)
                            .where('status', isEqualTo: 'RUNNING')
                            .limit(1)
                            .snapshots(),
                        builder: (context, activeSnapshot) {
                          // 로딩 중엔 빈 자리
                          if (activeSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          // 에러(색인 없음 등)면 콘솔에 찍고 숨김
                          if (activeSnapshot.hasError) {
                            debugPrint('사용중 모듈 오류: ${activeSnapshot.error}');
                            return const SizedBox.shrink();
                          }
                          // 사용 중 기기 없으면 자리 완전히 비움
                          if (!activeSnapshot.hasData ||
                              activeSnapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final activeSession = activeSnapshot.data!.docs.first
                              .data() as Map<String, dynamic>;
                          final machineId = activeSession['machineId'] ?? '';
                          final endTime =
                              activeSession['endTime'] as Timestamp?;
                          final machineType =
                              activeSession['machineType'] ?? 'WASHER';

                          // 기기 정보 실시간 조회 (종류 + 층 + 번호)
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('machines')
                                .doc(machineId)
                                .snapshots(),
                            builder: (context, machineSnap) {
                              if (!machineSnap.hasData) {
                                return const SizedBox.shrink();
                              }
                              final mData = machineSnap.data!.data()
                                  as Map<String, dynamic>?;
                              if (mData == null) {
                                return const SizedBox.shrink();
                              }

                              final machineStatus = mData['status'] ?? 'USING';
                              // AVAILABLE이 되면 모듈 사라짐
                              if (machineStatus == 'AVAILABLE') {
                                return const SizedBox.shrink();
                              }

                              final mType = mData['machineType'] == 'DRYER'
                                  ? '건조기'
                                  : '세탁기';
                              final machineNo = mData['machineNo'] ?? '';
                              // floor가 없으면 '?층' 대신 아예 생략
                              final floorRaw = mData['floor'];
                              final label = floorRaw != null
                                  ? '$mType · $floorRaw층 · $machineNo번'
                                  : '$mType · $machineNo번';

                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/machineDetail',
                                  arguments: {
                                    'machineId': machineId,
                                    'machineType': machineType,
                                  },
                                ),
                                child: Container(
                                  // 카드가 있을 때만 아래 여백 (간격을 카드 안으로)
                                  margin: const EdgeInsets.only(bottom: 24),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          machineType == 'DRYER'
                                              ? Icons.dry_cleaning
                                              : Icons.local_laundry_service,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              machineStatus == 'WAITING'
                                                  ? '수거 대기 중'
                                                  : '사용 중인 기기',
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              label,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 실시간 카운트다운
                                      if (endTime != null)
                                        StreamBuilder(
                                          stream: Stream.periodic(
                                              const Duration(seconds: 1)),
                                          builder: (context, timerSnap) {
                                            final diff = endTime
                                                .toDate()
                                                .difference(DateTime.now());

                                            if (diff.isNegative) {
                                              return const Text(
                                                '수거 대기',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            }

                                            final m = diff.inMinutes
                                                .toString()
                                                .padLeft(2, '0');
                                            final s = (diff.inSeconds % 60)
                                                .toString()
                                                .padLeft(2, '0');

                                            return Text(
                                              '$m:$s',
                                              style: const TextStyle(
                                                color: Color(0xFF9BC3FF),
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const Text(
                        '최근 이용 내역',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
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
                                child: CircularProgressIndicator());
                          }

                          if (!sessionSnapshot.hasData ||
                              sessionSnapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text('최근 이용 내역이 없습니다.',
                                  style: TextStyle(color: Colors.grey)),
                            );
                          }

                          return Column(
                            children: sessionSnapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final machineId = data['machineId'] ?? '';
                              final status = data['status'] ?? '';
                              final endTime = data['endTime'];

                              String subText = '이용 기록';
                              if (endTime is Timestamp) {
                                final date = endTime.toDate();
                                subText =
                                    '사용 종료 · ${date.year}.${date.month}.${date.day}';
                              }

                              return _UsageItemWithMachineInfo(
                                machineId: machineId,
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
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// -- 최근 이용 내역 아이템 (기기 정보 표시) --
class _UsageItemWithMachineInfo extends StatelessWidget {
  final String machineId;
  final String subtitle;
  final String status;

  const _UsageItemWithMachineInfo({
    required this.machineId,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRunning = status == '진행';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('machines')
          .doc(machineId)
          .get(),
      builder: (context, snap) {
        String title = machineId;
        bool isDryer = false;

        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          isDryer = d['machineType'] == 'DRYER';
          final mType = isDryer ? '건조기' : '세탁기';
          final no = d['machineNo'] ?? '';
          final floorRaw = d['floor'];
          title =
              floorRaw != null ? '$mType · $floorRaw층 · $no번' : '$mType · $no번';
        }

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
                child: Icon(
                  isDryer
                      ? Icons.dry_cleaning_outlined
                      : Icons.local_laundry_service_outlined,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isRunning ? Colors.black : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isRunning ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
