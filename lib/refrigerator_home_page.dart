import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RefrigeratorHomePage extends StatelessWidget {
  const RefrigeratorHomePage({Key? key}) : super(key: key);

  String _formatStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return '보관중';

      case 'EXPIRED':
        return '기간만료';

      case 'REMOVED':
        return '사용자 제거';

      case 'DISCARDED':
        return '관리자 폐기';

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    //print('현재 로그인 uid: $uid');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('냉장고'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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

                final containerNo =
                    userData?['fridgeContainerNo'] ?? '등록된 통 정보 없음';

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('refrigeratorItems')
                      .where('userId', isEqualTo: uid)
                      .where('status', isEqualTo: 'ACTIVE')
                      .snapshots(),
                  builder: (context, itemSnapshot) {
                    final itemCount = itemSnapshot.hasData
                        ? itemSnapshot.data!.docs.length
                        : 0;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      '냉장고 시설',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Icon(Icons.kitchen_outlined),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  containerNo,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  '보관중인 식품',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$itemCount건',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: const [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey,
                                        thickness: 1,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'STATUS: ACTIVE ●',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _actionButton(
                                  icon: Icons.add_circle_outline,
                                  title: '제품 등록',
                                  backgroundColor: Colors.grey.shade200,
                                  textColor: Colors.black,
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/refrigeratorCamera');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _actionButton(
                                  icon: Icons.inventory_2_outlined,
                                  title: '보관 제품',
                                  backgroundColor: Colors.black,
                                  textColor: Colors.white,
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/refrigeratorItems');
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            '수거 임박 아이템',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (itemSnapshot.connectionState ==
                              ConnectionState.waiting)
                            const Center(child: CircularProgressIndicator())
                          else if (!itemSnapshot.hasData ||
                              itemSnapshot.data!.docs.isEmpty)
                            const Text(
                              '등록된 냉장고 식품이 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else ...[
                            Builder(
                              builder: (context) {
                                final now = DateTime.now();

                                final soonItems =
                                    itemSnapshot.data!.docs.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final dateText =
                                      data['recommendedExpireDate'];

                                  if (dateText == null || dateText == '')
                                    return false;

                                  final parts = dateText.toString().split('.');
                                  if (parts.length != 3) return false;

                                  final expireDate = DateTime(
                                    int.parse(parts[0]),
                                    int.parse(parts[1]),
                                    int.parse(parts[2]),
                                    23,
                                    59,
                                  );

                                  final hoursLeft =
                                      expireDate.difference(now).inHours;

                                  return hoursLeft <= 48 && hoursLeft >= 0;
                                }).toList();

                                if (soonItems.isEmpty) {
                                  return const Text(
                                    '수거 임박 아이템이 없습니다.',
                                    style: TextStyle(color: Colors.grey),
                                  );
                                }

                                return Column(
                                  children: soonItems.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    final itemName = data['itemName'] == null ||
                                            data['itemName'] == ''
                                        ? '이름 없는 식품'
                                        : data['itemName'];

                                    final status = data['status'] ?? '';
                                    final storageType =
                                        data['storageType'] ?? 'IN_CONTAINER';

                                    return _historyItem(
                                      title: itemName,
                                      subtitle:
                                          storageType == 'OUTSIDE_CONTAINER'
                                              ? '통 밖 보관'
                                              : '통 안 보관',
                                      status: _formatStatus(status),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyItem({
    required String title,
    required String subtitle,
    required String status,
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
          const Icon(Icons.info_outline),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
