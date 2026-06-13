import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RefrigeratorItemsPage extends StatelessWidget {
  const RefrigeratorItemsPage({Key? key}) : super(key: key);

  String _formatDate(dynamic value) {
    if (value == null) return '미확인';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }

    return value.toString();
  }

  Future<void> _updateStatus({
    required BuildContext context,
    required String itemId,
    required String status,
  }) async {
    await FirebaseFirestore.instance
        .collection('refrigeratorItems')
        .doc(itemId)
        .update({
      'status': status,
      'removedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == 'REMOVED' ? '보관 제품을 꺼냈습니다.' : '제품을 폐기 처리했습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '보관 제품',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('로그인이 필요합니다.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('refrigeratorItems')
                  .where('userId', isEqualTo: uid)
                  .where('status', isEqualTo: 'ACTIVE')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '보관 중인 제품이 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final itemName = data['itemName'] ?? '이름 없는 식품';
                    final storageType = data['storageType'] ?? 'IN_CONTAINER';
                    final foodType = data['foodType'] ?? 'FRESH';
                    final expireDate = data['expireDate'];
                    final recommendedExpireDate = data['recommendedExpireDate'];
                    final recommendedStorageDays =
                        data['recommendedStorageDays'] ?? 7;
                    final imageUrl = (data['imageUrl'] ?? '').toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: imageUrl.isEmpty
                                    ? const Icon(Icons.kitchen_outlined,
                                        size: 34)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print('이미지 로드 에러: $error');
                                            return const Icon(
                                                Icons.broken_image_outlined,
                                                size: 34);
                                          },
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      storageType == 'OUTSIDE_CONTAINER'
                                          ? '통 밖 보관'
                                          : '통 안 보관',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      foodType == 'PACKAGED'
                                          ? '유통기한: ${_formatDate(expireDate)}'
                                          : '추천 수거일: ${_formatDate(recommendedExpireDate)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '추천 보관일: $recommendedStorageDays일',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _updateStatus(
                                      context: context,
                                      itemId: doc.id,
                                      status: 'REMOVED',
                                    );
                                  },
                                  child: const Text('꺼냈어요'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _updateStatus(
                                      context: context,
                                      itemId: doc.id,
                                      status: 'DISCARDED',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('폐기'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
