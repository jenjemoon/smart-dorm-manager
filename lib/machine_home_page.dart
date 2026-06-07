import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MachineHomePage extends StatefulWidget {
  const MachineHomePage({Key? key}) : super(key: key);

  @override
  State<MachineHomePage> createState() => _MachineHomePageState();
}

class _MachineHomePageState extends State<MachineHomePage> {
  String _selectedType = 'WASHER';
  String _selectedFilter = 'ALL';

  String _formatStatus(String status) {
    switch (status) {
      case 'AVAILABLE':
        return '사용 가능';
      case 'USING':
        return '사용 중';
      case 'WAITING':
        return '수거 대기';
      case 'BROKEN':
        return '고장';
      default:
        return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return const Color(0xFF9BC3FF);
      case 'USING':
        return Colors.black;
      case 'WAITING':
        return Colors.orange;
      case 'BROKEN':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _pageTitle() {
    return _selectedType == 'WASHER' ? '세탁' : '건조';
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('machines')
        .where('machineType', isEqualTo: _selectedType);

    if (_selectedFilter == 'AVAILABLE') {
      query = query.where('status', isEqualTo: 'AVAILABLE');
    } else if (_selectedFilter == 'USING') {
      query = query.where('status', isEqualTo: 'USING');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          '세탁실',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () =>
                Navigator.pushNamed(context, '/notificationPage'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _typeButton('세탁기', 'WASHER'),
                    const SizedBox(width: 12),
                    _typeButton('건조기', 'DRYER'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _filterButton('전체', 'ALL'),
                    const SizedBox(width: 12),
                    _filterButton('사용 가능', 'AVAILABLE'),
                    const SizedBox(width: 12),
                    _filterButton('사용 중', 'USING'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '등록된 기기가 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final machines = snapshot.data!.docs;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pageTitle(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.only(top: 12, bottom: 32),
                        width: 60,
                        height: 5,
                        color: Colors.black,
                      ),
                      Column(
                        children: machines.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final machineNo = data['machineNo'] ?? '';
                          final status =
                              data['status'] ?? 'AVAILABLE';
                          final floor = data['floor'] ?? '--';
                          final currentUserId =
                              data['currentUserId'] ?? '';
                          final currentUid =
                              FirebaseAuth.instance.currentUser?.uid;
                          final bool isMyMachine = currentUid != null &&
                              currentUid == currentUserId;

                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/machineDetail',
                                arguments: {
                                  'machineId': doc.id,
                                  'machineType': data['machineType'],
                                },
                              );
                            },
                            child: _MachineCard(
                              machineId: doc.id,
                              machineNo: machineNo.toString(),
                              status: status,
                              floor: floor.toString(),
                              selectedType: _selectedType,
                              statusLabel: _formatStatus(status),
                              statusColor: _statusColor(status),
                              isMyMachine: isMyMachine,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(String label, String type) {
    final bool isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedFilter = 'ALL';
          });
        },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterButton(String label, String filter) {
    final bool isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── 기기 카드 (실시간 카운트다운 포함) ──
class _MachineCard extends StatelessWidget {
  final String machineId;
  final String machineNo;
  final String status;
  final String floor;
  final String selectedType;
  final String statusLabel;
  final Color statusColor;
  final bool isMyMachine;

  const _MachineCard({
    required this.machineId,
    required this.machineNo,
    required this.status,
    required this.floor,
    required this.selectedType,
    required this.statusLabel,
    required this.statusColor,
    required this.isMyMachine,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == 'USING' || status == 'WAITING';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        // 내 기기면 테두리 강조
        border: isMyMachine && isActive
            ? Border.all(color: Colors.black, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            color: Colors.grey.shade200,
            child: Icon(
              selectedType == 'WASHER'
                  ? Icons.local_laundry_service_outlined
                  : Icons.dry_cleaning_outlined,
              size: 48,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: status == 'AVAILABLE'
                              ? Colors.black
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isMyMachine && isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '내 기기',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${selectedType == 'WASHER' ? '세탁기' : '건조기'} $machineNo',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('⌾ $floor층'),
                if (isActive) ...[
                  const SizedBox(height: 8),
                  // 실시간 카운트다운 스트림
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usageSessions')
                        .where('machineId', isEqualTo: machineId)
                        .where('status', isEqualTo: 'RUNNING')
                        .limit(1)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Text('시간 정보 없음',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey));
                      }
                      final data = snap.data!.docs.first.data()
                          as Map<String, dynamic>;
                      final endTs = data['endTime'] as Timestamp?;
                      if (endTs == null) {
                        return const SizedBox();
                      }
                      final endTime = endTs.toDate();
                      return StreamBuilder(
                        stream: Stream.periodic(
                            const Duration(seconds: 1)),
                        builder: (context, _) {
                          final now = DateTime.now();
                          final diff = endTime.difference(now);
                          if (diff.isNegative) {
                            return const Text(
                              '수거 대기 중',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            );
                          }
                          final m = diff.inMinutes
                              .toString()
                              .padLeft(2, '0');
                          final s = (diff.inSeconds % 60)
                              .toString()
                              .padLeft(2, '0');
                          return Text(
                            '남은 시간 $m:$s',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}