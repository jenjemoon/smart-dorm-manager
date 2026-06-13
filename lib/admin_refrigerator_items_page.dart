import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRefrigeratorItemsPage extends StatefulWidget {
  const AdminRefrigeratorItemsPage({Key? key}) : super(key: key);

  @override
  State<AdminRefrigeratorItemsPage> createState() =>
      _AdminRefrigeratorItemsPageState();
}

class _AdminRefrigeratorItemsPageState
    extends State<AdminRefrigeratorItemsPage> {
  String _sortType = 'LATEST';

  String _formatDate(dynamic value) {
    if (value == null) return '미확인';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }

    return value.toString();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    final text = value.toString();
    final parts = text.split('.');
    if (parts.length != 3) return null;

    return DateTime(
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  int? _daysLeft(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return null;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    return dateOnly.difference(todayOnly).inDays;
  }

  void _sortDocs(List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      if (_sortType == 'LATEST') {
        final aTime = aData['createdAt'] as Timestamp?;
        final bTime = bData['createdAt'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      }

      if (_sortType == 'OLDEST') {
        final aTime = aData['createdAt'] as Timestamp?;
        final bTime = bData['createdAt'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return aTime.compareTo(bTime);
      }

      final aDate = _parseDate(aData['recommendedExpireDate']);
      final bDate = _parseDate(bData['recommendedExpireDate']);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });
  }

  Future<void> _discardItem({
    required BuildContext context,
    required String itemId,
  }) async {
    await FirebaseFirestore.instance
        .collection('refrigeratorItems')
        .doc(itemId)
        .update({
      'status': 'DISCARDED',
      'removedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('제품을 폐기 처리했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          '냉장고 관리',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                const Text(
                  '보관 제품 목록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _sortType,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'LATEST',
                      child: Text('최신순'),
                    ),
                    DropdownMenuItem(
                      value: 'OLDEST',
                      child: Text('오래된순'),
                    ),
                    DropdownMenuItem(
                      value: 'EXPIRE',
                      child: Text('수거일 임박순'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _sortType = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('refrigeratorItems')
                  .where('status', isEqualTo: 'ACTIVE')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '보관 중인 제품이 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.toList();
                _sortDocs(docs);

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final itemName = data['itemName'] ?? '이름 없는 식품';
                    final userId = data['userId'] ?? '';
                    final imageUrl = (data['imageUrl'] ?? '').toString();
                    final storageType = data['storageType'] ?? 'IN_CONTAINER';
                    final foodType = data['foodType'] ?? 'FRESH';
                    final expireDate = data['expireDate'];
                    final recommendedExpireDate = data['recommendedExpireDate'];
                    final recommendedStorageDays =
                        data['recommendedStorageDays'] ?? 7;

                    final dateForDisplay = foodType == 'PACKAGED'
                        ? expireDate
                        : recommendedExpireDate;

                    final daysLeft = _daysLeft(recommendedExpireDate);
                    final isSoon =
                        daysLeft != null && daysLeft >= 0 && daysLeft <= 2;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.kitchen_outlined, size: 34)
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.broken_image_outlined,
                                          size: 34,
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        itemName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isSoon)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          '임박',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  storageType == 'OUTSIDE_CONTAINER'
                                      ? '통 밖 보관'
                                      : '통 안 보관',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '사용자: $userId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  foodType == 'PACKAGED'
                                      ? '유통기한: ${_formatDate(dateForDisplay)}'
                                      : '추천 수거일: ${_formatDate(dateForDisplay)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '추천 보관일: $recommendedStorageDays일',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                if (daysLeft != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    daysLeft >= 0
                                        ? '남은 기간: D-$daysLeft'
                                        : '수거일 지남',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          isSoon ? Colors.red : Colors.black54,
                                      fontWeight: isSoon
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _discardItem(
                                        context: context,
                                        itemId: doc.id,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('폐기 처리'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
